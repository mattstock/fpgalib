#include <iostream>
#include <fstream>
#include <stdio.h>
#include <cstdarg>
#include "Vpipeline_top.h"
#include "verilated.h"

#define INS_RA(x) (0xf & (x >> 20))
#define INS_RB(x) (0xf & (x >> 16))
#define INS_RC(x) (0xf & (x >> 12))

using namespace std;
Vpipeline_top* top;
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
  top = new Vpipeline_top;

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
      emit(D_DEBUG, "--- PIPELINE STATE ---\n");
      emit(D_DEBUG, "     %*s %*s %*s %*s\n",
	   16, "ifetch",
	   16, "idecode",
	   33, "exec",
	   16, "mem");
      emit(D_DEBUG, "pc:  %*x %*x %*x %*x\n",
	   16, top->if_pc,
	   16, top->id_pc,
	   33, top->exe_pc,
	   16, top->mem_pc);
      emit(D_DEBUG, "ir:  %*lx %*lx %*lx %*lx\n",
	   16, top->if_ir,
	   16, top->id_ir,
	   33, top->exe_ir,
	   16, top->mem_ir);
      emit(D_DEBUG, "ra:  %*lx %*lx %*lx %*lx\n",
	   16, INS_RA(top->if_ir),
	   16, INS_RA(top->id_ir),
	   33, INS_RA(top->exe_ir),
	   16, INS_RA(top->mem_ir));
      emit(D_DEBUG, "rb:  %*lx %*lx %*lx %*lx\n",
	   16, INS_RB(top->if_ir),
	   16, INS_RB(top->id_ir),
	   33, INS_RB(top->exe_ir),
	   16, INS_RB(top->mem_ir));
      emit(D_DEBUG, "rc:  %*lx %*lx %*lx %*lx\n",
	   16, INS_RC(top->if_ir),
	   16, INS_RC(top->id_ir),
	   33, INS_RC(top->exe_ir),
	   16, INS_RC(top->mem_ir));
      emit(D_DEBUG, "spd: %*s %*x/%*x %*x %*x\n",
	   16, "",
	   16, top->id_sp_data,
	   16, top->exe_sp_in,
	   16, top->exe_sp_data,
	   16, top->mem_sp_data);
      emit(D_DEBUG, "spw: %*s %*x %*x %*x\n",
	   16, "",
	   16, top->id_sp_write,
	   33, top->exe_sp_write,
	   16, top->mem_sp_write);
      emit(D_DEBUG, "rd1: %*s %*x/%*x %*x\n",
	   16, "",
	   16, top->id_reg_data_out1,
	   16, top->exe_data1,
	   16, top->exe_reg_data_out1);
      emit(D_DEBUG, "rd2: %*s %*x/%*x %*x\n",
	   16, "",
	   16, top->id_reg_data_out2,
	   16, top->exe_data2,
	   16, top->exe_reg_data_out2);
      emit(D_DEBUG, "res: %*s %*s %*x %*x\n",
	   16, "",
	   16, "",
	   33, top->exe_result,
	   16, top->mem_result);
      emit(D_DEBUG, "ccr: %*s %*s %*x\n",
	   16, "",
	   16, "",
	   33, top->exe_ccr);
      emit(D_DEBUG, "rwr: %*s %*d %*d %*d\n",
	   16, "",
	   16, top->id_reg_write,
	   33, top->exe_reg_write,
	   16, top->mem_reg_write);
      emit(D_DEBUG, "pcs: %*s %*s %*d %*d\n",
	   16, "",
	   16, "",
	   33, top->exe_pc_set,
	   16, top->mem_pc_set);
      emit(D_DEBUG, "exc: %*s %*s %*d %*d\n",
	   16, "",
	   16, "",
	   33, top->exe_exc,
	   16, top->mem_exc);
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
	emit(D_DEBUG, "%*d: %08x",
	     3, i, top->top__DOT__decode0__DOT__reg0__DOT__regfile[i]);
      emit(D_DEBUG, "\n");
      for (int i=8; i < 16; i++)
	emit(D_DEBUG, "%*d: %08x",
	     3, i+4*top->id_bank,
	     top->top__DOT__decode0__DOT__reg0__DOT__regfile[i+4*top->id_bank]);
      emit(D_DEBUG, "\n");
      emit(D_DEBUG, "vectoff: %08x inten: %*d interrupts: %*x\n",
	   top->top__DOT__exe0__DOT__vectoff,
	   2, top->cpu_inter_en,
	   2, top->interrupts);
      emit(D_DEBUG, "Ins: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x stall: %d state: %d\n",
	   top->ins_adr_o,
	   top->ins_cyc_o,
	   top->ins_stb_o,
	   top->ins_ack_i,
	   top->ins_dat_i,
	   top->ins_stall_i,
	   top->top__DOT__fetch0__DOT__state);
      emit(D_DEBUG, "  fifo: cidx: %x ridx: %x widx: %x value[idx]: %08x\n",
	   top->top__DOT__fetch0__DOT__ffifo__DOT__cidx,
	   top->top__DOT__fetch0__DOT__ffifo__DOT__ridx,
	   top->top__DOT__fetch0__DOT__ffifo__DOT__widx,
	   top->top__DOT__fetch0__DOT__ffifo__DOT__values[top->top__DOT__fetch0__DOT__ffifo__DOT__ridx]);
      emit(D_DEBUG, "Mem: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x dat_o: %08x we: %d sel: %1x stall: %d state %x\n",
	   top->dat_adr_o, top->dat_cyc_o, top->dat_stb_o, top->dat_ack_i, top->dat_dat_i,
	   top->dat_dat_o, top->dat_we_o, top->dat_sel_o, top->dat_stall_i,
	   top->top__DOT__mem0__DOT__state);
      cycle++;
    }

    if (top->mem_halt) {
      emit(D_DEBUG, "HALT\n");
      emit(D_BOTH, "Registers:\n");
      for (int i=0; i < 8; i++)
	emit(D_BOTH, "%*d: %08x",
	     3, i, top->top__DOT__decode0__DOT__reg0__DOT__regfile[i]);
      emit(D_BOTH, "\n");
      for (int i=8; i < 16; i++)
	emit(D_BOTH, "%*d: %08x",
	     3, i, top->top__DOT__decode0__DOT__reg0__DOT__regfile[i]);
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
