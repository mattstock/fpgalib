.globl _start
_start:
	setint 0x0000100
	nop
	nop
	nop
	nop
	trap 1
	halt

	.org 0x100
	jmpd 0x0
	.org 0x168
	jmpd 0x1100

	.org 0x1100
	ldi %1, 0x12345678
	halt
	
