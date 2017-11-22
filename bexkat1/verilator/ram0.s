.globl main
main:
	ldiu %0, 0x1000
	ldiu %1, 0x200
	add %2, %1, %0
