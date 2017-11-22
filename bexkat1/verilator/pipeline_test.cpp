#include <iostream>
#include "Vpipeline_top.h"
#include "verilated.h"

#define INS_RA(x) (0xf & (x >> 20))
#define INS_RB(x) (0xf & (x >> 16))
#define INS_RC(x) (0xf & (x >> 12))

using namespace std;
Vpipeline_top* top;

int main(int argc, char **argv, char **env) {
  uint8_t mode = 0;
  uint8_t str_count = 0;
  vluint64_t tick = 0, cycle = 0;
  
  Verilated::commandArgs(argc, argv);
  top = new Vpipeline_top;

  top->rst_i = 1;
  top->clk_i = 0;
  top->stall_i = 0;
  
  while (!Verilated::gotFinish()) {
    // Run the clock
    top->clk_i = ~top->clk_i;
    
    // Drop reset
    if (tick == 2)
      top->rst_i = 0;

    if (top->clk_i) {
      printf("-------------------- %03d --------------------\n", cycle);
      printf("--- PIPELINE STATE ---\n");
      printf("     % 16s % 16s % 16s % 16s % 16s\n",
	     "ifetch",
	     "idecode",
	     "exec",
	     "mem",
	     "wb");
	     
      printf("pc:  % 16x % 16x % 16x % 16x % 16x\n",
	     top->if_pc,
	     top->id_pc,
	     top->exe_pc,
	     top->mem_pc,
	     top->wb_pc);
      printf("ir:  %16lx %16lx %16lx %16lx\n",
	     top->if_ir,
	     top->id_ir,
	     top->exe_ir,
	     top->mem_ir);
      printf("st:  % 16d % 16d % 16d % 16d % 16d\n",
	     top->if_stall,
	     top->id_stall,
	     top->exe_stall,
	     top->mem_stall,
	     top->wb_stall);
      printf("ra:  % 16x % 16x % 16x % 16x\n",
	     INS_RA(top->if_ir),
	     INS_RA(top->id_ir),
	     INS_RA(top->exe_ir),
	     INS_RA(top->mem_ir));
      printf("rb:  % 16x % 16x % 16x % 16x\n",
	     INS_RB(top->if_ir),
	     INS_RB(top->id_ir),
	     INS_RB(top->exe_ir),
	     INS_RB(top->mem_ir));
      printf("rc:  % 16x % 16x % 16x % 16x\n",
	     INS_RC(top->if_ir),
	     INS_RC(top->id_ir),
	     INS_RC(top->exe_ir),
	     INS_RC(top->mem_ir));
      printf("rd1: % 16s % 16x % 16x\n",
	     "",
	     top->id_reg_data_out1,
	     top->exe_reg_data_out1);
      printf("rd2: % 16s % 16x\n",
	     "",
	     top->id_reg_data_out2);
      printf("ed1: % 16s % 16x\n",
	     "",
	     top->exe_data1);
      printf("ed2: % 16s % 16x\n",
	     "",
	     top->exe_data2);
      printf("res: % 16s % 16s % 16x % 16x % 16x\n",
	     "","",
	     top->exe_result,
	     top->mem_result,
	     top->wb_result);
      printf("ccr: % 16s % 16s % 16x % 16x\n",
	     "","",
	     top->exe_ccr,
	     top->mem_ccr);
      printf("rwr: % 16s % 16d % 16d % 16d % 16d\n",
	     "",
	     top->id_reg_write,
	     top->exe_reg_write,
	     top->mem_reg_write,
	     top->wb_reg_write);
      printf("wad: % 16s % 16s % 16s % 16s % 16x\n",
	     "","","","",
	     top->wb_reg_write_addr);
      printf("pcs: % 16s % 16s % 16s % 16s % 16d\n",
	     "","","","",
	     top->pc_set);
      printf("--- REGISTER STATE ---\n");
      for (int i=0; i < 8; i++)
	printf("% 3d: %08x",
	       i, top->top__DOT__decode0__DOT__reg0__DOT__regfile[i]);
      printf("\n");
      for (int i=8; i < 16; i++)
	printf("% 3d: %08x",
	       i, top->top__DOT__decode0__DOT__reg0__DOT__regfile[i]);
      printf("\n");
      printf("ssp: %08x\n", top->top__DOT__decode0__DOT__reg0__DOT__ssp);
      printf("--- HAZARD STATE ---\n");
      printf("h1: %02x h2: %02x\n",
	     top->hazard1, top->hazard2);
      //      printf("--- BUS STATE ---\n");
      cycle++;
    }

    top->eval();

    tick++;
  }
  top->final();
  delete top;
  exit(0);
}
