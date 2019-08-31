`timescale 1ns / 1ns
`define NO_MODPORT_EXPRESSIONS
`include "bexkat2.vh"
`include "wb.vh"

module top(input              clk_i,
	   input 	      rst_i,
	   output logic [1:0] cache_status,
	   output [31:0]      cache0_adr_o,
	   output 	      cache0_cyc_o,
	   input 	      cache0_ack_i,
	   output 	      cache0_stb_o,
	   input 	      cache0_stall_i,
	   input [31:0]       cache0_dat_i,
	   output 	      cache0_we_o,
	   output [3:0]       cache0_sel_o,
	   output [31:0]      cache0_dat_o, 
	   output [31:0]      dat_adr_o,
	   output 	      dat_cyc_o,
	   input 	      dat_ack_i,
	   output 	      dat_stb_o,
	   input 	      dat_stall_i,
	   input [31:0]       dat_dat_i,
	   output 	      dat_we_o,
	   output [3:0]       dat_sel_o,
	   output [31:0]      dat_dat_o);
  
  if_wb cachebus0(), stats0(), outbus();

  assign cache0_adr_o = cachebus0.adr;
  assign cache0_cyc_o = cachebus0.cyc;
  assign cachebus0.ack = cache0_ack_i;
  assign cache0_stb_o = cachebus0.stb;
  assign cachebus0.dat_s = cache0_dat_i;
  assign cache0_we_o = cachebus0.we;
  assign cachebus0.stall = cache0_stall_i;
  assign cache0_sel_o = cachebus0.sel;
  assign cache0_dat_o = cachebus0.dat_m;
  assign dat_adr_o = outbus.adr;
  assign dat_cyc_o = outbus.cyc;
  assign outbus.ack = dat_ack_i;
  assign dat_stb_o = outbus.stb;
  assign outbus.dat_s = dat_dat_i;
  assign dat_we_o = outbus.we;
  assign outbus.stall = dat_stall_i;
  assign dat_sel_o = outbus.sel;
  assign dat_dat_o = outbus.dat_m;

  cache #(.AWIDTH(13), .TAGSIZE(7)) cache0(.clk_i(clk_i),
					    .rst_i(rst_i),
					    .inbus(cachebus0.slave),
					    .outbus(outbus.master),
					    .cache_status(cache_status),
					    .stats(stats0.slave));
endmodule // top
