#ifndef MEMOUT_H
#define MEMOUT_H

#include <stdint.h>

extern volatile unsigned int * const memout;

void emit(uint32_t val);

#endif
