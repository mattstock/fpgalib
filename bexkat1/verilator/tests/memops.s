.globl _start
_start:
	ldiu %0, 0x1001
	ldiu %1, 0x1911
	std.l %1, c
	ldd.l %2, c
	halt
	mov %3, %2
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	
.data
a:	.word 0x0000
	.word 0x101c
b:	.word 0x1000
	.word 0x0002
c:	.word 0xaaaa
	.word 0xbbbb
