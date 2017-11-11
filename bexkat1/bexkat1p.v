`timescale 1ns / 1ns
`include "bexkat1.vh"

import bexkat1Def::*;

module bexkat1p(input 	      clk_i,
		input 	      rst_i,
		input 	      ack_i,
		output [31:0] adr_o,
		output logic  cyc_o,
		output logic  we_o,
		output 	      halt,
		input [2:0]   inter,
		output 	      int_en,
		output [3:0]  exception,
		output 	      supervisor,
		input [31:0]  dat_i,
		output [31:0] dat_o,
		output [3:0]  sel_o);

  logic [63:0] 		      ir[3:0];
  logic [31:0] 		      pc;
  logic 		      fetch_cyc;
  logic 		      fetch_ack;
  logic [31:0] 		      pc_new;
  logic [3:0] 		      reg_write_addr;
  logic [31:0] 		      reg_data_in;
  logic [31:0] 		      reg_data_out1;
  logic [31:0] 		      reg_data_out2;
  logic 		      reg_write;
  logic 		      alu_func_t alu_func;

  // we'll need to mux these later, but for now the bus is just for
  // instructions.
  
  assign adr_o = pc;
  assign sel_o = 4'hf;
  assign cyc_o = fetch_cyc;
  assign fetch_ack = ack_i;
  assign pc_new = 32'h0;
  assign exception = 4'h0;
  assign halt = 1'h0;
  assign supervisor = 1'h0;

  // since we only have part of the path defined
  assign reg_write = 1'h0;
  assign reg_data_in 32'h0;
  assign reg_write_addr = 4'h0;

  ifetch fetch0(.clk_i(clk_i), .rst_i(rst_i), .ir(ir[0]), .pc(pc),
		.bus_cyc(fetch_cyc), .bus_ack(fetch_ack),
		.bus_in(dat_i), .pc_in(pc_new));
  
  idecode decode0(.clk_i(clk_i), .rst_i(rst_i), .ir_i(ir[0]),
		  .ir_o(ir[1]),
		  .reg_data_in(reg_data_in),
		  .reg_write_addr(reg_write_addr),
		  .reg_write(reg_write),
		  .reg_data_out1(reg_data_out1),
		  .reg_data_out2(reg_data_out2),
		  .alu_func(alu_func));

  execute exe0(.clk_i(clk_i), .rst_i(rst_i),
	       .reg_data_out(reg_data_in),
	       .reg_write_addr(reg_write_addr),
	       .ir_i(ir[1]),
	       .ir_o(ir[2]));
  mem mem0(.clk_i(clk_i), .rst_i(rst_i),
	   .ir_i(ir[2]),
	   .ir_o(ir[3]));
  wb wb0(.clk_i(clk_i), .rst_i(rst_i),
	 .ir_i(ir[3]));
  
endmodule // bexkat1p
