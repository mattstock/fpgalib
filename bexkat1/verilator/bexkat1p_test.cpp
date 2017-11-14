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

    if (top->clk_i) {
      printf("%03d: i_cyc: %d i_adr: %08x i_dat: %08x d_cyc: %d, d_adr: %08x, d_dat_i: %08x, dat_we: %d\n",
	     cycle,
	     top->ins_cyc,
	     top->ins_adr,
	     top->ins_dat,
	     top->dat_cyc,
	     top->dat_adr,
	     top->dat_cpu_in,
	     top->dat_we);
      printf("     if: %d read1: %04x read2: %04x\n",
	     top->top__DOT__cpu0__DOT__fetch0__DOT__state,
	     top->top__DOT__cpu0__DOT__decode0__DOT__reg_read1,
	     top->top__DOT__cpu0__DOT__decode0__DOT__reg_read2);
      printf("     if_pc: %08x id_pc: %08x exe_pc: %08x mem_pc: %08x wb_pc: %08x\n",
	     top->top__DOT__cpu0__DOT__pc[0],
	     top->top__DOT__cpu0__DOT__pc[1],
	     top->top__DOT__cpu0__DOT__pc[2],
	     top->top__DOT__cpu0__DOT__pc[3],
	     top->top__DOT__cpu0__DOT__pc[4]);
      cycle++;
    }

    top->eval();


    tick++;
  }
  top->final();
  delete top;
  exit(0);
}
