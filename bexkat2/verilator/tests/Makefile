OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
CFLAGS = -T profile-verilator.ld
ASFLAGS = -nostartfiles
LDFLAGS = -T profile-verilator.ld
LDLIBS = -Lout -lvectors
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
CC = bexkat1-elf-gcc
RANLIB = bexkat1-elf-ranlib

TESTS = load load2 memops regrel regrel2 regrel3 mov alu alu2 pushpop misc math exceptions branch jump sub cache


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
		sed -e 's/^@70000000/@00000000/' out/$$t.hex > ../ram0.hex ; \
		../obj_dir/Vmicrocode_top out/$$t.debug out/$$t.vcd > out/$$t.output ; \
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

out/load2: out/load2.o
	$(LD) -nostartfiles -o $@ $^

out/memops: out/memops.o
	$(LD) -nostartfiles -o $@ $^

out/regrel: out/regrel.o
	$(LD) -nostartfiles -o $@ $^

out/regrel2: out/regrel2.o
	$(LD) -nostartfiles -o $@ $^

out/regrel3: out/regrel3.o
	$(LD) -nostartfiles -o $@ $^

out/mov: out/mov.o
	$(LD) -nostartfiles -o $@ $^

out/alu: out/alu.o
	$(LD) -nostartfiles -o $@ $^

out/alu2: out/alu2.o
	$(LD) -nostartfiles -o $@ $^

out/pushpop: out/pushpop.o
	$(LD) -nostartfiles -o $@ $^

out/misc: out/misc.o
	$(LD) -nostartfiles -o $@ $^

out/math: out/math.o
	$(LD) -nostartfiles -o $@ $^

out/exceptions: out/exceptions.o
	$(LD) $(LDFLAGS) -o $@ $^

out/branch: out/branch.o
	$(LD) $(LDFLAGS) -o $@ $^

out/jump: out/jump.o
	$(LD) $(LDFLAGS) -o $@ $^

out/sub: out/sub.o
	$(LD) $(LDFLAGS) -o $@ $^

out/cache: out/cache.o
	$(LD) $(LDFLAGS) -o $@ $^

out/simple: out/simple.o
