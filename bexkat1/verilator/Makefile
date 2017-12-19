OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
RANLIB = bexkat1-elf-ranlib

TEMP := $(shell mktemp)
CPUDEPS = ../bexkat1p.v ../alu_comb.v ../bankedregisterfile.v ../intcalc.v ../mem.v ../execute.v ../idecode.v ../ifetch.v  ../hazard.v ../registerfile.v ../arbiter.v ../fifo.v
.PHONY: all clean tests

all: obj_dir/Vpipeline

tests:
	cd tests; make

obj_dir/Vpipeline_top.cpp: ${CPUDEPS} pipeline_top.v ram.v
	verilator -I.. -I../.. --unroll-count 256 --unroll-stmts 10000 -cc pipeline_top.v -exe pipeline_test.cpp

obj_dir/Vpipeline: obj_dir/Vpipeline_top.cpp pipeline_test.cpp
	cd obj_dir; make -f Vpipeline_top.mk

obj_dir/Varbiter.cpp: ../arbiter.v
	verilator -I.. --unroll-count 256 --unroll-stmts 10000 -cc ../arbiter.v -exe arbiter_test.cpp

obj_dir/Varbiter: obj_dir/Varbiter.cpp arbiter_test.cpp
	cd obj_dir; make -f Varbiter.mk

clean:
	rm -f *.o *.hex *.bin *.mif *.gkd *.expand ram0
	rm -rf obj_dir

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
