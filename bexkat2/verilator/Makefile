OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
RANLIB = bexkat1-elf-ranlib

TEMP := $(shell mktemp)
CPUDEPS = ../bexkat2.sv ../alu.sv ../intcalc.sv ../control.sv ../registerfile.sv

.PHONY: all clean tests

all: obj_dir/Vmicrocode tests

tests:
	cd tests; make

obj_dir/Vmicrocode_top.cpp: ${CPUDEPS} microcode_top.sv
	verilator --trace -I.. -I../.. -I../../cache --unroll-count 256 --unroll-stmts 10000 -cc microcode_top.sv

obj_dir/Vcache_top.cpp: cache_top.sv ../../cache/cache.sv ../../cache/cachemem.sv
	verilator --trace -I.. -I../.. -I../../cache --unroll-count 256 --unroll-stmts 10000 -cc cache_top.sv

obj_dir/Vmicrocode_top__ALL.a: obj_dir/Vmicrocode_top.cpp
	cd obj_dir; make -f Vmicrocode_top.mk

obj_dir/Vcache_top__ALL.a: obj_dir/Vcache_top.cpp
	cd obj_dir; make -f Vcache_top.mk

obj_dir/Vmicrocode: obj_dir/Vcache_top__ALL.a obj_dir/Vmicrocode_top__ALL.a microcode_test.cpp
	g++ -Iobj_dir -I/usr/local/share/verilator/include microcode_test.cpp obj_dir/Vmicrocode_top__ALL.a obj_dir/Vcache_top__ALL.a -o obj_dir/Vmicrocode

clean:
	rm -f *.o ram0.hex *.bin *.mif *.gkd *.expand *~ *.bak
	rm -rf obj_dir
	cd tests; make clean

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $^

%.mif: %
	$(OBJCOPY) -O mif $< $@

%.hex: %
	$(OBJCOPY) -O verilog $< $@

%.bin: %.o
	$(OBJCOPY) -O binary $< $@
