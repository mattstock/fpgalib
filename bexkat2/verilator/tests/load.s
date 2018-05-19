.globl _start
_start:
	ldiu %0, 0x1001
	ldiu %1, 0x1911
	ldi %2, 0xdeadbeef
	ldiu %3, 0x3020
	ldi %4, 0xfeefd00f
	ldi %5, 0x10002000
	ldiu %6, 0x3045
	ldd.l %7, a
	ldd %8, b
	ldd.b %9, a+2
	halt
	
.data
a:	.word 0x0000
	.word 0x101c
b:	.word 0x1000
	.word 0x0002
c:	.word 0x0000
	.word 0x0000
