.globl _start
_start:
	ldi %0, 0x11223344
	bra brat1
	ldiu %1, 0x6677
	halt
brat1: 	mov.l %1, %0
	brn done
	mov.l %2, %0
	cmp %0, %1
	bne done
	ldiu %3, 0x7899
	beq brat2
	bra done
brat2:	ldi %9, 0x11112222
	halt
done:	ldi %0, 0xdeeddead
	halt
