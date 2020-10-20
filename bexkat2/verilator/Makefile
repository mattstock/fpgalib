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
	cd tests-c; make

obj_dir/Vmicrocode_top.cpp: ${CPUDEPS} microcode_top.sv
	verilator --trace -I.. -I../.. --unroll-count 256 --unroll-stmts 10000 -cc microcode_top.sv -exe microcode_test.cpp memory.cpp

obj_dir/Vmicrocode_top: obj_dir/Vmicrocode_top.cpp microcode_test.cpp
	cd obj_dir; make -f Vmicrocode_top.mk

clean:
	rm -f *.o *.bin *.mif *.gkd *.expand *~ *.bak *.d
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
