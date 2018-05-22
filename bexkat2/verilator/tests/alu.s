.globl _start
_start:
	ldiu %0, 0x1001
	ldi %1, 0x11111111
	ldi %2, 0x11224455
	add %3, %1, %2
	addi %4, %1, 0x3222
	and %5, %0, %1
	andi %6, %1, 0x01
	sub %7, %3, %1
	subi %8, %5, 0x2
	lsl %9, %2, %6
	lsli %10, %0, 0x4
	halt
	
