OBJCOPY = bexkat1-elf-objcopy
OBJDUMP = bexkat1-elf-objdump
CFLAGS = -T profile-verilator.ld
ASFLAGS = 
LDFLAGS = -T profile-verilator.ld
LDLIBS = -Lout -lvectors
AS = bexkat1-elf-as
LD = bexkat1-elf-ld
CC = bexkat1-elf-gcc
RANLIB = bexkat1-elf-ranlib

TESTS = load load2 memops regrel regrel2 regrel3 mov alu alu2 pushpop misc math exceptions branch branch2 branch3 jump sub


TESTPROGS = $(addsuffix .srec, $(addprefix out/, $(TESTS)))

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
		cp out/$$t.srec ../ram0.srec ; \
		../obj_dir/Vpipeline_top --debug=out/$$t.debug --output=out/$$t.memout --trace=out/$$t.vcd > out/$$t.output ; \
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

out/%.srec: out/%
	$(OBJCOPY) -O srec $< $@

out/%.hex: out/%
	$(OBJCOPY) -O verilog $< $@

out/%.bin: out/%.o
	$(OBJCOPY) -O binary $< $@

ram0: %.o
	$(LD)  $< -o $@

out/load: out/load.o
	$(LD)  -o $@ $^

out/load2: out/load2.o
	$(LD)  -o $@ $^

out/memops: out/memops.o
	$(LD)  -o $@ $^

out/regrel: out/regrel.o
	$(LD)  -o $@ $^

out/regrel2: out/regrel2.o
	$(LD)  -o $@ $^

out/regrel3: out/regrel3.o
	$(LD)  -o $@ $^

out/mov: out/mov.o
	$(LD)  -o $@ $^

out/alu: out/alu.o
	$(LD)  -o $@ $^

out/alu2: out/alu2.o
	$(LD)  -o $@ $^

out/pushpop: out/pushpop.o
	$(LD)  -o $@ $^

out/misc: out/misc.o
	$(LD)  -o $@ $^

out/math: out/math.o
	$(LD)  -o $@ $^

out/exceptions: out/exceptions.o
	$(LD) $(LDFLAGS) -o $@ $^

out/branch: out/branch.o
	$(LD) $(LDFLAGS) -o $@ $^

out/branch2: out/branch2.o
	$(LD) $(LDFLAGS) -o $@ $^

out/branch3: out/branch3.o
	$(LD) $(LDFLAGS) -o $@ $^

out/jump: out/jump.o
	$(LD) $(LDFLAGS) -o $@ $^

out/sub: out/sub.o
	$(LD) $(LDFLAGS) -o $@ $^
