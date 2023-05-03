OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
CFLAGS = -T verilator.ld
LDFLAGS = -T verilator.ld
LDLIBS = -Lout -lvectors
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
CC = bexkat1-elf-gcc
RANLIB = bexkat1-elf-ranlib

TESTS = simple fib frames


TESTPROGS = $(addsuffix .srec, $(addprefix out/, $(TESTS)))

.PHONY: all clean tests rebase directories

all: directories out/boot-verilator.o out/libvectors.a out/memout.o tests

directories:
	@mkdir -p out

clean:
	@rm -rf out

rebase:
	@for t in $(TESTS); do \
		echo $$t ; \
		cp out/$$t.memout ref/$$t ; \
	done

tests: $(TESTPROGS)
	@for t in $(TESTS); do \
		echo -n $$t ; \
		cp out/$$t.srec ../ram0.srec ; \
		../obj_dir/Vmicrocode_top --debug=out/$$t.debug --output=out/$$t.memout --trace=out/$$t.vcd > out/$$t.output ; \
		diff -u0 ref/$$t out/$$t.memout > out/$$t.diff ; \
		if [ -s out/$$t.diff ] ; \
		then \
			echo " FAIL" ; \
		else \
			echo " PASS" ; \
		fi ; \
	done

out/%.o: %.s
	$(AS) -o $@ $^

out/%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $^

out/libvectors.a: out/vectors.o
	$(AR) rcs -o $@ $^
	$(RANLIB) $@

out/%.mif: out/%
	$(OBJCOPY) -O mif $< $@

out/%.srec: out/%
	$(OBJCOPY) -O srec $< $@

out/%.hex: out/%
	$(OBJCOPY) -O verilog $< $@

out/%.bin: out/%.o
	$(OBJCOPY) -O binary $< $@

ram0: %.o
	$(LD) $< -o $@

out/simple: out/simple.o out/memout.o
	$(LD) $(LDFLAGS) -o $@ $< out/memout.o $(LDLIBS)

out/fib: out/fib.o out/memout.o
	$(LD) $(LDFLAGS) -o $@ $< out/memout.o $(LDLIBS)

out/frames: out/frames.o out/memout.o
	$(LD) $(LDFLAGS) -o $@ $< out/memout.o $(LDLIBS)
