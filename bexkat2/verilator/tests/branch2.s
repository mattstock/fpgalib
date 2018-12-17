.globl _start
_start:
	ldi %0, -10
	ldi %1, 20
	ldi %2, 6
	ldi %3, -8
	cmp %0, %1
	brn err
# (-10 and 20)	
	beq err
	bleu err
	bltu err
	bge err
	bgt err
# (20 and 6)
	cmp %1, %2
	beq err
	bleu err
	bltu err
	ble err
	blt err
# (6 and -8)
	cmp %2, %3
	beq err
	bgeu err
	bgtu err
	ble err
	blt err
# (-8 and -20)
	cmp %3, %0
	beq err
	bleu err
	bltu err
	ble err
	blt err
# (-8 and -8)
	cmp %3, %3
	bne err
	blt err
	bltu err
	bgt err
	bgtu err
	halt
err:	ldi %0, 0xdeeddead
	halt
