#include <iostream>
#include <fstream>
#include <stdio.h>
#include <cstdarg>
#include "Vmicrocode_top.h"
#include "verilated.h"
#include <verilated_vcd_c.h>

#define INS_RA(x) (0xf & (x >> 20))
#define INS_RB(x) (0xf & (x >> 16))
#define INS_RC(x) (0xf & (x >> 12))

static const char *statestr[] = {
  "RESET", "EXC", "EXC2", "EXC3",
  "EXC4", "EXC5", "EXC6", "EXC7",
  "EXC8", "EXC9", "EXC10", "JUMPD", "EXC12",
  "EXC13", "EXC14", "FETCH2", "ARG2",
  "FETCH", "LOADD2", "EVAL", "TERM",
  "ARG", "INH", "RELADDR", "PUSH",
  "PUSH2", "PUSH3", "PUSH4", "PUSH5",
  "POP", "POP2", "POP3", "POP4", "RTS",
  "RTS2", "RTS3", "CMP", "CMP2", "CMPS",
  "CMPS2", "CMPS3", "MOV", "INTU",
  "MDR2RA", "ALU", "ALU2", "ALU3", "ALU4",
  "INT", "INT2", "INT3", "BRANCH",
  "LDIU", "JUMP", "JUMP2", "JUMP3",
  "LOAD", "LOAD2", "LOAD3", "LOADD",
  "STORE", "STORE2", "STORE3", "STORE4",
  "STORED", "STORED2", "HALT", "RTI",
  "RTI2", "RTI3", "RTI4", "RTI5",
  "PUSH6", "POP5", "RTI6", "RTS4", "LOADD3",
  "STORE5", "ARG3" };

static const char *cachestatestr[] = {
  "IDLE", "BUSY", "HIT", "MISS",
  "FILL", "FILL2", "FILL3", "FILL4", "FILL5",
  "FLUSH", "FLUSH2", "FLUSH3", "FLUSH4", "FLUSH5",
  "DONE",
  "FILL_WAIT", "FILL2_WAIT", "FILL3_WAIT", "FILL4_WAIT",
  "FLUSH_WAIT", "FLUSH2_WAIT", "FLUSH3_WAIT", "FLUSH4_WAIT",
  "INIT", "BUSY2" };

static const char *cachebusstatestr[] = {
  "IDLE", "ACK", "READ_WAIT", "WAIT" };

using namespace std;
Vmicrocode_top* top;
VerilatedVcdC* trace;
ofstream debugfile;

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

  if (argc != 3) {
    printf("Need debug and trace files on command line.\n");
    exit(1);
  }
  
  debugfile.open(argv[1]);
    
  Verilated::commandArgs(argc, argv);
  top = new Vmicrocode_top;
  Verilated::traceEverOn(true);
  trace = new VerilatedVcdC;
  top->trace(trace, 99);
  trace->open(argv[2]);
  
  top->rst_i = 1;
  top->clk_i = 0;
  top->interrupts = 0;
  
  while (!Verilated::gotFinish() && tick < 5000) {
    // Run the clock
    top->clk_i = ~top->clk_i;
    
    // Drop reset
    if (tick == 2)
      top->rst_i = 0;
    
    top->eval();

    trace->dump(tick);
    trace->flush();
    
    if (top->clk_i) {
      emit(D_DEBUG, "-------------------- %03ld --------------------\n", cycle);
      emit(D_DEBUG, "state: %*s  ", 8,
	   statestr[top->top__DOT__cpu0__DOT__con0__DOT__state]);
      emit(D_DEBUG, "pc: %08x  ir: %08x  mdr: %08x  mar: %08x  a: %08x  b: %08x\n",
	   top->top__DOT__cpu0__DOT__pc,
	   top->top__DOT__cpu0__DOT__ir,
	   top->top__DOT__cpu0__DOT__mdr,
	   top->top__DOT__cpu0__DOT__mar,
	   top->top__DOT__cpu0__DOT__a,
	   top->top__DOT__cpu0__DOT__b);
      emit(D_DEBUG, "ccr: %02x  status: %02x  ssp: %08x\n",
	   top->top__DOT__cpu0__DOT__ccr,
	   top->top__DOT__cpu0__DOT__status,
	   top->top__DOT__cpu0__DOT__intreg__DOT__ssp);
	   
      for (int i=0; i < 8; i++)
	emit(D_DEBUG, "%*d: %08x",
	     3, i, top->top__DOT__cpu0__DOT__intreg__DOT__regfile[i]);
      emit(D_DEBUG, "\n");
      for (int i=8; i < 16; i++)
	emit(D_DEBUG, "%*d: %08x",
	     3, i, top->top__DOT__cpu0__DOT__intreg__DOT__regfile[i]);
      emit(D_DEBUG, "\n");
      emit(D_DEBUG, "Ins: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x stall: %d\n",
	   top->ins_adr_o,
	   top->ins_cyc_o,
	   top->ins_stb_o,
	   top->ins_ack_i,
	   top->ins_dat_i,
	   top->ins_stall_i);
      emit(D_DEBUG, "Dat: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x dat_o: %08x we: %d sel: %1x stall: %d\n",
	   top->dat_adr_o, top->dat_cyc_o, top->dat_stb_o, top->dat_ack_i, top->dat_dat_i,
	   top->dat_dat_o, top->dat_we_o, top->dat_sel_o, top->dat_stall_i);

      emit(D_DEBUG, "Cache: state: %*s bus state: %*s\n",
	   6, cachestatestr[top->top__DOT__cache0__DOT__state],
	   9, cachebusstatestr[top->top__DOT__cache0__DOT__bus_state]);
      
      emit(D_DEBUG, "Cache0: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x dat_o: %08x we: %d sel: %1x stall: %d\n",
	   top->cache0_adr_o, top->cache0_cyc_o, top->cache0_stb_o, top->cache0_ack_i, top->cache0_dat_i,
	   top->cache0_dat_o, top->cache0_we_o, top->cache0_sel_o, top->cache0_stall_i);
      emit(D_DEBUG, "row0: in: %03x%08x%08x%08x%08x out: %03x%08x%08x%08x%08x\n",
	   top->top__DOT__cache0__DOT__rowin[0][4],
	   top->top__DOT__cache0__DOT__rowin[0][3],
	   top->top__DOT__cache0__DOT__rowin[0][2],
	   top->top__DOT__cache0__DOT__rowin[0][1],
	   top->top__DOT__cache0__DOT__rowin[0][0],
	   top->top__DOT__cache0__DOT__rowout[0][4],
	   top->top__DOT__cache0__DOT__rowout[0][3],
	   top->top__DOT__cache0__DOT__rowout[0][2],
	   top->top__DOT__cache0__DOT__rowout[0][1],
	   top->top__DOT__cache0__DOT__rowout[0][0]);
      emit(D_DEBUG, "row1: in: %03x%08x%08x%08x%08x out: %03x%08x%08x%08x%08x\n",
	   top->top__DOT__cache0__DOT__rowin[1][4],
	   top->top__DOT__cache0__DOT__rowin[1][3],
	   top->top__DOT__cache0__DOT__rowin[1][2],
	   top->top__DOT__cache0__DOT__rowin[1][1],
	   top->top__DOT__cache0__DOT__rowin[1][0],
	   top->top__DOT__cache0__DOT__rowout[1][4],
	   top->top__DOT__cache0__DOT__rowout[1][3],
	   top->top__DOT__cache0__DOT__rowout[1][2],
	   top->top__DOT__cache0__DOT__rowout[1][1],
	   top->top__DOT__cache0__DOT__rowout[1][0]);

      emit(D_DEBUG, "fifo: write: %d read: %d saved: %016lx\n",
	   top->top__DOT__cache0__DOT__fifo_write,
	   top->top__DOT__cache0__DOT__fifo_read,
	   top->top__DOT__cache0__DOT__fifo_saved);
      emit(D_DEBUG, "words0: 3: %08x 2: %08x 1: %08x 0: %08x\n",
	   top->top__DOT__cache0__DOT__word3[0],
	   top->top__DOT__cache0__DOT__word2[0],
	   top->top__DOT__cache0__DOT__word1[0],
	   top->top__DOT__cache0__DOT__word0[0]);
      emit(D_DEBUG, "words1: 3: %08x 2: %08x 1: %08x 0: %08x\n",
	   top->top__DOT__cache0__DOT__word3[1],
	   top->top__DOT__cache0__DOT__word2[1],
	   top->top__DOT__cache0__DOT__word1[1],
	   top->top__DOT__cache0__DOT__word0[1]);
	   
      emit(D_DEBUG, "cmem0: adr: %08x we: %d hitset: %d lruset: %d\n",
	   top->top__DOT__cache0__DOT____Vcellinp__cmem0__address,
	   top->top__DOT__cache0__DOT__wren & 0x1,
	   top->top__DOT__cache0__DOT__hitset,
	   top->top__DOT__cache0__DOT__lruset);
	   
      emit(D_DEBUG, "Ram0: adr: %08x cyc: %d stb: %d ack: %d dat_i: %08x dat_o: %08x we: %d sel: %1x stall: %d\n",
	   top->ram0_adr_o, top->ram0_cyc_o, top->ram0_stb_o, top->ram0_ack_i, top->ram0_dat_i,
	   top->ram0_dat_o, top->ram0_we_o, top->ram0_sel_o, top->ram0_stall_i);
      cycle++;
    }

    if (top->halt) {
      emit(D_DEBUG, "HALT\n");
      
      emit(D_BOTH, "Registers:\n");
      for (int i=0; i < 8; i++)
	emit(D_BOTH, "%*d: %08x",
	     3, i, top->top__DOT__cpu0__DOT__intreg__DOT__regfile[i]);
      emit(D_BOTH, "\n");
      for (int i=8; i < 16; i++)
	emit(D_BOTH, "%*d: %08x",
	     3, i, top->top__DOT__cpu0__DOT__intreg__DOT__regfile[i]);
      emit(D_BOTH, "\n");
      emit(D_BOTH, "Memory:\n");
      for (int i=0; i < 8*1024; i++) {
	if (i%16==0) {
	  if (i != 0)
	    emit(D_BOTH, "\n");
	  emit(D_BOTH, "%04x: ", i);
	}
	emit(D_BOTH, "%02x ", top->top__DOT__ram0__DOT__mem[i]);
      }
      break;
    }
    
    tick++;
  }
  debugfile.close();
  trace->close();
  top->final();
  delete top;
  exit(0);
}
