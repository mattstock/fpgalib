#include <iostream>
#include <fstream>
#include <stdio.h>
#include <cstdarg>
#include "Vmicrocode_top.h"
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "memory.h"

#define INS_RA(x) (0xf & (x >> 20))
#define INS_RB(x) (0xf & (x >> 16))
#define INS_RC(x) (0xf & (x >> 12))

static const char *statestr[] = {
  "RESET", "EXC", "EXC2", "EXC3",
  "EXC4", "EXC5", "EXC6", "EXC7",
  "EXC8", "EXC9", "EXC10", "JUMPD", "EXC12",
  "EXC13", "EXC14", "FETCH2", "ARG2",
  "FETCH", "LOADD2", "EVAL", "TERM",
  "ARG", "INH", "RELADDR", "PUSH",
  "PUSH2", "PUSH3", "PUSH4", "PUSH5",
  "POP", "POP2", "POP3", "POP4", "RTS",
  "RTS2", "RTS3", "CMP", "CMP2", "CMPS",
  "CMPS2", "CMPS3", "MOV", "INTU",
  "MDR2RA", "ALU", "ALU2", "ALU3", "ALU4",
  "INT", "INT2", "INT3", "BRANCH",
  "LDIU", "JUMP", "JUMP2", "JUMP3",
  "LOAD", "LOAD2", "LOAD3", "LOADD",
  "STORE", "STORE2", "STORE3", "STORE4",
  "STORED", "STORED2", "HALT", "RTI",
  "RTI2", "RTI3", "RTI4", "RTI5",
  "PUSH6", "POP5", "RTI6", "RTS4", "LOADD3",
  "STORE5", "ARG3" };

static const char *cachestatestr[] = {
  "IDLE", "BUSY", "HIT", "MISS",
  "FILL", "FILL2", "FILL3", "FILL4", "FILL5",
  "FLUSH", "FLUSH2", "FLUSH3", "FLUSH4", "FLUSH5",
  "FILL_WAIT", "FLUSH_WAIT", "DONE", "INIT", "BUSY2", "BUSY3" };

static const char *cachebusstatestr[] = {
  "IDLE", "ACK", "READ_WAIT", "WAIT" };

using namespace std;
Vmicrocode_top* cpu;
VerilatedVcdC* trace;
ofstream debugfile, outputfile;

#define D_DEBUG 0
#define D_BOTH  1

void emit(int type, const char * fmt...)
{
  char buf[200];
  va_list args;

  va_start(args, fmt);
  vsprintf(buf, fmt, args);
  if (type == D_BOTH)
    cout << buf;
  debugfile << buf;

  va_end(args);
}

int main(int argc, char **argv, char **env) {
  uint8_t mode = 0;
  uint8_t str_count = 0;
  vluint64_t tick = 0, cycle = 0;
  char *tracefile;
  MemoryBlock *ram0, *rom0, *output0;
  
  for (int i=1; i < argc; i++) {
    if (!strncmp(argv[i], "--debug=", 8)) {
      debugfile.open(argv[i]+8);
    }
    if (!strncmp(argv[i], "--output=", 9)) {
      outputfile.open(argv[i]+9);
    }
    if (!strncmp(argv[i], "--trace=", 8)) {
      tracefile = argv[i]+8;
    }
  }
    
  Verilated::commandArgs(argc, argv);
  cpu = new Vmicrocode_top;
  Verilated::traceEverOn(true);
  trace = new VerilatedVcdC;
  cpu->trace(trace, 99);
  trace->open(tracefile);
  
  cpu->rst_i = 1;
  cpu->clk_i = 0;
  cpu->interrupts = 0;
  rom0 = new MemoryBlock("rom0", debugfile, 8*1024, "../ram0.srec");  
  ram0 = new MemoryBlock("ram0", debugfile, 8*1024);  
  output0 = new MemoryBlock("output0", debugfile, 512);  
  
  while (!Verilated::gotFinish() && tick < 2000000) {
    // Run the clock
    cpu->clk_i = ~cpu->clk_i;
    
    // Drop reset
    if (tick == 4)
      cpu->rst_i = 0;
    
    // Memory in wiring
    if (cpu->ins_adr_o >= 0x00000000 && cpu->ins_adr_o < 0x10000000) {
      ram0->bus0(cpu->ins_cyc_o, cpu->ins_stb_o, cpu->ins_adr_o);
      cpu->ins_dat_i = ram0->read0();
      cpu->ins_ack_i = ram0->ack0();
    }
    if (cpu->ins_adr_o >= 0x70000000 && cpu->ins_adr_o < 0x80000000) {
      rom0->bus0(cpu->ins_cyc_o, cpu->ins_stb_o, cpu->ins_adr_o);
      cpu->ins_dat_i = rom0->read0();
      cpu->ins_ack_i = rom0->ack0();
    }
    if (cpu->dat_adr_o >= 0x00000000 && cpu->dat_adr_o < 0x10000000) {
      ram0->bus1(cpu->dat_cyc_o, cpu->dat_stb_o, cpu->dat_adr_o, cpu->dat_we_o, cpu->dat_sel_o, cpu->dat_dat_o);
      cpu->dat_dat_i = ram0->read1();
      cpu->dat_ack_i = ram0->ack1();
    }
    if (cpu->dat_adr_o >= 0x50000000 && cpu->dat_adr_o < 0x60000000) {
      output0->bus1(cpu->dat_cyc_o, cpu->dat_stb_o, cpu->dat_adr_o, cpu->dat_we_o, cpu->dat_sel_o, cpu->dat_dat_o);
      cpu->dat_dat_i = output0->read1();
      cpu->dat_ack_i = output0->ack1();
    }
    if (cpu->dat_adr_o >= 0x70000000 && cpu->dat_adr_o < 0x80000000) {
      rom0->bus1(cpu->dat_cyc_o, cpu->dat_stb_o, cpu->dat_adr_o, 0, cpu->dat_sel_o, cpu->dat_dat_o);
      cpu->dat_dat_i = rom0->read1();
      cpu->dat_ack_i = rom0->ack1();
    }
    rom0->eval();
    ram0->eval();
    cpu->eval();
    output0->eval();
    
    trace->dump(tick);
    trace->flush();

    if (cpu->clk_i) {
      emit(D_DEBUG, "-------------------- %03ld --------------------\n", cycle);
      emit(D_DEBUG, "state: %*s  ", 8,
	   statestr[cpu->top__DOT__cpu0__DOT__con0__DOT__state]);
      emit(D_DEBUG, "pc: %08x  ir: %08x  mdr: %08x  mar: %08x  a: %08x  b: %08x\n",
	   cpu->top__DOT__cpu0__DOT__pc,
	   cpu->top__DOT__cpu0__DOT__ir,
	   cpu->top__DOT__cpu0__DOT__mdr,
	   cpu->top__DOT__cpu0__DOT__mar,
	   cpu->top__DOT__cpu0__DOT__a,
	   cpu->top__DOT__cpu0__DOT__b);
      emit(D_DEBUG, "ccr: %02x  status: %02x  ssp: %08x  vectoff: %08x\n",
	   cpu->top__DOT__cpu0__DOT__ccr,
	   cpu->top__DOT__cpu0__DOT__status,
	   cpu->top__DOT__cpu0__DOT__intreg__DOT__ssp,
	   cpu->top__DOT__cpu0__DOT__vectoff);
	   
      for (int i=0; i < 8; i++)
	emit(D_DEBUG, "%*d: %08x",
	     3, i, cpu->top__DOT__cpu0__DOT__intreg__DOT__regfile[i]);
      emit(D_DEBUG, "\n");
      for (int i=8; i < 16; i++)
	emit(D_DEBUG, "%*d: %08x",
	     3, i, cpu->top__DOT__cpu0__DOT__intreg__DOT__regfile[i]);
      emit(D_DEBUG, "\n");
      emit(D_DEBUG, "Ins: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x stall: %d\n",
	   cpu->ins_adr_o,
	   cpu->ins_cyc_o,
	   cpu->ins_stb_o,
	   cpu->ins_ack_i,
	   cpu->ins_dat_i,
	   cpu->ins_stall_i);
      emit(D_DEBUG, "Dat: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x dat_o: %08x we: %d sel: %1x stall: %d\n",
	   cpu->dat_adr_o,
	   cpu->dat_cyc_o,
	   cpu->dat_stb_o,
	   cpu->dat_ack_i,
	   cpu->dat_dat_i,
	   cpu->dat_dat_o,
	   cpu->dat_we_o,
	   cpu->dat_sel_o,
	   cpu->dat_stall_i);
      
      cycle++;
    }

    if (cpu->halt) {
      emit(D_DEBUG, "HALT\n");
      
      emit(D_BOTH, "Registers:\n");
      for (int i=0; i < 8; i++)
	emit(D_BOTH, "%*d: %08x",
	     3, i, cpu->top__DOT__cpu0__DOT__intreg__DOT__regfile[i]);
      emit(D_BOTH, "\n");
      for (int i=8; i < 16; i++)
	emit(D_BOTH, "%*d: %08x",
	     3, i, cpu->top__DOT__cpu0__DOT__intreg__DOT__regfile[i]);
      emit(D_BOTH, "\n");
      emit(D_BOTH, "Memory:\n");
      ram0->dump(debugfile);
      ram0->dump(cout);
      break;
    }
    
    tick++;
  }

  if (!Verilated::gotFinish()) {
    emit(D_DEBUG, "FAIL RAM:\n");
    ram0->dump(debugfile);
    emit(D_DEBUG, "\nFAIL ROM:\n");
    rom0->dump(debugfile);
  }
    
  // emit the output memory to a file
  output0->dump(outputfile);
  outputfile.close();
  debugfile.close();
  trace->close();
  cpu->final();
  delete cpu;
  exit(0);
}
