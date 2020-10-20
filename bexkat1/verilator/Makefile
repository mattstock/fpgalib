OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
RANLIB = bexkat1-elf-ranlib

TEMP := $(shell mktemp)
CPUDEPS = ../bexkat1.sv ../alu.sv ../intcalc.sv ../mem.sv ../execute.sv ../idecode.sv ../ifetch.sv  ../hazard.sv ../registerfile.sv ../../fifo.sv ../memwb.sv ../../interrupt_encoder.sv ../../timerint.sv ../../uart/uart.sv ../../cache/arbiter.sv ../../cache/cache.sv

.PHONY: all clean tests

all: obj_dir/Vpipeline tests

tests:
	cd tests; make
	cd tests-c; make

obj_dir/Vpipeline_top.cpp: ${CPUDEPS} pipeline_top.sv ram2.sv
	verilator --trace -I.. -I../.. -I../../cache -cc pipeline_top.sv -exe pipeline_test.cpp ../../bexkat2/verilator/memory.cpp

obj_dir/Vpipeline: obj_dir/Vpipeline_top.cpp pipeline_test.cpp
	cd obj_dir; make -f Vpipeline_top.mk

clean:
	rm -f *.o ram0.hex *.bin *.mif *.gkd *.expand ram0 *~ *.bak
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

ram0: ram0.o
	$(LD) -nostartfiles $< -o $@
ram0.o: ram0.s
	$(AS) -o $@ $^

memory.o: ../../bexkat2/verilator/memory.cpp ../../bexkat2/verilator/memory.h
