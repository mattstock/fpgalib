`timescale 1ns / 1ns
`define NO_MODPORT_EXPRESSIONS
`include "bexkat2.vh"
`include "wb.vh"

module top(input              clk_i,
	   input 	      rst_i,
	   input [2:0] 	      interrupts,
	   output 	      int_en,
	   output logic [3:0] exception,
	   output logic       supervisor,
	   output logic       halt,
	   output [31:0]      ins_adr_o,
	   input 	      ins_stall_i,
	   input 	      ins_ack_i,
	   output 	      ins_cyc_o,
	   output 	      ins_stb_o,
	   input [31:0]       ins_dat_i,
	   output [31:0]      dat_adr_o,
	   output 	      dat_cyc_o,
	   input 	      dat_ack_i,
	   output 	      dat_stb_o,
	   input 	      dat_stall_i,
	   input [31:0]       dat_dat_i,
	   output 	      dat_we_o,
	   output [3:0]       dat_sel_o,
	   output [31:0]      dat_dat_o);
   
  if_wb ins_bus(), dat_bus();
  
  assign ins_adr_o = ins_bus.adr;
  assign ins_bus.ack = ins_ack_i;
  assign ins_cyc_o = ins_bus.cyc;
  assign ins_bus.stall = ins_stall_i;
  assign ins_stb_o = ins_bus.stb;
  assign ins_bus.dat_s = ins_dat_i;
  assign dat_adr_o = dat_bus.adr;
  assign dat_cyc_o = dat_bus.cyc;
  assign dat_bus.ack = dat_ack_i;
  assign dat_stb_o = dat_bus.stb;
  assign dat_bus.dat_s = dat_dat_i;
  assign dat_we_o = dat_bus.we;
  assign dat_bus.stall = dat_stall_i;
  assign dat_sel_o = dat_bus.sel;
  assign dat_dat_o = dat_bus.dat_m;

  bexkat2 cpu0(.clk_i(clk_i), .rst_i(rst_i),
	       .ins_bus(ins_bus.master),
	       .dat_bus(dat_bus.master),
	       .halt(halt),
	       .int_en(int_en),
	       .inter(interrupts),
	       .exception(exception),
	       .supervisor(supervisor));
  
endmodule // top
