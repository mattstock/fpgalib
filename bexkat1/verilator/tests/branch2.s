.globl _start
_start:
	ldiu %0, 0
	ldiu %1, 0x4
l0:	addi %2, %2, 1
	subi %1, %1, 1
	cmp %0, %1
	bne l0
	ldiu %1, 0x6677
	halt
