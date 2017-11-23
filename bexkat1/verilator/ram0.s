.globl _start
_start:
	ldiu %0, -34
	ldd.l %6, a
	ldi %1, 0xaa0a
	ld.l %2, 1(%6)
	ldd.b %3, b
	add %4, %1, %0
	add %5, %2, %0

.data
a:	.word 0x0000
	.word 0x101c
b:	.word 0x1000
	.word 0x0002
