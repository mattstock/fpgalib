.globl _start
_start:
	ldi %0, -2
	ldiu %1, 2
	ldiu %2, 0x12ff
	lsr %3, %0, %1
	lsri %4, %0, 3
	asr %5, %0, %1
	asri %6, %0, 3
	or %7, %2, %3
	ori %8, %2, 0x0f0f
	xor %9, %2, %5
	xori %15, %2, 0x3113
	halt
	
