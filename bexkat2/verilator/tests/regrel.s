.globl _start
_start:
	ldiu %0, 0x1000
	ldi %1, 0x11223344
	ldi %15, 0xffffffff
	# basic relative write then read with a pipeline variants
	st.l %1, (%0)
	ld.l %2, (%0)
	addi %3, %1, 1
	st.l %1, (%0)
	nop
	ld.l %4, (%0)
	nop
	st.l %4, 4(%0)
	nop
	nop
	ld.l %5, 4(%0)
	addi %6, %3, 1
	nop
	nop
	st.l %6, -4(%0)
	ld.l %7, -4(%0)
	nop
	nop
	nop
	nop
	st.l %15, -1(%0)
	ld.l %8, -4(%0)
	ld.l %9, (%0)
	st.l %15, 2(%0)
	ld.l %10, (%0)
	ld.l %11, 4(%0)
	halt
