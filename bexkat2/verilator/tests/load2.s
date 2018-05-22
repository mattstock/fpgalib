.globl _start
_start:
	ldi %0, 0xdeadbeef
	ldiu %1, 0x3456
	halt
