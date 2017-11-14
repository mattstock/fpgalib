OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
RANLIB = bexkat1-elf-ranlib

TEMP := $(shell mktemp)

.PHONY: all clean

all: obj_dir/Vbexkat1p_top.cpp ram0.hex

obj_dir/Vifetch_test.cpp: ../ifetch.v ifetch_test.cpp
	verilator -I.. -cc ifetch.v -exe ifetch_test.cpp

obj_dir/Vbexkat1p_top.cpp: bexkat1p_top.v bexkat1p_test.cpp
	verilator -I.. -cc bexkat1p_top.v -exe bexkat1p_test.cpp

verilator: top.v
	verilator -I.. -cc top.v -exe sim_main.cpp


clean:
	rm -f *.o *.hex *.bin *.mif *.gkd *.expand
	rm -rf obj_dir

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $^

%.mif: %
	$(OBJCOPY) -O mif $< $@

%.hex: %.o
	$(OBJCOPY) -O verilog $< $@

%.bin: %.o
	$(OBJCOPY) -O binary $< $@

rom0.o: rom0.s
	$(AS) -o $@ $^
