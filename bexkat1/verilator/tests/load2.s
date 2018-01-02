.globl _start
_start:
	ldi %0, 0xdeadbeef
	ldd.l %1, a
	std.l %0, a
	ldd.l %2, a
	ldd.l %3, a
	ldd.l %4, a
	ldd.l %5, a
	nop
	nop
	nop
	nop
	halt
	
.data
a:	.word 0x0000
	.word 0x101c
b:	.word 0x1000
	.word 0x0002
c:	.word 0x0000
	.word 0x0000
