#include <iostream>
#include "Vbexkat1.h"
#include "verilated.h"

using namespace std;

Vbexkat1* top;
vluint64_t main_time = 0;

int main(int argc, char **argv, char **env) {
  Verilated::commandArgs(argc, argv);
  Vbexkat1* top = new Vbexkat1;

  top->rst_i = 1;
  top->clk_i = 0;
  
  while (!Verilated::gotFinish()) {
	// Run the clock
	if (main_time % 10)
          top->clk_i = ~top->clk_i;

        // Drop reset
	if (main_time > 10)
          top->rst_i = 0;

	top->eval();
	printf("tick: %ld  cyc: %d  adr_o: %08x\n", main_time, top->cyc_o, top->adr_o);
        main_time++;
  }
  top->final();
  delete top;
  exit(0);
}
