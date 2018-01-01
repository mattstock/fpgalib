#include <iostream>
#include "Vpipeline_top.h"
#include "verilated.h"

#define INS_RA(x) (0xf & (x >> 20))
#define INS_RB(x) (0xf & (x >> 16))
#define INS_RC(x) (0xf & (x >> 12))

using namespace std;
Vpipeline_top* top;

int main(int argc, char **argv, char **env) {
  uint8_t mode = 0;
  uint8_t str_count = 0;
  vluint64_t tick = 0, cycle = 0;
  
  Verilated::commandArgs(argc, argv);
  top = new Vpipeline_top;

  top->rst_i = 1;
  top->clk_i = 0;
  top->interrupts = 0;
  
  while (!Verilated::gotFinish()) {
    // Run the clock
    top->clk_i = ~top->clk_i;
    
    // Drop reset
    if (tick == 2)
      top->rst_i = 0;
    if (tick == 9)
      top->interrupts = 1;
    
    top->eval();

    if (top->clk_i) {
      printf("-------------------- %03d --------------------\n", cycle);
      printf("--- PIPELINE STATE ---\n");
      printf("     % 16s % 16s % 33s % 16s\n",
	     "ifetch",
	     "idecode",
	     "exec",
	     "mem");
	     
      printf("pc:  % 16x % 16x % 33x % 16x\n",
	     top->if_pc,
	     top->id_pc,
	     top->exe_pc,
	     top->mem_pc);
      printf("ir:  %16lx %16lx %33lx %16lx\n",
	     top->if_ir,
	     top->id_ir,
	     top->exe_ir,
	     top->mem_ir);
      printf("ra:  % 16x % 16x % 33x % 16x\n",
	     INS_RA(top->if_ir),
	     INS_RA(top->id_ir),
	     INS_RA(top->exe_ir),
	     INS_RA(top->mem_ir));
      printf("rb:  % 16x % 16x % 33x % 16x\n",
	     INS_RB(top->if_ir),
	     INS_RB(top->id_ir),
	     INS_RB(top->exe_ir),
	     INS_RB(top->mem_ir));
      printf("rc:  % 16x % 16x % 33x % 16x\n",
	     INS_RC(top->if_ir),
	     INS_RC(top->id_ir),
	     INS_RC(top->exe_ir),
	     INS_RC(top->mem_ir));
      printf("spd: % 16s % 16x/% 16x % 16x % 16x\n",
	     "",
	     top->id_sp_data,
	     top->exe_sp_in,
	     top->exe_sp_data,
	     top->mem_sp_data);
      printf("spw: % 16s % 16x % 33x % 16x\n",
	     "",
	     top->id_sp_write,
	     top->exe_sp_write,
	     top->mem_sp_write);
      /*      printf("bnk: % 16s % 16x % 16x % 16x\n",
	     "",
	     top->id_bank,
	     top->exe_bank,
	     top->mem_bank); */
      printf("rd1: % 16s % 16x/% 16x % 16x\n",
	     "",
	     top->id_reg_data_out1,
	     top->exe_data1,
	     top->exe_reg_data_out1);
      printf("rd2: % 16s % 16x/% 16x % 16x\n",
	     "",
	     top->id_reg_data_out2,
	     top->exe_data2,
	     top->exe_reg_data_out2);
      printf("res: % 16s % 16s % 33x % 16x\n",
	     "","",
	     top->exe_result,
	     top->mem_result);
      printf("ccr: % 16s % 16s % 33x\n",
	     "","",
	     top->exe_ccr);
      printf("rwr: % 16s % 16d % 33d % 16d\n",
	     "",
	     top->id_reg_write,
	     top->exe_reg_write,
	     top->mem_reg_write);
      printf("pcs: % 16s % 16s % 33d % 16d\n",
	     "", "",
	     top->exe_pc_set,
	     top->mem_pc_set);
      printf("exc: % 16s % 16s % 33d % 16d\n",
	     "", "",
	     top->exe_exc,
	     top->mem_exc);
      printf("--- INTERNAL STATE ---\n");
      printf("alu_func: %d alu1: %08x alu2: %08x alu_out: %08x int_func: %d int_out: %08x\n",
	     top->top__DOT__exe0__DOT__alu_func,
	     top->top__DOT__exe0__DOT__alu_in1,
	     top->top__DOT__exe0__DOT__alu_in2,
	     top->top__DOT__exe0__DOT__alu_out,
	     top->top__DOT__exe0__DOT__int_func,
	     top->top__DOT__exe0__DOT__int_out);
      for (int i=0; i < 8; i++)
	printf("% 3d: %08x",
	       i, top->top__DOT__decode0__DOT__reg0__DOT__regfile[i]);
      printf("\n");
      for (int i=8; i < 16; i++)
	printf("% 3d: %08x",
	       i+4*top->id_bank,
	       top->top__DOT__decode0__DOT__reg0__DOT__regfile[i+4*top->id_bank]);
      printf("\n");
      printf("vectoff: %08x inten: % 2d interrupts: % 2x\n",
	     top->top__DOT__exe0__DOT__vectoff,
	     top->int_en,
	     top->interrupts);
      printf("h1: %02x h2: %02x hsp: %02x hs: % 2d es: % 2d ms: % 2d wad: %02d\n",
	     top->hazard1, top->hazard2, top->sp_hazard,
	     top->hazard_stall,
	     top->exe_stall, top->mem_stall,
	     top->mem_reg_write_addr);
      printf("Ins: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x stall: %d\n",
	     top->ins_adr_o,top->ins_cyc_o, top->ins_stb_o, top->ins_ack_i, top->ins_dat_i,
	     top->ins_stall_i);
      printf("Dat: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x dat_o: %08x we: %d sel: %1x stall: %d state %x\n",
	     top->dat_adr_o, top->dat_cyc_o, top->dat_stb_o, top->dat_ack_i, top->dat_dat_i,
	     top->dat_dat_o, top->dat_we_o, top->dat_sel_o, top->dat_stall_i,
	     top->top__DOT__mem0__DOT__state);
      printf("Arb: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x dat_o: %08x we: %d sel: %1x stall: %d\n",
	     top->arb_adr_o, top->arb_cyc_o, top->arb_stb_o, top->arb_ack_i, top->arb_dat_i,
	     top->arb_dat_o, top->arb_we_o, top->arb_sel_o, top->arb_stall_i);
      printf("fifo: cidx: %x ridx: %x widx: %x adr[idx]: %08x, path[idx]: %d\n",
	     top->top__DOT__bus0__DOT__fifo0__DOT__cidx,
	     top->top__DOT__bus0__DOT__fifo0__DOT__ridx,
	     top->top__DOT__bus0__DOT__fifo0__DOT__widx,
	     top->top__DOT__bus0__DOT__fifo0__DOT__values[top->top__DOT__bus0__DOT__fifo0__DOT__ridx] >> 1,
	     top->top__DOT__bus0__DOT__fifo0__DOT__values[top->top__DOT__bus0__DOT__fifo0__DOT__ridx] & 0x1);
      cycle++;
    }

    if (top->mem_halt) {
      printf("HALT\n");
      break;
    }
    
    tick++;
  }
  top->final();
  delete top;
  exit(0);
}
