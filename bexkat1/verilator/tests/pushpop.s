	.globl _start
_start:	ldi %sp, 0x00001000
	ldi %0, 0x12345678
	push %0
	nop
	nop
	nop
	nop
	nop
	pop %1
	push %0
	pop %2
	halt
	
