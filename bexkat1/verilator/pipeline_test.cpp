#include <iostream>
#include "Vpipeline_top.h"
#include "verilated.h"

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
      printf("--- %03d ---\n", cycle);
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
      printf("ra:  % 16s % 16x\n",
	     "",
	     top->ir_ra);
      printf("rb:  % 16s % 16x\n",
	     "",
	     top->ir_rb);
      printf("rc:  % 16s % 16x\n",
	     "",
	     top->ir_rc);
      printf("rd1:  % 16s % 16x % 16x\n",
	     "",
	     top->id_reg_data_out1,
	     top->exe_reg_data_out1);
      printf("rd2: % 16s % 16x\n",
	     "",
	     top->id_reg_data_out2);
      printf("res: % 16s % 16s % 16x % 16x % 16x\n",
	     "","",
	     top->exe_result,
	     top->mem_result,
	     top->wb_result);
      printf("ccr: % 16s % 16s % 16x % 16x\n",
	     "","",
	     top->exe_ccr,
	     top->mem_ccr);
      printf("rwr: % 16s % 16s % 16d % 16d % 16d\n",
	     "","",
	     top->exe_reg_write,
	     top->mem_reg_write,
	     top->wb_reg_write);
      printf("wad: % 16s % 16s % 16s % 16s % 16x\n",
	     "","","","",
	     top->wb_reg_write_addr);
      printf("0: %08x 1: %08x 2: %08x\n",
	     top->top__DOT__decode0__DOT__reg0__DOT__regfile[0],
	     top->top__DOT__decode0__DOT__reg0__DOT__regfile[1],
	     top->top__DOT__decode0__DOT__reg0__DOT__regfile[2]);
      cycle++;
    }

    top->eval();

    tick++;
  }
  top->final();
  delete top;
  exit(0);
}
