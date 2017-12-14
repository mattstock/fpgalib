OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
RANLIB = bexkat1-elf-ranlib

TEMP := $(shell mktemp)
CPUDEPS = ../bexkat1p.v ../alu_comb.v ../bankedregisterfile.v ../intcalc.v ../mem.v ../execute.v ../idecode.v ../ifetch.v  ../hazard.v ../registerfile.v
.PHONY: all clean tests

all: obj_dir/Vpipeline_top.cpp obj_dir/Vbexkat1p_top.cpp tests

tests:
	cd tests; make

obj_dir/Vpipeline_top.cpp: ${CPUDEPS} pipeline_top.v pipeline_test.cpp ram2.v
	verilator -I.. --unroll-count 256 --unroll-stmts 10000 -cc pipeline_top.v -exe pipeline_test.cpp
	cd obj_dir; make -f Vpipeline_top.mk

obj_dir/Vbexkat1p_top.cpp: ${CPUDEPS} ../bexkat1p.v bexkat1p_top.v bexkat1p_test.cpp ram2.v
	verilator -I.. -cc bexkat1p_top.v -exe bexkat1p_test.cpp
	cd obj_dir; make -f Vbexkat1p_top.mk

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
