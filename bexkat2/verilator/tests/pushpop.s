	.globl _start
_start:	ldi %sp, 0x0000100
	ldi %0, 0x12345678
	ldi %1, 0xffeeddcc
	push %0
	pop %2
	push %0
	push %1
	pop %3
	pop %4
	# force cache flush
	ldd.l %10, 0x1f0
	ldd.l %10, 0x2f0
	halt
	
