.globl _start
_start:
	ldiu %0, 0x1000
	ldiu %1, 0x1911
	ldi %2, 0xdeadbeef
	st.l %2, (%0)
	ld.l %3, (%0)
	st.l %1, 2(%0)
	ld.l %4, 2(%0)
	ld.l %5, (%0)
	ld.l %6, 2(%0)
	halt
