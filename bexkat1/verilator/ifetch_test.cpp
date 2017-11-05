#include <iostream>
#include "Vifetch.h"
#include "verilated.h"

using namespace std;

Vifetch* ifetch;

int main(int argc, char **argv, char **env) {
  uint8_t mode = 0;
  uint8_t str_count = 0;
  vluint64_t tick = 0;
  
  Verilated::commandArgs(argc, argv);
  ifetch = new Vifetch;

  ifetch->rst_i = 1;
  ifetch->clk_i = 0;
  ifetch->pc_in = 0;
  ifetch->pc_set = 0;
  ifetch->bus_in = 0;
  ifetch->bus_ack = 0;

  while (!Verilated::gotFinish()) {
    // Run the clock
    ifetch->clk_i = ~ifetch->clk_i;
    
    // Drop reset
    if (tick > 10)
      ifetch->rst_i = 0;

    if (ifetch->bus_cyc) {
      switch (ifetch->pc) {
      case 0:
	ifetch->bus_in = 0x10101010;
	ifetch->bus_ack = 1;
	break;
      case 4:
	ifetch->bus_in = 0x20202020;
	ifetch->bus_ack = 1;
	break;
      case 8:
	ifetch->bus_in = 0x30303030;
	ifetch->bus_ack = 1;
	break;
      default:
	ifetch->bus_in = 0xffffffff;
	ifetch->bus_ack = 1;
	break;
      }
    }

    if (tick == 30) {
      ifetch->pc_in = 0x70000000;
      ifetch->pc_set = 1;
    }

    if (tick == 34)
      ifetch->pc_set = 0;
    
    ifetch->eval();

    if (ifetch->clk_i)
      printf("%d: pc: %08x, ir: %08x, cyc: %d\n",
	     tick,
	     ifetch->pc,
	     ifetch->ir,
	     ifetch->bus_cyc);

    if (ifetch->bus_cyc == 0)
      ifetch->bus_ack = 0;
    
    tick++;

  }
  ifetch->final();
  delete ifetch;
  exit(0);
}
