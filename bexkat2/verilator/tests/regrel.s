.globl _start
_start:
	ldiu %0, 0x100
	ldi %1, 0x11223344
	st.l %1, (%0)
	ld.l %2, (%0)
	ld.b %3, (%0)
	ld.b %4, 1(%0)
	ld.b %5, 2(%0)
	ld.b %6, 3(%0)
	st %1, 4(%0)
	st.b %3, -1(%0)
	st.b %4, -2(%0)
	st.b %5, -3(%0)
	st.b %6, -4(%0)
	ld %7, -2(%0)
	# force cache flush
	ldd.l %10, 0x200
	ldd.l %10, 0x300
	ldd.l %10, 0x1fc
	ldd.l %10, 0x2fc
	halt
