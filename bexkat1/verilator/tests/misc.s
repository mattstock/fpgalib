	.globl _start
_start:	ldi %0, 0x11223344
	com %1, %0
	neg %2, %0
	halt
	
