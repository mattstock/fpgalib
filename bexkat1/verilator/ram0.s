.globl main
main:
	mov %0, %1
	mov %2, %0
	add %2, %3, %6
	ldi %2, 0x12345678
	add %2, %5, %10
	ldiu %0, 0x02
	ldiu %1, 0x10
	add %2, %1, %0
	halt
	
