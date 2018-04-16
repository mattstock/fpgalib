.globl _start
_start:
	ldi %0, 0x11223344
	bra brat1
	ldiu %1, 0x6677
	halt
brat2:	mov.l %4, %0
	bra brat3
brat1: 	mov.l %1, %0
	brn err
	mov.l %2, %0
	cmp %0, %1
	bne err
	ldiu %3, 0x7899
	beq brat2
	bra err
brat3:	ldi %9, 0x11112222
	halt
err:	ldi %0, 0xdeeddead
	halt
