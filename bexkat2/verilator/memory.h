class MemoryBlock {
  int len;
  unsigned char *block;
  
public:
  MemoryBlock(int s);
  unsigned char read(unsigned int addr);
  void write(unsigned int addr, unsigned char v);
  ~MemoryBlock();
};
