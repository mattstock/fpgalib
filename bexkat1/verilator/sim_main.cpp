#include <iostream>
#include "Vtop.h"
#include "verilated.h"

using namespace std;

Vtop* top;
vluint64_t main_time = 0, tick = 0;

int main(int argc, char **argv, char **env) {
  Verilated::commandArgs(argc, argv);
  top = new Vtop;
  
  top->rst_i = 1;
  top->clk_i = 0;
  
  while (!Verilated::gotFinish()) {
    // Run the clock
    if (main_time % 10) {
      if (!top->clk_i)
	tick++;
      top->clk_i = ~top->clk_i;
    }
    
    // Drop reset
    if (main_time > 10)
      top->rst_i = 0;
    
    top->eval();
    
    printf("tick: %d, clk: %d, cyc: %d, addr: %08x\n, state: %08x",
	   tick, top->clk_i,
	   top->cpu_cyc, top->cpu_addr,
	   top->top__DOT__cpu0__DOT__con0__DOT__state);
    printf("  rom1: %08x, rom1_ack: %d\n", top->r1dat, top->r1ack);

    main_time++;
  }
  top->final();
  delete top;
  exit(0);
}
