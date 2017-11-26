	.globl _start
_start:	ldi %0, 4030
	ldi %1, 10
	ldi %2, -5
	div %3, %0, %1
	div %4, %0, %2
	divu %5, %0, %2
	divi %6, %0, 3
	ldi %0, 0x78881111
	mul %7, %1, %2
	muli %8, %1, 34
	mul %9, %0, %0
	mul.x %10, %0, %0
	halt
	
