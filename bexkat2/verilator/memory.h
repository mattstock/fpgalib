#include <string>

class MemoryBlock {
  int len;
  unsigned char *block;

  void loadBlock(const char filename[]);
  void parseSrec(std::string line);
  
public:
  MemoryBlock(int s);
  MemoryBlock(int s, const char filename[]);
  unsigned char read(unsigned int addr);
  unsigned short read2(unsigned int addr);
  unsigned int read4(unsigned int addr);
  void write(unsigned int addr, unsigned char v);
  ~MemoryBlock();
};
