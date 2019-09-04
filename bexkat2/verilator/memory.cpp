#include "memory.h"
#include <iostream>
#include <fstream>
#include <iomanip>

/*
 * This is a little more that a fancy memory array, simply because we want to
 * honor the cycle-latency that we would have with real memory as well as
 * allow for pipelining.
 */

MemoryBlock::MemoryBlock(int s) {
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

void MemoryBlock::bus0(bool cyc, bool stb, unsigned int addr) {
  cyc0 = cyc;
  stb0 = stb;
  addr0 = addr;
}

void MemoryBlock::bus1(bool cyc, bool stb, unsigned int addr, bool we, unsigned short sel, unsigned int data) {
  cyc1 = cyc;
  stb1 = stb;
  addr1 = addr;
  we1 = we;
  wdata1 = data;
  sel1 = sel;
}

void MemoryBlock::eval() {
  switch (state0) {
  case IDLE:
    if (cyc0 && stb0) {
      state0 = BUSY;
      rdata0 = (read2(addr0) << 16) + read2(addr0+2);
    }
    break;
  case BUSY:
    if (!(cyc0 && stb0)) {
      state0 = IDLE;
    } else {
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

MemoryBlock::MemoryBlock(int s, const char filename[]) {
  len = s;
  block = new unsigned char[len];
  loadBlock(filename);
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
  }
}

void MemoryBlock::parseSrec(std::string line) {
  unsigned char val, count, i;
  unsigned int addr;
  unsigned char checksum = 0;
  if (line[0] != 'S')
    return;
  if (line[1] != '1')
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
  while (count != 0) {
    val = std::stoi(line.substr(i, 2), nullptr, 16);
    checksum += val;
    if (count != 1)
      block[addr++] = val;
    i += 2;
    count--;
  }
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

void MemoryBlock::dump(std::ofstream& df) {
  char buf[200];

  for (int i=0; i < len; i++) {
    if (i % 16 == 0) {
      if (i != 0) {
	std::cout << "\n";
	df << "\n";
      }
      sprintf(buf, "%04x: ", i);
      std::cout << buf;
      df << buf;
    }
    sprintf(buf, "%02x ", block[i]);
    std::cout << buf;
    df << buf;
  }
}

MemoryBlock::~MemoryBlock() {
  delete []block;
}
