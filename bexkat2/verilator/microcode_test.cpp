#include <iostream>
#include <fstream>
#include <stdio.h>
#include <cstdarg>
#include "Vmicrocode_top.h"
#include "verilated.h"

#define INS_RA(x) (0xf & (x >> 20))
#define INS_RB(x) (0xf & (x >> 16))
#define INS_RC(x) (0xf & (x >> 12))

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
      emit(D_BOTH, "-------------------- %03ld --------------------\n", cycle);
      emit(D_DEBUG, "pc:  %*x\n", 16, top->top__DOT__cpu0__DOT__pc);
      emit(D_DEBUG, "ir:  %*lx\n", 16, top->top__DOT__cpu0__DOT__ir);
      emit(D_DEBUG, "ra:  %*lx\n", 16, INS_RA(top->top__DOT__cpu0__DOT__ir));
      emit(D_DEBUG, "rb:  %*lx\n", 16, INS_RB(top->top__DOT__cpu0__DOT__ir));
      emit(D_DEBUG, "rc:  %*lx\n", 16, INS_RC(top->top__DOT__cpu0__DOT__ir));
#if 0
      emit(D_DEBUG, "h1: %02x h2: %02x hsp: %02x hs: % 2d es: % 2d ms: % 2d wad: %02d\n",
	   top->hazard1, top->hazard2, top->sp_hazard,
	   top->hazard_stall,
	   top->exe_stall, top->mem_stall,
	   top->mem_reg_write_addr);
      emit(D_DEBUG, "alu_func: %d alu1: %08x alu2: %08x alu_out: %08x int_func: %d int_out: %08x\n",
	   top->top__DOT__exe0__DOT__alu_func,
	   top->top__DOT__exe0__DOT__alu_in1,
	   top->top__DOT__exe0__DOT__alu_in2,
	   top->top__DOT__exe0__DOT__alu_out,
	   top->top__DOT__exe0__DOT__int_func,
	   top->top__DOT__exe0__DOT__int_out);
      for (int i=0; i < 8; i++)
	emit(D_BOTH, "%*d: %08x",
	     3, i, top->top__DOT__decode0__DOT__reg0__DOT__regfile[i]);
      emit(D_BOTH, "\n");
      for (int i=8; i < 16; i++)
	emit(D_BOTH, "%*d: %08x",
	     3, i+4*top->id_bank,
	     top->top__DOT__decode0__DOT__reg0__DOT__regfile[i+4*top->id_bank]);
      emit(D_BOTH, "\n");
#endif
      emit(D_BOTH, "Ins: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x stall: %d\n",
	   top->ins_adr_o,
	   top->ins_cyc_o,
	   top->ins_stb_o,
	   top->ins_ack_i,
	   top->ins_dat_i,
	   top->ins_stall_i);
      emit(D_BOTH, "Mem: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x dat_o: %08x we: %d sel: %1x stall: %d\n",
	   top->dat_adr_o, top->dat_cyc_o, top->dat_stb_o, top->dat_ack_i, top->dat_dat_i,
	   top->dat_dat_o, top->dat_we_o, top->dat_sel_o, top->dat_stall_i);
      cycle++;
    }

    if (top->halt) {
      emit(D_BOTH, "HALT\n");
      break;
    }
    
    tick++;
  }
  debugfile.close();
  top->final();
  delete top;
  exit(0);
}
