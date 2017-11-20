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
      printf("%03d: iBUS (%d, %08x, %08x) dBUS (%d, %08x, %08x, %d)\n",
	     cycle,
	     top->ins_cyc,
	     top->ins_adr,
	     top->ins_dat,
	     top->dat_cyc,
	     top->dat_adr,
	     top->dat_cpu_in,
	     top->dat_we);
      printf("     read1[%04x]: %08x read2[%04x]: %08x write[%04x]: %08x, %d\n",
	     top->top__DOT__cpu0__DOT__decode0__DOT__reg_read1,
	     top->top__DOT__cpu0__DOT__reg_data_out1[0],
	     top->top__DOT__cpu0__DOT__decode0__DOT__reg_read2,
	     top->top__DOT__cpu0__DOT__exe0__DOT__alu_in2,
	     top->reg_write_addr,
	     top->top__DOT__cpu0__DOT__result[2],
	     top->top__DOT__cpu0__DOT__reg_write[2]);
      printf("     wr: (%d, %d)\n",
	     top->top__DOT__cpu0__DOT__reg_write[0],
	     top->top__DOT__cpu0__DOT__reg_write[1]);
#if 0	     
      printf("     if_pc: %08x id_pc: %08x exe_pc: %08x mem_pc: %08x wb_pc: %08x\n",
	     top->top__DOT__cpu0__DOT__pc[0],
	     top->top__DOT__cpu0__DOT__pc[1],
	     top->top__DOT__cpu0__DOT__pc[2],
	     top->top__DOT__cpu0__DOT__pc[3],
	     top->top__DOT__cpu0__DOT__pc[4]);
#endif
      cycle++;
    }

    top->eval();


    tick++;
  }
  top->final();
  delete top;
  exit(0);
}
