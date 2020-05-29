#include "memout.h"
#include <stdint.h>

// Used as comparison for output of applications.
volatile unsigned int * const memout = (unsigned int *)0x50000000;
 
int memidx = 0;

void emit(uint32_t val) {
  memout[memidx++] = val;
}
