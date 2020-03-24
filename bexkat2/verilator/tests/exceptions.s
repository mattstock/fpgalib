.globl _start
_start:
	ldi %sp, 0x1000
	setint _vectors_start
	sti
	
	trap 1
	ldi %0, 0x11223300
	halt

.globl trap1
trap1:	pushcc
	ldi %1, 0x12345678
	# we need to flush out the stack to the memory dump
	ldd.l %10, 0x1f0
	ldd.l %10, 0x2f0
	popcc
	rti
	
.globl trap0
trap0:	ldi %2, 0xffeeffee
	rti

fail:	halt
	
.globl _vectors_start
_vectors_start:
	jmpd fail # RESET
	jmpd fail # MMU
	jmpd fail # TIMER0
	jmpd fail # TIMER1
	jmpd fail # TIMER2
	jmpd fail # TIMER3
	jmpd fail # UART0_RX
	jmpd fail # UART0_TX
	jmpd fail # ILLOP
	jmpd fail # CPU1
	jmpd fail # CPU2
	jmpd fail # CPU3
	jmpd trap0 # TRAP0
	jmpd trap1 # TRAP1
	jmpd fail # TRAP2
	jmpd fail # TRAP3
	
