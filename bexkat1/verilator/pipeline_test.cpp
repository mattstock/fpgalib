#include <iostream>
#include <fstream>
#include <stdio.h>
#include <cstdarg>
#include "Vcache_top.h"
#include "Vpipeline_top.h"
#include "verilated.h"
#include <verilated_vcd_c.h>
#include "memory.h"

#define INS_RA(x) (0xf & (x >> 20))
#define INS_RB(x) (0xf & (x >> 16))
#define INS_RC(x) (0xf & (x >> 12))

static const char *ifetchstatestr[] = {
  "IDLE", "FETCH", "END", "HALT" };

static const char *memstatestr[] = {
  "IDLE", "EXC", "LOAD", "STORE", "PUSH", "POP", "JSR", "RTS" };
static const char *cachestatestr[] = {
  "IDLE", "BUSY", "HIT", "MISS",
  "FILL", "FILL2", "FILL3", "FILL4", "FILL5",
  "FLUSH", "FLUSH2", "FLUSH3", "FLUSH4", "FLUSH5",
  "FILL_WAIT", "FLUSH_WAIT", "DONE", "INIT", "BUSY2", "BUSY3" };

static const char *cachebusstatestr[] = {
  "IDLE", "ACK", "READ_WAIT", "WAIT" };

using namespace std;
Vpipeline_top* cpu;
Vcache_top* cache;
VerilatedVcdC* cputrace;
VerilatedVcdC* cachetrace;
ofstream debugfile, outputfile;

#define D_DEBUG 0
#define D_BOTH  1

void emit(int type, const char * fmt...)
{
  char buf[200];
  va_list args;

  va_start(args, fmt);
  vsprintf(buf, fmt, args);
  if (type == D_BOTH)
    cout << buf;
  debugfile << buf;

  va_end(args);
}

int main(int argc, char **argv, char **env) {
  uint8_t mode = 0;
  uint8_t str_count = 0;
  vluint64_t tick = 0, cycle = 0;
  char *tracefile;
  char cachetracefile[40]; 
  MemoryBlock *ram0, *rom0, *output0;
  
  for (int i=1; i < argc; i++) {
    if (!strncmp(argv[i], "--debug=", 8)) {
      debugfile.open(argv[i]+8);
    }
    if (!strncmp(argv[i], "--output=", 9)) {
      outputfile.open(argv[i]+9);
    }
   if (!strncmp(argv[i], "--trace=", 8)) {
      tracefile = argv[i]+8;
      strncpy(cachetracefile, tracefile, 40);
      strncat(cachetracefile, "_cache", 40);
    }
  }
    
  Verilated::commandArgs(argc, argv);
  cpu = new Vpipeline_top;
  cache = new Vcache_top;
  Verilated::traceEverOn(true);
  cputrace = new VerilatedVcdC;
  cachetrace = new VerilatedVcdC;
  cpu->trace(cputrace, 99);
  cache->trace(cachetrace, 99);
  cputrace->open(tracefile);
  cachetrace->open(cachetracefile);
  
  cpu->rst_i = 1;
  cpu->clk_i = 0;
  cache->rst_i = 1;
  cache->clk_i = 0;
  cpu->interrupts = 0;
  rom0 = new MemoryBlock("rom0", debugfile, 8*1024, "../ram0.srec");  
  ram0 = new MemoryBlock("ram0", debugfile, 8*1024);  
  output0 = new MemoryBlock("output0", debugfile, 512);  
  
  while (!Verilated::gotFinish() && tick < 200000) {
    // Run the clock
    cpu->clk_i ^= 0x1;
    cache->clk_i ^= 0x1;
    
    // Drop reset
    if (tick == 4) {
      cpu->rst_i = 0;
      cache->rst_i = 0;
    }

    if (cpu->clk_i) {
      // Memory in wiring
      if (cpu->dat_adr_o >= 0x00000000 && cpu->dat_adr_o < 0x10000000) {
	ram0->bus1(cpu->dat_cyc_o, cpu->dat_stb_o, cpu->dat_adr_o, cpu->dat_we_o, cpu->dat_sel_o, cpu->dat_dat_o);
	cpu->dat_dat_i = ram0->read1();
	cpu->dat_ack_i = ram0->ack1();
      }
      if (cpu->dat_adr_o >= 0x50000000 && cpu->dat_adr_o < 0x60000000) {
	output0->bus1(cpu->dat_cyc_o, cpu->dat_stb_o, cpu->dat_adr_o, cpu->dat_we_o, cpu->dat_sel_o, cpu->dat_dat_o);
	cpu->dat_dat_i = output0->read1();
	cpu->dat_ack_i = output0->ack1();
      }
      if (cpu->ins_adr_o >= 0x70000000 && cpu->ins_adr_o < 0x80000000) {
 	rom0->bus0(cpu->ins_cyc_o, cpu->ins_stb_o, cpu->ins_adr_o);
	cpu->ins_dat_i = rom0->read0();
	cpu->ins_ack_i = rom0->ack0();
      }
    }

    cpu->eval();
    cache->eval();
    rom0->eval();
    ram0->eval();
    output0->eval();
    
    cputrace->dump(tick);
    cachetrace->dump(tick);

    if (cpu->clk_i) {
      emit(D_DEBUG, "-------------------- %03ld --------------------\n", cycle);
      emit(D_DEBUG, "--- PIPELINE STATE ---\n");
      emit(D_DEBUG, "     %*s %*s %*s %*s\n",
	   16, "ifetch",
	   16, "idecode",
	   33, "exec",
	   16, "mem");
      emit(D_DEBUG, "pc:  %*x %*x %*x %*x\n",
	   16, cpu->if_pc,
	   16, cpu->id_pc,
	   33, cpu->exe_pc,
	   16, cpu->mem_pc);
      emit(D_DEBUG, "ir:  %*lx %*lx %*lx %*lx\n",
	   16, cpu->if_ir,
	   16, cpu->id_ir,
	   33, cpu->exe_ir,
	   16, cpu->mem_ir);
      emit(D_DEBUG, "ra:  %*lx %*lx %*lx %*lx\n",
	   16, INS_RA(cpu->if_ir),
	   16, INS_RA(cpu->id_ir),
	   33, INS_RA(cpu->exe_ir),
	   16, INS_RA(cpu->mem_ir));
      emit(D_DEBUG, "rb:  %*lx %*lx %*lx %*lx\n",
	   16, INS_RB(cpu->if_ir),
	   16, INS_RB(cpu->id_ir),
	   33, INS_RB(cpu->exe_ir),
	   16, INS_RB(cpu->mem_ir));
      emit(D_DEBUG, "rc:  %*lx %*lx %*lx %*lx\n",
	   16, INS_RC(cpu->if_ir),
	   16, INS_RC(cpu->id_ir),
	   33, INS_RC(cpu->exe_ir),
	   16, INS_RC(cpu->mem_ir));
      emit(D_DEBUG, "spd: %*s %*x/%*x %*x %*x\n",
	   16, "",
	   16, cpu->id_sp_data,
	   16, cpu->exe_sp_in,
	   16, cpu->exe_sp_data,
	   16, cpu->mem_sp_data);
      emit(D_DEBUG, "spw: %*s %*x %*x %*x\n",
	   16, "",
	   16, cpu->id_sp_write,
	   33, cpu->exe_sp_write,
	   16, cpu->mem_sp_write);
      emit(D_DEBUG, "rd1: %*s %*x/%*x %*x\n",
	   16, "",
	   16, cpu->id_reg_data_out1,
	   16, cpu->exe_data1,
	   16, cpu->exe_reg_data_out1);
      emit(D_DEBUG, "rd2: %*s %*x/%*x %*x\n",
	   16, "",
	   16, cpu->id_reg_data_out2,
	   16, cpu->exe_data2,
	   16, cpu->exe_reg_data_out2);
      emit(D_DEBUG, "res: %*s %*s %*x %*x\n",
	   16, "",
	   16, "",
	   33, cpu->exe_result,
	   16, cpu->mem_result);
      emit(D_DEBUG, "ccr: %*s %*s %*x\n",
	   16, "",
	   16, "",
	   33, (cpu->supervisor << 8) |cpu->exe_ccr);
      emit(D_DEBUG, "rwr: %*s %*d %*d %*d\n",
	   16, "",
	   16, cpu->id_reg_write,
	   33, cpu->exe_reg_write,
	   16, cpu->mem_reg_write);
      emit(D_DEBUG, "pcs: %*s %*s %*d %*d\n",
	   16, "",
	   16, "",
	   33, cpu->exe_pc_set,
	   16, cpu->mem_pc_set);
      emit(D_DEBUG, "exc: %*s %*s %*d %*d\n",
	   16, "",
	   16, "",
	   33, cpu->exe_exc,
	   16, cpu->mem_exc);
      emit(D_DEBUG, "h1: %02x h2: %02x hsp: %02x hs: % 2d es: % 2d ms: % 2d wad: %02d\n",
	   cpu->hazard1, cpu->hazard2, cpu->sp_hazard,
	   cpu->hazard_stall,
	   cpu->exe_stall, cpu->mem_stall,
	   cpu->mem_reg_write_addr);
      emit(D_DEBUG, "alu_func: %d alu1: %08x alu2: %08x alu_out: %08x int_func: %d int_out: %08x\n",
	   cpu->pipeline_top__DOT__exe0__DOT__alu_func,
	   cpu->pipeline_top__DOT__exe0__DOT__alu_in1,
	   cpu->pipeline_top__DOT__exe0__DOT__alu_in2,
	   cpu->pipeline_top__DOT__exe0__DOT__alu_out,
	   cpu->pipeline_top__DOT__exe0__DOT__int_func,
	   cpu->pipeline_top__DOT__exe0__DOT__int_out);
      for (int i=0; i < 8; i++)
	emit(D_DEBUG, "%*d: %08x",
	     3, i, cpu->pipeline_top__DOT__decode0__DOT__reg0__DOT__regfile[i]);
      emit(D_DEBUG, "\n");
      for (int i=8; i < 16; i++)
	emit(D_DEBUG, "%*d: %08x",
	     3, i+4*cpu->id_bank,
	     cpu->pipeline_top__DOT__decode0__DOT__reg0__DOT__regfile[i+4*cpu->id_bank]);
      emit(D_DEBUG, "\n");
      emit(D_DEBUG, "vectoff: %08x inten: %*d interrupts: %*x\n",
	   cpu->pipeline_top__DOT__exe0__DOT__vectoff,
	   2, cpu->cpu_inter_en,
	   2, cpu->interrupts);
      emit(D_DEBUG, "Ins: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x stall: %d state: %s\n",
	   cpu->ins_adr_o,
	   cpu->ins_cyc_o,
	   cpu->ins_stb_o,
	   cpu->ins_ack_i,
	   cpu->ins_dat_i,
	   cpu->ins_stall_i,
	   ifetchstatestr[cpu->pipeline_top__DOT__fetch0__DOT__state]);
      emit(D_DEBUG, "  fifo: cidx: %x ridx: %x widx: %x value[idx]: %08x\n",
	   cpu->pipeline_top__DOT__fetch0__DOT__cidx,
	   cpu->pipeline_top__DOT__fetch0__DOT__ffifo__DOT__ridx,
	   cpu->pipeline_top__DOT__fetch0__DOT__ffifo__DOT__widx,
	   cpu->pipeline_top__DOT__fetch0__DOT__ffifo__DOT__values[cpu->pipeline_top__DOT__fetch0__DOT__ffifo__DOT__ridx]);
      emit(D_DEBUG, "Mem: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x dat_o: %08x we: %d sel: %1x stall: %d state %s\n",
	   cpu->dat_adr_o, cpu->dat_cyc_o, cpu->dat_stb_o, cpu->dat_ack_i, cpu->dat_dat_i,
	   cpu->dat_dat_o, cpu->dat_we_o, cpu->dat_sel_o, cpu->dat_stall_i,
	   memstatestr[cpu->pipeline_top__DOT__mem0__DOT__state]);
      cycle++;
    }

    if (cpu->mem_halt) {
      emit(D_DEBUG, "HALT\n");
      emit(D_BOTH, "Registers:\n");
      for (int i=0; i < 8; i++)
	emit(D_BOTH, "%*d: %08x",
	     3, i, cpu->pipeline_top__DOT__decode0__DOT__reg0__DOT__regfile[i]);
      emit(D_BOTH, "\n");
      for (int i=8; i < 16; i++)
	emit(D_BOTH, "%*d: %08x",
	     3, i, cpu->pipeline_top__DOT__decode0__DOT__reg0__DOT__regfile[i]);
      emit(D_BOTH, "\n");
      emit(D_BOTH, "Memory:\n");
      ram0->dump(debugfile);
      ram0->dump(cout);
      break;
    }
    
    tick++;
  }

  if (!Verilated::gotFinish()) {
    emit(D_DEBUG, "FAIL RAM:\n");
    ram0->dump(debugfile);
    emit(D_DEBUG, "\nFAIL ROM:\n");
    rom0->dump(debugfile);
  } 

  output0->dump(outputfile);
  outputfile.close();
  debugfile.close();
  cputrace->close();
  cachetrace->close();
  delete cputrace;
  delete cachetrace;
  cpu->final();
  cache->final();
  delete cpu;
  delete cache;
  exit(0);
}
