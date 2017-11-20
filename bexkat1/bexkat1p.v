`timescale 1ns / 1ns
`include "bexkat1.vh"

import bexkat1Def::*;

module bexkat1p(input 	      clk_i,
		input 		   rst_i,
		input 		   ins_ack_i,
		output [31:0] 	   ins_adr_o,
		output logic 	   ins_cyc_o,
		output logic 	   ins_we_o,
		input [31:0] 	   ins_dat_i,
		output logic [3:0] ins_sel_o,
		output 		   halt,
		input [2:0] 	   inter,
		output 		   int_en,
		output [3:0] 	   exception,
		output 		   supervisor,
		input 		   dat_ack_i,
		output [31:0] 	   dat_adr_o,
		output logic 	   dat_cyc_o,
		output logic 	   dat_we_o,
		input [31:0] 	   dat_dat_i,
		output [31:0] 	   dat_dat_o,
		output logic [3:0] dat_sel_o,
		output logic [3:0] reg_write_addr);

  // pipeline var
  logic [63:0] 			   ir[3:0];
  logic [31:0] 			   pc[4:0];
  logic [31:0] 			   result[2:0];
  logic [1:0] 			   reg_write[2:0];
  logic [2:0] 			   ccr[1:0];
  logic 			   if_stall, id_stall, exec_stall, mem_stall, wb_stall;
  logic 			   fetch_cyc;
  logic 			   fetch_ack;
  logic [3:0] 			   reg_write_addr;
  logic [31:0] 			   reg_data_in;
  logic [31:0] 			   reg_data_out1[1:0];
  logic [31:0] 			   reg_data_out2;
  logic 			   pc_set;
  
  // we'll need to mux these later, but for now the bus is just for
  // instructions.
  
  assign ins_adr_o = pc[0];
  assign ins_sel_o = 4'hf;
  assign ins_we_o = 1'h0;
  assign exception = 4'h0;
  assign halt = 1'h0;
  assign supervisor = 1'h0;
  
  // since we only have part of the path defined
  
  ifetch fetch0(.clk_i(clk_i), .rst_i(rst_i),
		.ir(ir[0]),
		.pc(pc[0]),
		.bus_cyc(ins_cyc_o),
		.bus_ack(ins_ack_i),
		.bus_in(ins_dat_i),
		.pc_set(pc_set),
		.stall_i(1'b0),
		.stall_o(if_stall),
		.pc_in(pc[4]));
  
  idecode decode0(.clk_i(clk_i), .rst_i(rst_i),
		  .ir_i(ir[0]),
		  .ir_o(ir[1]),
		  .stall_i(if_stall),
		  .stall_o(id_stall),
		  .pc_i(pc[0]),
		  .pc_o(pc[1]),
		  .reg_data_in(result[2]),
		  .reg_write_addr(reg_write_addr),
		  .reg_write(reg_write[1]),
		  .reg_data_out1(reg_data_out1[0]),
		  .reg_data_out2(reg_data_out2));
  
  execute exe0(.clk_i(clk_i), .rst_i(rst_i),
	       .reg_data1_i(reg_data_out1[0]),
	       .reg_data2(reg_data_out2),
	       .result(result[0]),
	       .reg_write(reg_write[0]),
	       .reg_data1_o(reg_data_out1[1]),
	       .stall_i(id_stall),
	       .stall_o(exec_stall),
	       .pc_i(pc[1]),
	       .pc_o(pc[2]),
	       .ir_i(ir[1]),
	       .ir_o(ir[2]),
	       .ccr_o(ccr[0]));
  mem mem0(.clk_i(clk_i), .rst_i(rst_i),
	   .reg_data1_i(reg_data_out1[1]),
	   .reg_write_o(reg_write[1]),
	   .reg_write_i(reg_write[0]),
	   .result_i(result[0]),
	   .result_o(result[1]),
	   .stall_i(exec_stall),
	   .stall_o(mem_stall),
	   .ir_i(ir[2]),
	   .ir_o(ir[3]),
	   .pc_i(pc[2]),
	   .pc_o(pc[3]),
	   .ccr_i(ccr[0]),
	   .ccr_o(ccr[1]),
	   .bus_adr(dat_adr_o),
	   .bus_cyc(dat_cyc_o),
	   .bus_ack(dat_ack_i),
	   .bus_in(dat_dat_i),
	   .bus_we(dat_we_o),
	   .bus_out(dat_dat_o),
	   .bus_sel(dat_sel_o));
  wb wb0(.clk_i(clk_i), .rst_i(rst_i),
	 .ir_i(ir[3]),
	 .pc_set(pc_set),
	 .ccr_i(ccr[1]),
	 .result_o(result[2]),
	 .result_i(result[1]),
	 .pc_o(pc[4]),
	 .pc_i(pc[3]),
	 .stall_i(mem_stall),
	 .stall_o(wb_stall),
	 .reg_write_addr(reg_write_addr),
	 .reg_write_i(reg_write[1]),
	 .reg_write_o(reg_write[2]));
  
endmodule // bexkat1p
