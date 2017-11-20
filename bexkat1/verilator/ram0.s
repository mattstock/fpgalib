.globl main
main:
	ldiu %0, 0x02
	ldiu %1, 0x10
	nop
	nop
	nop
	nop
	add %2, %1, %0
	halt
	
