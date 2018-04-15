	.globl _start
_start:	ldi %sp, 0x00001000
	ldi %0, 0x12345678
	ldi %1, 0xffeeddcc
	push %0
	nop
	nop
	nop
	nop
	nop
	pop %2
	push %0
	push %1
	pop %3
	pop %4
	halt
	
