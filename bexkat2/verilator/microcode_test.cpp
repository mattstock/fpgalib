#include <iostream>
#include <fstream>
#include <stdio.h>
#include <cstdarg>
#include "Vmicrocode_top.h"
#include "verilated.h"

#define INS_RA(x) (0xf & (x >> 20))
#define INS_RB(x) (0xf & (x >> 16))
#define INS_RC(x) (0xf & (x >> 12))

static const char *statestr[] = {
  "RESET", "EXC", "EXC2", "EXC3",
  "EXC4", "EXC5", "EXC6", "EXC7",
  "EXC8", "EXC9", "EXC10", "EXC11", "EXC12",
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
  "STORE5" };

using namespace std;
Vmicrocode_top* top;
ofstream debugfile;

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

  if (argc != 2) {
    printf("Need debug file on command line.\n");
    exit(1);
  }
  
  debugfile.open(argv[1]);
    
  Verilated::commandArgs(argc, argv);
  top = new Vmicrocode_top;

  top->rst_i = 1;
  top->clk_i = 0;
  top->interrupts = 0;
  
  while (!Verilated::gotFinish()) {
    // Run the clock
    top->clk_i = ~top->clk_i;
    
    // Drop reset
    if (tick == 2)
      top->rst_i = 0;
    
    top->eval();

    if (top->clk_i) {
      emit(D_DEBUG, "-------------------- %03ld --------------------\n", cycle);
      emit(D_DEBUG, "pc:  %*x  ir:  %*lx\n", 16, top->top__DOT__cpu0__DOT__pc,
	   16, top->top__DOT__cpu0__DOT__ir);
      emit(D_DEBUG, "state: %s\n", statestr[top->top__DOT__cpu0__DOT__con0__DOT__state]);
      for (int i=0; i < 8; i++)
	emit(D_DEBUG, "%*d: %08x",
	     3, i, top->top__DOT__cpu0__DOT__intreg__DOT__regfile[i]);
      emit(D_DEBUG, "\n");
      for (int i=8; i < 16; i++)
	emit(D_DEBUG, "%*d: %08x",
	     3, i, top->top__DOT__cpu0__DOT__intreg__DOT__regfile[i]);
      emit(D_DEBUG, "\n");
      emit(D_DEBUG, "Ins: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x stall: %d\n",
	   top->ins_adr_o,
	   top->ins_cyc_o,
	   top->ins_stb_o,
	   top->ins_ack_i,
	   top->ins_dat_i,
	   top->ins_stall_i);
      emit(D_DEBUG, "Mem: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x dat_o: %08x we: %d sel: %1x stall: %d\n",
	   top->dat_adr_o, top->dat_cyc_o, top->dat_stb_o, top->dat_ack_i, top->dat_dat_i,
	   top->dat_dat_o, top->dat_we_o, top->dat_sel_o, top->dat_stall_i);
      cycle++;
    }

    if (top->halt) {
      emit(D_DEBUG, "HALT\n");
      
      emit(D_BOTH, "Registers:\n");
      for (int i=0; i < 8; i++)
	emit(D_BOTH, "%*d: %08x",
	     3, i, top->top__DOT__cpu0__DOT__intreg__DOT__regfile[i]);
      emit(D_BOTH, "\n");
      for (int i=8; i < 16; i++)
	emit(D_BOTH, "%*d: %08x",
	     3, i, top->top__DOT__cpu0__DOT__intreg__DOT__regfile[i]);
      emit(D_BOTH, "\n");
      emit(D_BOTH, "Memory:\n");
      for (int i=0; i < 8*1024; i++) {
	if (i%16==0) {
	  if (i != 0)
	    emit(D_BOTH, "\n");
	  emit(D_BOTH, "%04x: ", i);
	}
	emit(D_BOTH, "%02x ", top->top__DOT__ram0__DOT__mem[i]);
      }
      break;
    }
    
    tick++;
  }
  debugfile.close();
  top->final();
  delete top;
  exit(0);
}
