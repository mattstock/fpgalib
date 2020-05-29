#include "memout.h"

unsigned int foo(unsigned n) {
  return n+6;
}

int main() {
  int a = 0x45;
  int b = 0x56;
  unsigned int c;
  
  c = foo(a);
  c++;
  emit(0xdeadbeef);
  emit(a);
  emit(b);
  emit(c);
}
