.globl _start
_start:
	ldi %sp, 0x2000
	ldiu %0, 0x0
	ldi %1, _erodata
	ldiu %2, 0x0
check:	ld.b %3, (%1)
	addi %0, %0, 1
	addi %1, %1, 1
	cmp %3, %2
	bne check
	push %0
	ldi %0, _erodata
	push %0
	push %2
	jsrd memcpy
	halt

.globl memcpy
memcpy:	
	push %0
	push %1
	push %2
	push %3
	push %4
	push %5
	push %6
	push %7
	push %8
	push %fp
	mov.l %fp, %sp
	ld.l %12, 44(%fp)
	ld.l %1, 48(%fp)
	ld.l %4, 52(%fp)
	cmp %12, %1
	bleu else
	add %0, %1, %4
	cmp %0, %12
	bleu else
	add %2, %12, %4
	ldiu %3, 0
	cmp %4, %3
	beq done
l1:	addi %0, %0, -1
	addi %2, %2, -1
	ld.b %3, (%0)
	st.b %3, (%2)
	cmp %1, %0
	bne l1
done:	pop %fp
	pop %8
	pop %7
	pop %6
	pop %5
	pop %4
	pop %3
	pop %2
	pop %1
	pop %0
	rts
else:	ldiu %0, 15
	cmp %4, %0
	bgtu x4
	mov.l %0, %12
x9:	addi %2, %4, -1
	ldiu %3, 0
	cmp %4, %3
	beq done
x8:	addi %2, %2, 1
	add %2, %0, %2
l2:	ld.b %3, (%1)
	st.b %3, (%0)
	addi %0, %0, 1
	addi %1, %1, 1
	cmp %0, %2
	bne l2
	bra done
x4:	or %0, %12, %1
	ldiu %2, 3
	and %0, %0, %2
	ldiu %2, 0
	cmp %0, %2
	bne x5
	addi %5, %4, -16
	ldiu %2, 4
	lsr %5, %5, %2
	addi %5, %5, 1
	lsl %5, %5, %2
l3:	add %3, %1, %0
	add %2, %12, %0
	ld.l %6, (%3)
	st.l %6, (%2)
	ld.l %6, 4(%3)
	st.l %6, 4(%2)
	ld.l %6, 8(%3)
	st.l %6, 8(%2)
	ld.l %3, 12(%3)
	st.l %3, 12(%2)
	addi %0, %0, 16
	cmp %0, %5
	bne l3
	add %1, %1, %0
	add %0, %12, %0
	ldiu %3, 15
	and %3, %4, %3
	ldiu %2, 12
	and %2, %4, %2
	ldiu %5, 0
	cmp %2, %5
	beq x6
	mov.l %5, %0
	mov.l %2, %1
	add %8, %1, %3
	ldiu %7, 3
l4:	ld.l %6, (%2)
	st.l %6, (%5)
	addi %2, %2, 4
	addi %5, %5, 4
	sub %6, %8, %2
	cmp %6, %7
	bgtu l4
	and %4, %4, %7
	addi %2, %3, -4
	ldiu %3, 2
	lsr %2, %2, %3
	addi %2, %2, 1
	lsl %2, %2, %3
	add %0, %0, %2
	add %1, %1, %2
	bra x9
x5:	addi %2, %4, -1
	mov.l %0, %12
	bra x8
x6:	mov.l %4, %3
	bra x9
	
.data

msg:	.asciz "this is a test"
