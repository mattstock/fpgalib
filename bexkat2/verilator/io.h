#include <string>
#include <iostream>
#include <fstream>

class IOModule {
  char *name;
  
 public:
  IOModule(const char name[]);

  void eval();
  void reset();
  void debug();
  void dump();
  void bus(bool cyc, bool stb, unsigned int addr, bool we, unsigned short sel, unsigned int data);
  bool ack();
  unsigned int read();
  ~IOModule();
};
