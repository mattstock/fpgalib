	.set msg_base,  0x20000000
	
.globl main
main:
	ldi %0, 0x80000062
	std.l %0, msg_base
	ldi %0, 0x80000063
	std.l %0, msg_base
	ldi %0, 0x8000000a
	std.l %0, msg_base
	bra main
