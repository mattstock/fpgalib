OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
RANLIB = bexkat1-elf-ranlib

TESTS = load memops sub

.PHONY: all clean tests

all: tests

clean:
	rm -rf out

tests:
	@mkdir -p out
	@for t in ${TESTS}; do \
		echo -n $$t ; \
		$(AS) -o out/$$t.o $$t.s ; \
		$(LD) -nostartfiles out/$$t.o -o out/$$t ; \
		$(OBJCOPY) -O verilog out/$$t ../ram0.hex ; \
		../obj_dir/Vpipeline_top > out/$$t.output ; \
		diff -u0 ref/$$t out/$$t.output > out/$$t.diff ; \
		if [ -s out/$$t.diff ] ; \
		then \
			echo " FAIL" ; \
		else \
			echo " PASS" ; \
		fi ; \
	done

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $^

%.mif: %
	$(OBJCOPY) -O mif $< $@

%.hex: %
	$(OBJCOPY) -O verilog $< $@

%.bin: %.o
	$(OBJCOPY) -O binary $< $@

%.o: %.s
	$(AS) -o $@ $^

ram0: %.o
	$(LD) -nostartfiles $< -o $@

