#include "memory.h"

MemoryBlock::MemoryBlock(int s) {
  len = s;
  block = new unsigned char[len];
}
  
unsigned char MemoryBlock::read(unsigned int addr) {
  return (addr < len ? block[addr] : 0);
}

void MemoryBlock::write(unsigned int addr, unsigned char v) {
  if (addr < len)
    block[addr] = v;
}

MemoryBlock::~MemoryBlock() {
  delete []block;
}
