#include "memout.h"

unsigned int foo(int a, char b, short c, char *d) {
  emit(a);
  emit(b);
  emit(c);
  emit((unsigned)d);
}

int main() {
  foo(-3, 'a', 400, "test");
}
