.globl _start
_start:
	ldiu %0, 0x1000
	ldiu %1, 0x1911
	ldi %2, 0x11223344
	mov.l %3, %2
	mov %4, %2
	mov.b %5, %3
	halt
