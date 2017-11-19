.globl main
main:
	ldiu %0, 0x02
	ldiu %1, 0x10
	ldi %2, 0x12345678
	add %2, %1, %0
	halt
	
