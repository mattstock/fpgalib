OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
RANLIB = bexkat1-elf-ranlib

TEMP := $(shell mktemp)
CPUDEPS = ../bexkat2.sv ../alu.sv ../intcalc.sv ../control.sv ../registerfile.sv

# For the verilator targets
VCPPFLAGS = -Iobj_dir  -MMD -I/usr/local/share/verilator/include -I/usr/local/share/verilator/include/vltstd -DVL_PRINTF=printf -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TRACE=1 -faligned-new -Wno-bool-operation -Wno-sign-compare -Wno-uninitialized -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable -Wno-shadow

.PHONY: all clean tests

all: obj_dir/Vmicrocode_top tests

tests:
	cd tests; make

obj_dir/Vmicrocode_top.cpp: ${CPUDEPS} microcode_top.sv
	verilator --trace -I.. -I../.. -I../../cache --unroll-count 256 --unroll-stmts 10000 -cc microcode_top.sv

obj_dir/Vcache_top.cpp: cache_top.sv ../../cache/cache.sv ../../cache/cachemem.sv
	verilator --trace -I.. -I../.. -I../../cache --unroll-count 256 --unroll-stmts 10000 -cc cache_top.sv

obj_dir/Vmicrocode_top__ALL.a: obj_dir/Vmicrocode_top.cpp
	cd obj_dir; make -f Vmicrocode_top.mk Vmicrocode_top__ALL.a

obj_dir/Vcache_top__ALL.a: obj_dir/Vcache_top.cpp
	cd obj_dir; make -f Vcache_top.mk Vcache_top__ALL.a

obj_dir/verilated.o:
	cd obj_dir; make -f Vmicrocode_top.mk verilated.o

obj_dir/verilated_vcd_c.o:
	cd obj_dir; make -f Vmicrocode_top.mk verilated_vcd_c.o

microcode_test.o: obj_dir/Vmicrocode_top__ALL.a microcode_test.cpp
	cd obj_dir; make -f Vcache_top.mk ../microcode_test.o

obj_dir/Vmicrocode_top: obj_dir/Vmicrocode_top__ALL.a obj_dir/Vcache_top__ALL.a obj_dir/verilated.o obj_dir/verilated_vcd_c.o microcode_test.o memory.o
	g++ -o $@ obj_dir/Vmicrocode_top__ALL*.o obj_dir/Vcache_top__ALL*.o obj_dir/verilated.o obj_dir/verilated_vcd_c.o microcode_test.o memory.o

clean:
	rm -f *.o ram0.srec *.bin *.mif *.gkd *.expand *~ *.bak *.d
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

microcode_test.o: microcode_test.cpp memory.h
memory.o: memory.cpp memory.h

