.globl _start
_start:
	ldi %0, 0xdeadbeef
	jmpd jmptgt
next1:	ldiu %0, 0x4567
	bra bratgt
	halt
jmptgt:	mov %1, %0
	mov %2, %0
	jmpd next1
brat2:	mov %4, %0
	mov %5, %0
	mov %6, %0
	halt
bratgt:	mov %3, %0
	ldiu %0, 0x1234
	bra brat2
	ldiu %0, 0x1111
	ldiu %1, 0x1221
	ldiu %2, 0x1331
	ldiu %3, 0x1441
	ldiu %4, 0x1551
	nop
	nop
	nop
	
.data
a:	.word 0x0000
	.word 0x101c
b:	.word 0x1000
	.word 0x0002
c:	.word 0x0000
	.word 0x0000
