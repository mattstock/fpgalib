.globl _start
_start:
	setint 0x0000100
	trap 1
	ldi %0, 0x11223300
	halt

	.org 0x100
	jmpd 0x0
	.org 0x108
	jmpd 0x1200
	.org 0x168
	jmpd 0x1100

	.org 0x1100
	ldi %1, 0x12345678
	halt
	
	.org 0x1200
	ldi %2, 0xffeeffee
	halt
