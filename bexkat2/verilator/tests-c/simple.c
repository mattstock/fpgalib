volatile unsigned int * const memout = (unsigned int *)0x50000000;

unsigned int foo(unsigned n) {
  return n+6;
}

int main() {
  int a = 0x45;
  int b = 0x56;
  unsigned int c;
  
  c = foo(a);
  c++;
  memout[0] = 0xdeadbeef;
  memout[1] = a;
  memout[2] = b;
  memout[3] = c;
}
