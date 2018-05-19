#include <iostream>
#include "Vbexkat1p_top.h"
#include "verilated.h"

using namespace std;
Vbexkat1p_top* top;

int main(int argc, char **argv, char **env) {
  uint8_t mode = 0;
  uint8_t str_count = 0;
  vluint64_t tick = 0, cycle = 0;
  
  Verilated::commandArgs(argc, argv);
  top = new Vbexkat1p_top;

  top->rst_i = 1;
  top->clk_i = 0;

  while (!Verilated::gotFinish()) {
    // Run the clock
    top->clk_i = ~top->clk_i;
    
    // Drop reset
    if (tick > 2)
      top->rst_i = 0;
    
    top->eval();
    tick++;
  }
  top->final();
  delete top;
  exit(0);
}
