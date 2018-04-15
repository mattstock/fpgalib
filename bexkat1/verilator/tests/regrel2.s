.globl _start
_start:
	ldiu %0, 0x1000
	ldi %1, 0x11223344
	ldi %15, 0xffffffff
	# basic relative write then read using half word instructions
	st.l %15, -4(%0)
	st.l %15, (%0)
	st.l %15, 4(%0)
	st %1, (%0)
	ld %2, (%0)
	st %1, 2(%0)
	ld.l %3, (%0)
	st %1, -2(%0)
	ld.l %4, -4(%0)
	ld %5, -2(%0)
	halt
