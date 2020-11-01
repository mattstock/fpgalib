OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
RANLIB = bexkat1-elf-ranlib

TEMP := $(shell mktemp)
CPUDEPS = ../bexkat1.sv ../alu.sv ../intcalc.sv ../mem.sv ../execute.sv ../idecode.sv ../ifetch.sv  ../hazard.sv ../registerfile.sv ../../fifo.sv ../memwb.sv ../../interrupt_encoder.sv ../../timerint.sv ../../uart/uart.sv ../../cache/arbiter.sv ../../cache/cache.sv
CACHEDEPS = ../../cache/cache.sv ../../cache/cachemem.sv ../../cache/arbiter.sv

.PHONY: all clean tests

all: obj_dir/Vpipeline tests

tests:
	cd tests; make
	cd tests-c; make

obj_dir/Vpipeline_top.cpp: ${CPUDEPS} pipeline_top.sv ram2.sv
	verilator --trace -I.. -I../.. -I../../cache -cc pipeline_top.sv ../../cache/cache.sv -exe --top-module pipeline_top pipeline_test.cpp ../../bexkat2/verilator/memory.cpp Vcache_top__ALL.a

obj_dir/Vpipeline: obj_dir/Vpipeline_top.cpp obj_dir/Vcache_top__ALL.a pipeline_test.cpp
	cd obj_dir; make -f Vpipeline_top.mk

obj_dir/Vcache_top.cpp: ${CACHEDEPS} cache_top.sv
	verilator --trace -I.. -I../.. -I../../cache --unroll-count 256 --unroll-stmts 10000 -cc cache_top.sv bus_term.sv --top-module cache_top

obj_dir/Vcache_top__ALL.a: obj_dir/Vcache_top.cpp
	cd obj_dir; make -f Vcache_top.mk

clean:
	rm -f *.o ram0.srec *.bin *.mif *.gkd *.expand ram0 *~ *.bak
	rm -rf obj_dir
	cd tests; make clean
	cd tests-c; make clean

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $^

%.mif: %
	$(OBJCOPY) -O mif $< $@

%.hex: %
	$(OBJCOPY) -O verilog $< $@

%.bin: %.o
	$(OBJCOPY) -O binary $< $@

ram0: ram0.o
	$(LD) -nostartfiles $< -o $@
ram0.o: ram0.s
	$(AS) -o $@ $^

memory.o: ../../bexkat2/verilator/memory.cpp ../../bexkat2/verilator/memory.h
