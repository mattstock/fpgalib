.globl _start
_start:
	ldi %sp, 0x00001000
	ldi %0, 0x11223344
	jsrd func1
	bsr func2
	ldi %3, 0xdeadbeef
	mov %4, %3
	# force cache flush
	ldd.l %10, 0x11f0
	ldd.l %10, 0xef0
	halt
	
func1:	ldiu %1, 0x4567
	rts
func2:	ldiu %2, 0x3244
	rts
	
	
