.globl _start
_start:
	ldiu %0, 0x1000
	ldi %1, 0x11223344
	ldi %15, 0xffffffff
	# basic relative write then read using byte instructions
	st.l %15, -4(%0)
	st.l %15, (%0)
	st.l %15, 4(%0)
	st.b %1, (%0)
	ld.l %2, (%0)
	st.b %1, 2(%0)
	ld.l %3, (%0)
	st.b %1, -2(%0)
	ld.l %4, -4(%0)
	ld.b %5, -2(%0)
	st.b %1, 5(%0)
	ld.l %6, 4(%0)
	st.b %1, 6(%0)
	ld.l %7, 4(%0)
	st.b %1, 7(%0)
	ld.l %8, 4(%0)
	ld.b %9, 4(%0)
	# force cache flush
	ldd.l %10, 0xf00
	ldd.l %10, 0x1100
	ldd.l %10, 0x2f0
	ldd.l %10, 0x11f0
	halt
