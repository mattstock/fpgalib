.globl _start
_start:
	ldi %0, 0xdeadbeef
	std.l %0, 0x0
	ldd.l %1, 0x0
	ldd %2, 0x0
	ldd %3, 0x2
	ldd.b %4, 0x0
	ldd.b %5, 0x1
	ldd.b %6, 0x2
	ldd.b %7, 0x3
	# exercise the cache system a bit
	ldiu %10, 0xf0
loop:	ld.l %9, (%8)
	addi %8, %8, 0x10
	cmp %8, %10
	bne loop
	halt
