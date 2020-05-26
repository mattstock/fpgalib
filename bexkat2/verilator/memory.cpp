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

// We disable this by default because it messes up the slignment of the
// debug frames.
#define DEBUG_ON false

MemoryBlock::MemoryBlock(const char n[], std::ostream& df, int s)
  : debugfile(df) {
  name = new char[strlen(n)];
  strcpy(name, n);
  len = s;
  block = new unsigned char[len];
  state0 = IDLE;
  state1 = IDLE;
  cyc0 = 0;
  cyc1 = 0;
  addr0 = 0;
  addr1 = 0;
  stb0 = 0;
  stb1 = 0;
  we1 = 0;
  sel1 = 0xf;
  rdata0 = 0;
  rdata1 = 0;
  back0 = 0;
  back1 = 0;

  for (int i=0; i < len; i++)
    block[i] = 0;
}

MemoryBlock::MemoryBlock(const char n[], std::ostream& df, int s, const char filename[])
  : debugfile(df) {
  name = new char[strlen(n)];
  strcpy(name, n);
  len = s;
  block = new unsigned char[len];
  state0 = IDLE;
  state1 = IDLE;
  cyc0 = 0;
  cyc1 = 0;
  addr0 = 0;
  addr1 = 0;
  stb0 = 0;
  stb1 = 0;
  we1 = 0;
  sel1 = 0xf;
  rdata0 = 0;
  rdata1 = 0;
  back0 = 0;
  back1 = 0;
  loadBlock(filename);

  debugfile << name << " initialized from " << filename << std::endl;
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

void MemoryBlock::eval() {
  char buf[200];
  switch (state0) {
  case IDLE:
    if (cyc0 && stb0) {
      state0 = BUSY;
#if MEMORY_DEBUG
      sprintf(buf, "%s bus0(i) %08x: %02x%02x%02x%02x\n", name, addr0,
	      read(addr0), read(addr0+1),
	      read(addr0+2), read(addr0+3));
      debugfile << buf;
#endif
      rdata0 = (read2(addr0) << 16) + read2(addr0+2);
    }
    break;
  case BUSY:
    if (!(cyc0 && stb0)) {
      state0 = IDLE;
    } else {
#if MEMORY_DEBUG
      sprintf(buf, "%s bus0(b) %08x: %02x%02x%02x%02x\n", name, addr0,
	      read(addr0), read(addr0+1),
	      read(addr0+2), read(addr0+3));
      debugfile << buf;
#endif
      rdata0 = (read2(addr0) << 16) + read2(addr0+2);
    }
    break;
  }
  switch (state1) {
  case IDLE:
    if (cyc1 && stb1) {
      state1 = BUSY;
      if (we1) {
	if (sel1 & 0x8)
	  block[addr1] = wdata1 >> 24;
	if (sel1 & 0x4)
	  block[addr1+1] = (wdata1 >> 16) & 0xff;
	if (sel1 & 0x2)
	  block[addr1+2] = (wdata1 >> 8) & 0xff;
	if (sel1 & 0x1)
	  block[addr1+3] = wdata1 & 0xff; 
      } else {
#if MEMORY_DEBUG
	sprintf(buf, "%s bus1(i) %08x: %02x%02x%02x%02x\n", name, addr1,
		read(addr1), read(addr1+1),
		read(addr1+2), read(addr1+3));
	debugfile << buf;
#endif
	rdata1 = (read2(addr1) << 16) + read2(addr1+2);
      } 
    }
    break;
  case BUSY:
    if (!(cyc1 && stb1)) {
      state1 = IDLE;
    } else {
      if (we1) {
	if (sel1 & 0x8)
	  block[addr1] = wdata1 >> 24;
	if (sel1 & 0x4)
	  block[addr1+1] = (wdata1 >> 16) & 0xff;
	if (sel1 & 0x2)
	  block[addr1+2] = (wdata1 >> 8) & 0xff;
	if (sel1 & 0x1)
	  block[addr1+3] = wdata1 & 0xff;
      } else {
#if MEMORY_DEBUG
	sprintf(buf, "%s bus1(b) %08x: %02x%02x%02x%02x\n", name, addr1,
		read(addr1), read(addr1+1),
		read(addr1+2), read(addr1+3));
	debugfile << buf;
#endif
	rdata1 = (read2(addr1) << 16) + read2(addr1+2);
      }
    }
    break;
  }
  back0 = (state0 == BUSY);
  back1 = (state1 == BUSY);
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
