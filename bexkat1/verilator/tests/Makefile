OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
CFLAGS = -T profile-verilator.ld -nostartfiles
ASFLAGS = -nostartfiles
LDFLAGS = -T profile-verilator.ld -nostartfiles
LDLIBS = -Lout -lvectors
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
CC = bexkat1-elf-gcc
RANLIB = bexkat1-elf-ranlib

TESTS = load memops regrel mov alu pushpop misc math exceptions exceptions2 exceptions3 branch jump sub simple


TESTPROGS = $(addsuffix .hex, $(addprefix out/, $(TESTS)))

.PHONY: all clean tests rebase directories

all: directories out/boot-verilator.o out/libvectors.a tests

directories:
	@mkdir -p out

clean:
	@rm -rf out

rebase:
	@for t in $(TESTS); do \
		echo $$t ; \
		cp out/$$t.output ref/$$t ; \
	done

tests: $(TESTPROGS)
	@for t in $(TESTS); do \
		echo -n $$t ; \
		cp out/$$t.hex ../ram0.hex ; \
		../obj_dir/Vpipeline_top > out/$$t.output ; \
		diff -u0 ref/$$t out/$$t.output > out/$$t.diff ; \
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

out/%.hex: out/%
	$(OBJCOPY) -O verilog $< $@

out/%.bin: out/%.o
	$(OBJCOPY) -O binary $< $@

ram0: %.o
	$(LD) -nostartfiles $< -o $@

out/load: out/load.o
	$(LD) -nostartfiles -o $@ $^

out/memops: out/memops.o
	$(LD) -nostartfiles -o $@ $^

out/regrel: out/regrel.o
	$(LD) -nostartfiles -o $@ $^

out/mov: out/mov.o
	$(LD) -nostartfiles -o $@ $^

out/alu: out/alu.o
	$(LD) -nostartfiles -o $@ $^

out/pushpop: out/pushpop.o
	$(LD) -nostartfiles -o $@ $^

out/misc: out/misc.o
	$(LD) -nostartfiles -o $@ $^

out/math: out/math.o
	$(LD) -nostartfiles -o $@ $^

out/exceptions: out/exceptions.o
	$(LD) -nostartfiles -o $@ $^

out/exceptions2: out/exceptions2.o
	$(LD) -nostartfiles -o $@ $^

out/exceptions3: out/exceptions3.o
	$(LD) -nostartfiles -o $@ $^

out/branch: out/branch.o
	$(LD) -nostartfiles -o $@ $^

out/jump: out/jump.o
	$(LD) -nostartfiles -o $@ $^

out/sub: out/sub.o
	$(LD) -nostartfiles -o $@ $^

out/simple: out/simple.o
