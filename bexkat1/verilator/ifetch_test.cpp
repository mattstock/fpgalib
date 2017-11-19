#include <iostream>
#include "Vifetch_top.h"
#include "verilated.h"

using namespace std;
Vifetch_top* top;

int main(int argc, char **argv, char **env) {
  uint8_t mode = 0;
  uint8_t str_count = 0;
  vluint64_t tick = 0, cycle = 0;
  
  Verilated::commandArgs(argc, argv);
  top = new Vifetch_top;

  top->rst_i = 1;
  top->clk_i = 0;
  top->pc_i = 0;
  top->pc_set = 0;

  while (!Verilated::gotFinish()) {
    // Run the clock
    top->clk_i = ~top->clk_i;
    
    // Drop reset
    if (tick > 2)
      top->rst_i = 0;

    if (top->clk_i) {
      printf("%03d: %d, %08x, %d, %d, %08x, %016lx\n",
	     cycle,
	     top->top__DOT__fetch0__DOT__state,
	     top->pc_o,
	     top->bus_cyc_o,
	     top->bus_ack_i,
	     top->bus_dat_i,
	     top->ir_o);
      cycle++;
    }

    top->eval();


    tick++;
  }
  top->final();
  delete top;
  exit(0);
}
