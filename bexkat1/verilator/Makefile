OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
RANLIB = bexkat1-elf-ranlib

TEMP := $(shell mktemp)
CPUDEPS = ../bexkat1p.v ../alu.v ../intcalc.v ../mem.v ../execute.v ../idecode.v ../ifetch.v  ../hazard.v ../registerfile.v ../../fifo.sv ../memwb.v ../../interrupt_encoder.v ../../timerint.v ../../uart/uart.v ../../cache/arbiter.sv ../../cache/cache.sv

.PHONY: all clean tests

all: obj_dir/Vpipeline tests

tests:
	cd tests; make

obj_dir/Vpipeline_top.cpp: ${CPUDEPS} pipeline_top.v ram2.v
	verilator --trace -I.. -I../.. -I../../cache --unroll-count 256 --unroll-stmts 10000 -cc pipeline_top.v -exe pipeline_test.cpp

obj_dir/Vpipeline: obj_dir/Vpipeline_top.cpp pipeline_test.cpp
	cd obj_dir; make -f Vpipeline_top.mk

obj_dir/Vifetch.cpp: ../ifetch.v
	verilator -I.. -cc ../ifetch.v -exe ifetch_test.cpp

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
