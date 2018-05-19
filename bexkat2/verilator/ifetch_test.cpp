#include <iostream>
#include "Vifetch.h"
#include "verilated.h"

using namespace std;
Vifetch* top;

uint32_t mem[] = {
  0x00112222,
  0x01333330,
  0x02293480,
  0x03483722,
  0x04494382,
  0x05302824,
  0x06382722,
  0x07827230,
  0x08847244
};

void ramop() {
  static uint8_t state;
  static uint32_t nextaddr;
  
  if (top->rst_i) {
    state = 0;
    top->bus_ack = 0;
    top->bus_in = 0;
  } else {
    switch (state) {
    case 0:
      top->bus_ack = 0;
      top->bus_in = 0;
      if (top->bus_cyc) {
	state = 1;
	nextaddr = top->bus_adr;
      }
      break;
    case 1:
      top->bus_ack = 1;
      top->bus_in = mem[(nextaddr >> 2) % (sizeof(mem)/sizeof(uint32_t))];
      nextaddr = top->bus_adr;
      if (!top->bus_cyc)
	state = 0;
      break;
    }
  }
  
}

int main(int argc, char **argv, char **env) {
  uint8_t mode = 0;
  uint8_t str_count = 0;
  uint32_t addr = 0;
  vluint64_t tick = 0, cycle = 0;

  Verilated::commandArgs(argc, argv);
  top = new Vifetch;

  top->rst_i = 1;
  top->clk_i = 0;
  top->bus_stall_i = 0;
  top->bus_ack = 0;
  top->bus_in = 0;
  top->pc_in = 0;
  top->pc_set = 0;
  top->stall_i = 0;

  while (!Verilated::gotFinish()) {
    // Run the clock
    top->clk_i = ~top->clk_i;

    switch (cycle) {
    case 6:
      top->rst_i = 0;
      break;
    case 20:
      top->pc_in = 0x00000008;
      top->pc_set = 1;
      break;
    case 21:
      top->pc_set = 0;
      top->pc_in = 0x33334444;
    }

    ramop();
    
    top->eval();

    if (top->clk_i) {
      printf("\n%03d ir:%016lx pc:%08x pcs:%d pci:%08x si:%d adr:%08x cyc:%d bsi:%d ack:%d in:%08x st:%d\n",
	   cycle,
	     top->ir,
	     top->pc,
	     top->pc_set,
	     top->pc_in,
	     top->stall_i,
	     top->bus_adr,
	     top->bus_cyc,
	     top->bus_stall_i,
	     top->bus_ack,
	     top->bus_in,
	     top->ifetch__DOT__state);
      printf("%4sridx: %d widx: %d empty: %d full: %d out: %08x\n",
	     "",
	     top->ifetch__DOT__fifo0__DOT__ridx,
	     top->ifetch__DOT__fifo0__DOT__widx,
	     top->ifetch__DOT__fifo0__DOT__cidx == 0,
	     top->ifetch__DOT__fifo0__DOT__cidx == 15,
	     top->ifetch__DOT__fifo0__DOT__values[top->ifetch__DOT__fifo0__DOT__ridx]);
      printf("%4s", "");
      for (int i=0; i < 8; i++)
	printf("%2d: %08x ", i, top->ifetch__DOT__fifo0__DOT__values[i]);
      printf("\n%4s", "");
      for (int i=8; i < 16; i++)
	printf("%2d: %08x ", i, top->ifetch__DOT__fifo0__DOT__values[i]);
      printf("\n");
      cycle++;
    }

    tick++;
  }
  top->final();
  delete top;
  exit(0);
}
