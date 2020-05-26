#include <string>
#include <iostream>
#include <fstream>

class MemoryBlock {
  int len;
  char *name;
  std::ostream& debugfile;
  unsigned char *block;
  unsigned int cyc0, cyc1;
  unsigned int stb0, stb1;
  unsigned int addr0, addr1;
  unsigned int wdata1;
  unsigned int rdata0, rdata1;
  unsigned int we1;
  unsigned short sel1;
  enum { IDLE, BUSY } state0, state1;
  unsigned int back0, back1;
  
  void loadBlock(const char filename[]);
  void parseSrec(std::string line);
  unsigned char read(unsigned int addr);
  unsigned short read2(unsigned int addr);
  
public:
  MemoryBlock(const char name[], std::ostream& df,int s);
  MemoryBlock(const char name[], std::ostream& df, int s, const char filename[]);
  void eval();
  void dump(std::ostream& outfile);
  void bus0(bool cyc, bool stb, unsigned int addr);
  void bus1(bool cyc, bool stb, unsigned int addr, bool we, unsigned short sel, unsigned int data);
  unsigned int read0();
  unsigned int read1();
  bool ack0();
  bool ack1();
  ~MemoryBlock();
};
