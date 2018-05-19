.globl _start
_start:
	setint 0x0000100
	
	movsr %2
	ldi %0, 0x11223300
	ldi %1, 0x00003000
	cmp %1, %0
	movsr %3
	cmp %0, %1
	movsr %4
	cmp %0, %0
	movsr %5
	movrs %4
	beq bad
	halt
	nop
	nop
	nop
	nop
bad:	ldiu %6, 0x7ead
	halt
	
