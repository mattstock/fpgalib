#include "memory.h"
#include <iostream>
#include <fstream>

MemoryBlock::MemoryBlock(int s) {
  len = s;
  block = new unsigned char[len];
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
  return (addr < len ? block[addr] : 0);
}

unsigned short MemoryBlock::read2(unsigned int addr) {
  unsigned short temp = 0;
  
  temp = read(addr) << 8;
  temp += read(addr+1);
  return temp;
}

unsigned int MemoryBlock::read4(unsigned int addr) {
  unsigned int temp = 0;

  temp = read2(addr) << 16;;
  temp += read2(addr+2);
  return temp;
}

void MemoryBlock::write(unsigned int addr, unsigned char v) {
  if (addr < len)
    block[addr] = v;
}

MemoryBlock::~MemoryBlock() {
  delete []block;
}
