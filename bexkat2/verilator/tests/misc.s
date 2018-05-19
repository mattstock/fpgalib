	.globl _start
_start:	ldi %0, 0x11223344
	com %1, %0
	neg %2, %0
	ldi %3, 0x00008349
	ldiu %4, 0x84
	ext %5, %3
	ext.b %6, %4
	ext %7, %0
	ext.b %8, %0
	halt
	
