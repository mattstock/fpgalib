.globl _start
_start:
	ldi %sp, 0x1000
	# build vector table at 0x100
	
	ldi %0, 0xc0000001
	ldi %1, 0x70001200
	std.l %0, 0x108
	std.l %1, 0x10c
	ldi %1, 0x70001100
	std.l %0, 0x168
	std.l %1, 0x16c
	# Since the instruction bus isn't using the cache,
	# I need to flush the jump table out.
	ldd.l %10, 0xf60
	ldd.l %10, 0x1060
	ldd.l %10, 0xf00
	ldd.l %10, 0x1100
	
	setint 0x100
	sti
	
	trap 1
	ldi %0, 0x11223300
	halt

	.org 0x1100
	ldi %1, 0x12345678
	# we need to flush out the stack to the memory dump
	ldd.l %10, 0x1f0
	ldd.l %10, 0x2f0
	rti
	
	.org 0x1200
	ldi %2, 0xffeeffee
	rti
