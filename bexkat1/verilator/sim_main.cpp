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

 #if 1
    if (top->clk_i)
      printf("%d: a:%08x w:%d ir:%08x r0:%d r1:%d io:%d mdr:%08x\n",
	     tick,
	     top->top__DOT__adr,
	     top->top__DOT__we,
	     top->top__DOT__cpu0__DOT__ir,
	     top->top__DOT__rom0_stb,
	     top->top__DOT__rom1_stb,
	     top->top__DOT__io0_stb,
	     top->top__DOT__cpu0__DOT__mdr);
#endif
    if (top->clk_i) {
      if (top->msg_out & 0x80000000) {
	printf("msg: %c\n", top->msg_out & 0xff);
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
