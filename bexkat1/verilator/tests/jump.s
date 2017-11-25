.globl _start
_start:
	ldi %0, 0x11225577
	ldiu %1, 0x1000
	jmp (%1)
done:	ldiu %0, 0x2ead
	halt
jmpt2:	mov.l %4, %0
	jmp 16(%1)
	halt
	
.org 0x1000
jmptgt:	mov.l %2, %0
	mov.l %3, %0
	jmpd jmpt2
	ldiu %0, 0x2ea2
	halt

.org 0x1040
jmpt3:	mov.l %5, %0
	halt
