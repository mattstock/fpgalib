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

obj_dir/Vpipeline_top.cpp: ${CPUDEPS} pipeline_top.sv ram2.sv
	verilator --trace -I.. -I../.. -I../../cache -cc pipeline_top.sv -exe pipeline_test.cpp
#	verilator --trace -I.. -I../.. -I../../cache --unroll-count 256 --unroll-stmts 5000 -cc pipeline_top.sv -exe pipeline_test.cpp

obj_dir/Vpipeline: obj_dir/Vpipeline_top.cpp pipeline_test.cpp
	cd obj_dir; make -f Vpipeline_top.mk

obj_dir/Vifetch.cpp: ../ifetch.sv
	verilator -I.. -cc ../ifetch.sv -exe ifetch_test.cpp

obj_dir/Vifetch: obj_dir/Vifetch.cpp ifetch_test.cpp
	cd obj_dir; make -f Vifetch.mk

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
