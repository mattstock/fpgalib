`timescale 1ns / 1ns
`define NO_MODPORT_EXPRESSIONS
`include "wb.vh"

module cache_top(input              clk_i,
		 input 		    rst_i,
		 output logic [1:0] cache_status,
		 input [31:0] 	    cache0_adr_i,
		 input 		    cache0_cyc_i,
		 output 	    cache0_ack_o,
		 input 		    cache0_stb_i,
		 output 	    cache0_stall_o,
		 input [31:0] 	    cache0_dat_i,
		 input 		    cache0_we_i,
		 input [3:0] 	    cache0_sel_i,
		 output [31:0] 	    cache0_dat_o, 
		 input [31:0] 	    cache1_adr_i,
		 input 		    cache1_cyc_i,
		 output 	    cache1_ack_o,
		 input 		    cache1_stb_i,
		 output 	    cache1_stall_o,
		 input [31:0] 	    cache1_dat_i,
		 input 		    cache1_we_i,
		 input [3:0] 	    cache1_sel_i,
		 output [31:0] 	    cache1_dat_o, 
		 output [31:0] 	    dat_adr_o,
		 output 	    dat_cyc_o,
		 input 		    dat_ack_i,
		 output 	    dat_stb_o,
		 input 		    dat_stall_i,
		 input [31:0] 	    dat_dat_i,
		 output 	    dat_we_o,
		 output [3:0] 	    dat_sel_o,
		 output [31:0] 	    dat_dat_o,
		 output [31:0] 	    arb_adr_o,
		 output [31:0] 	    arb_dat_s,
		 output [31:0] 	    arb_dat_m);
  
  if_wb cachebus0(), stats0(), outbus(), ibus(), dbus();

  assign ibus.adr = cache0_adr_i;
  assign ibus.cyc = cache0_cyc_i;
  assign cache0_ack_o = ibus.ack;
  assign ibus.stb = cache0_stb_i;
  assign cache0_dat_o = ibus.dat_m;
  assign ibus.we = cache0_we_i;
  assign cache0_stall_o = ibus.stall;
  assign ibus.sel = cache0_sel_i;
  assign ibus.dat_s = cache0_dat_i;

  assign dbus.adr = cache1_adr_i;
  assign dbus.cyc = cache1_cyc_i;
  assign cache1_ack_o = dbus.ack;
  assign dbus.stb = cache1_stb_i;
  assign cache1_dat_o = dbus.dat_m;
  assign dbus.we = cache1_we_i;
  assign cache1_stall_o = dbus.stall;
  assign dbus.sel = cache1_sel_i;
  assign dbus.dat_s = cache1_dat_i;

  assign dat_adr_o = outbus.adr;
  assign dat_cyc_o = outbus.cyc;
  assign outbus.ack = dat_ack_i;
  assign dat_stb_o = outbus.stb;
  assign outbus.dat_s = dat_dat_i;
  assign dat_we_o = outbus.we;
  assign outbus.stall = dat_stall_i;
  assign dat_sel_o = outbus.sel;
  assign dat_dat_o = outbus.dat_m;

  assign arb_adr_o = cachebus0.adr;
  assign arb_dat_m = cachebus0.dat_m;
  assign arb_dat_s = cachebus0.dat_s;
  
  arbiter arb0(.clk_i(clk_i),
	       .rst_i(rst_i),
	       .in0(ibus.slave),
	       .in1(dbus.slave),
	       .out(cachebus0.master));

  bus_term_m term0(stats0.master);
  
  cache #(.AWIDTH(13), .TAGSIZE(7)) cache0(.clk_i(clk_i),
					    .rst_i(rst_i),
					    .inbus(cachebus0.slave),
					    .outbus(outbus.master),
					    .cache_status(cache_status),
					    .stats(stats0.slave));
endmodule // top
