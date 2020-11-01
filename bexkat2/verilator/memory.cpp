#include "memory.h"
#include <iostream>
#include <fstream>
#include <iomanip>
#include <cstring>
#include <sstream>

/*
 * This is a little more that a fancy memory array, simply because we want to
 * honor the cycle-latency that we would have with real memory as well as
 * allow for pipelining.
 */

MemoryBlock::MemoryBlock(const char n[], std::ostream& df, int s)
  : debugfile(df) {
  name = new char[strlen(n)];
  strcpy(name, n);
  len = s;
  block = new unsigned char[len];
  reset();
  for (int i=0; i < len; i++)
    block[i] = 0;
}

MemoryBlock::MemoryBlock(const char n[], std::ostream& df, int s, const char filename[])
  : debugfile(df) {
  name = new char[strlen(n)];
  strcpy(name, n);
  len = s;
  block = new unsigned char[len];
  reset();
  loadBlock(filename);

  debugfile << name << " initialized from " << filename << std::endl;
}

void MemoryBlock::reset(void) {
  state0 = IDLE;
  state1 = IDLE;
  cyc0 = 0;
  cyc1 = 0;
  addr0 = 0;
  addr1 = 0;
  back0 = 0;
  back1 = 0;
  stb0 = 0;
  stb1 = 0;
  we1 = 0;
  sel1 = 0xf;
  rdata0 = 0;
  rdata1 = 0;
  back0 = 0;
  back1 = 0;
}

void MemoryBlock::bus0(bool cyc, bool stb, unsigned int addr) {
  cyc0 = cyc;
  stb0 = stb;
  addr0 = addr & 0xfffffc;
}

void MemoryBlock::bus1(bool cyc, bool stb, unsigned int addr, bool we, unsigned short sel, unsigned int data) {
  cyc1 = cyc;
  stb1 = stb;
  addr1 = addr & 0xfffffc;
  we1 = we;
  wdata1 = data;
  sel1 = sel;
}

void MemoryBlock::debug() {
  char buf[200];
  char s0, s1;

  s0 = (state0 == IDLE ? 'i' : 'b');
  s1 = (state1 == IDLE ? 'i' : 'b');
  
  sprintf(buf, "%s bus0: %08x %08x state: %c cyc: %d  stb %d ack %d\n", name, addr0, rdata0, s0, cyc0, stb0, back0);
  debugfile << buf;
  sprintf(buf, "%s bus1: %08x %08x state: %c cyc: %d  we %d stb %d ack %d\n", name, addr1, (we1 ? wdata1 : rdata1), s1, cyc1, we1, stb1, back1);
  debugfile << buf;
  sprintf(buf, "%08x %08x %08x\n", read4(addr1-4), read4(addr1), read4(addr1+4));
  debugfile << buf;  
}

void MemoryBlock::eval() {
  char buf[200];

  switch (state0) {
  case IDLE:
    if (cyc0 && stb0) {
      state0 = BUSY;
      back0++;
      rdata0 = read4(addr0);
    }
    break;
  case BUSY:
    if (!cyc0) {
      state0 = IDLE;
      back0 = 0;
    } else {
      if (back0 > 0)
	back0--;
      if (stb0) {
	back0++;
	rdata0 = read4(addr0);
      }
    }
    break;
  }
  switch (state1) {
  case IDLE:
    if (cyc1 && stb1) {
      state1 = BUSY;
      back1++;
      if (we1) {
	if (sel1 & 0x8)
	  block[addr1 & (len-1)] = wdata1 >> 24;
	if (sel1 & 0x4)
	  block[(addr1+1) & (len-1)] = (wdata1 >> 16) & 0xff;
	if (sel1 & 0x2)
	  block[(addr1+2) & (len-1)] = (wdata1 >> 8) & 0xff;
	if (sel1 & 0x1)
	  block[(addr1+3) & (len-1)] = wdata1 & 0xff; 
      } else {
	rdata1 = read4(addr1);
      } 
    }
    break;
  case BUSY:
    if (!cyc1) {
      state1 = IDLE;
      back1 = 0;
    } else {
      if (back1 > 0)
	back1--;
      if (stb1) {
	back1++;
	if (we1) {
	  if (sel1 & 0x8)
	    block[addr1 & (len-1)] = wdata1 >> 24;
	  if (sel1 & 0x4)
	    block[(addr1+1) & (len-1)] = (wdata1 >> 16) & 0xff;
	  if (sel1 & 0x2)
	    block[(addr1+2) & (len-1)] = (wdata1 >> 8) & 0xff;
	  if (sel1 & 0x1)
	    block[(addr1+3) & (len-1)] = wdata1 & 0xff;
	} else {
	  rdata1 = read4(addr1);
	}
      }
    }
    break;
  }
}

bool MemoryBlock::ack0() {
  return back0;
}

bool MemoryBlock::ack1() {
  return back1;
}

void MemoryBlock::loadBlock(const char filename[]) {
  std::string sbuf;
  std::ifstream srecfile(filename);
  if (srecfile.is_open()) {
    while (!srecfile.eof()) {
      std::getline(srecfile, sbuf);
      parseSrec(sbuf);
    }
    srecfile.close();
  } else {
    debugfile << "failed to load " << filename << std::endl;
  }
}

void MemoryBlock::parseSrec(std::string line) {
  char buf[200];
  unsigned char val, count, i;
  unsigned int addr;
  unsigned char checksum = 0;
  if (line[0] != 'S')
    return;
  if (line[1] != '1' and line[1] != '3')
    return;
  
  // Byte count
  count = std::stoi(line.substr(2, 2), nullptr, 16);
  // Initial address
  addr = std::stoi(line.substr(4, 2), nullptr, 16);
  checksum += val;
  addr <<= 8;
  addr += std::stoi(line.substr(6, 2), nullptr, 16);
  checksum += val;
  count -= 2; // for the address
  i = 8;
  
  if (line[1] == '3') {
    addr <<= 8;
    addr += std::stoi(line.substr(8, 2), nullptr, 16);
    checksum += val;
    addr <<= 8;
    addr += std::stoi(line.substr(10, 2), nullptr, 16);
    checksum += val;
    count -= 2;
    i = 12;
  }

  // We truncate the address to the size of the allocated buffer
  addr &= (len - 1);
  sprintf(buf, "%s: srec[%08x]: ", name, addr);
  debugfile << buf;
  
  while (count != 0) {
    val = std::stoi(line.substr(i, 2), nullptr, 16);
    checksum += val;
    if (count != 1) {
      block[addr++] = val;
      sprintf(buf, "%02x ", (int)val);
      debugfile << buf;
    }
    i += 2;
    count--;
  }
  debugfile << std::endl;
}

unsigned char MemoryBlock::read(unsigned int addr) {
  return block[addr & (len-1)];
}

unsigned short MemoryBlock::read2(unsigned int addr) {
  unsigned short temp = 0;
  
  temp = read(addr) << 8;
  temp += read(addr+1);
  return temp;
}

unsigned int MemoryBlock::read4(unsigned int addr) {
  return (read2(addr) << 16) + read2(addr+2);
}

unsigned int MemoryBlock::read0() {
  return rdata0;
}

unsigned int MemoryBlock::read1() {
  return rdata1;
}

void MemoryBlock::dump(std::ostream& ofile) {
  char buf[200];

  for (int i=0; i < len; i++) {
    if (i % 16 == 0) {
      if (i != 0) {
	ofile << std::endl;
      }
      sprintf(buf, "%04x: ", i);
      ofile << buf;
    }
    sprintf(buf, "%02x ", block[i]);
    ofile << buf;
  }
}

MemoryBlock::~MemoryBlock() {
  delete []block;
  delete []name;
}
