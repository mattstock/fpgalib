OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
RANLIB = bexkat1-elf-ranlib

TEMP := $(shell mktemp)

.PHONY: all clean gcctests kernel install

all: rom0.hex $(APPS) kernel

verilator: top.v
	verilator -I.. -cc top.v -exe sim_main.cpp


clean:
	rm -f *.o *.hex *.bin *.mif *.gkd *.expand

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
