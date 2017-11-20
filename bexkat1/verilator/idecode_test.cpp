#include <iostream>
#include "Videcode_top.h"
#include "verilated.h"

using namespace std;
Videcode_top* top;

int main(int argc, char **argv, char **env) {
  uint8_t mode = 0;
  uint8_t str_count = 0;
  vluint64_t tick = 0, cycle = 0;
  
  Verilated::commandArgs(argc, argv);
  top = new Videcode_top;

  top->rst_i = 1;
  top->clk_i = 0;
  top->pc_i = 0;
  top->pc_set = 0;
  top->stall_i = 0;
  top->reg_write_addr = 0;
  top->reg_write = 0;
  top->reg_data_in = 0;
  
  while (!Verilated::gotFinish()) {
    // Run the clock
    top->clk_i = ~top->clk_i;
    
    // Drop reset
    if (tick == 2)
      top->rst_i = 0;

    if (top->clk_i) {
      printf("--- %03d ---\n", cycle);
      printf("pc:          %08x         %08x\n",
	     top->if_pc,
	     top->id_pc);
      printf("ir:  %016lx %016lx\n",
	     top->if_ir,
	     top->id_ir);
      printf("st:  %16d %16d\n",
	     top->if_stall,
	     top->id_stall);
      printf("rd1:                          %08x\n",
	     top->reg_data_out1);
      printf("rd2:                          %08x\n",
	     top->reg_data_out2);
      cycle++;
    }

    top->eval();


    tick++;
  }
  top->final();
  delete top;
  exit(0);
}
