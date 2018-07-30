.globl _start
_start:
	ldi %0, 0xdeadbeef
	std.l %0, 0x0 # cache miss, fill
	ldd.l %1, 0x0 # cache hit
	ldd.l %8, 0x100 # cache fill on second path
	ldd.l %10, 0x200 # cache flush on first path, then fill
	halt
