#include "memout.h"

unsigned int fib(unsigned int n) {
  if (n < 3)
    return 1;
  else
    return fib(n-1)+fib(n-2);
}

int main() {
  for (int i=1; i < 10; i++)
    emit(fib(i));
}
