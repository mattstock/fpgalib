.globl _start
_start:
	ldiu %0, 0x1001
	ldiu %1, 0x1911
	ldi %2, 0xdeadbeef
	ldiu %3, 0x3020
	ldi %4, 0xfeefd00f
	ldi %5, 0x10002000
	ldiu %6, 0x3045
	mov.l %7, %5
	mov %8, %4
	mov.b %9, %2
	halt
