#include <iostream>
#include "Vtop.h"
#include "verilated.h"

using namespace std;

Vtop* top;

int main(int argc, char **argv, char **env) {
  uint8_t mode = 0;
  uint8_t str_count = 0;
  vluint64_t tick = 0;
  
  Verilated::commandArgs(argc, argv);
  top = new Vtop;

  top->rst_i = 1;
  top->clk_i = 0;

  while (!Verilated::gotFinish()) {
    // Run the clock
    top->clk_i = ~top->clk_i;
    
    // Drop reset
    if (tick > 10)
      top->rst_i = 0;
    
    top->eval();

    if (top->clk_i) {
      if (top->msg_out & 0x80000000) {
	printf("%c", top->msg_out & 0xff);
	top->msg_in = 0x80000000;
      } else
	top->msg_in = 0x0;
    }

    tick++;
  }
  top->final();
  delete top;
  exit(0);
}
