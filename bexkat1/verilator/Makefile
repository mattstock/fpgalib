OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
RANLIB = bexkat1-elf-ranlib

TEMP := $(shell mktemp)
CPUDEPS = ../bexkat1p.v ../alu_comb.v ../registerfile.v ../wb.v ../mem.v ../execute.v ../idecode.v ../ifetch.v 
.PHONY: all clean

all: obj_dir/Vpipeline_top.cpp ram0.hex

obj_dir/Vpipeline_top.cpp: ${CPUDEPS} pipeline_top.v pipeline_test.cpp ram2.v
	verilator -I.. -cc pipeline_top.v -exe pipeline_test.cpp
	cd obj_dir; make -f Vpipeline_top.mk

obj_dir/Vifetch_top.cpp: ../ifetch.v ifetch_top.v ifetch_test.cpp ram2.v
	verilator -I.. -cc ifetch_top.v -exe ifetch_test.cpp
	cd obj_dir; make -f Vifetch_top.mk

obj_dir/Videcode_top.cpp: ../idecode.v ../ifetch.v idecode_top.v idecode_test.cpp ram2.v
	verilator -I.. -cc idecode_top.v -exe idecode_test.cpp
	cd obj_dir; make -f Videcode_top.mk

obj_dir/Vexecute_top.cpp: ../execute.v ../idecode.v ../ifetch.v execute_top.v execute_test.cpp ram2.v
	verilator -I.. -cc execute_top.v -exe execute_test.cpp
	cd obj_dir; make -f Vexecute_top.mk

obj_dir/Vbexkat1p_top.cpp: ../bexkat1p.v bexkat1p_top.v bexkat1p_test.cpp ram2.v ../ifetch.v
	verilator -I.. -cc bexkat1p_top.v -exe bexkat1p_test.cpp
	cd obj_dir; make -f Vbexkat1p_top.mk

verilator: top.v
	verilator -I.. -cc top.v -exe sim_main.cpp


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
