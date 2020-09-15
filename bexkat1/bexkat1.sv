`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "../wb.vh"

import bexkat1Def::*;

module bexkat1(input 	     clk_i,
		input 	     rst_i,
		if_wb.master ins_bus,
		if_wb.master dat_bus,
		output 	     halt,
		input [2:0]  inter,
		output 	     int_en,
		output [3:0] exception,
		output logic supervisor);

  logic [63:0] 			    if_ir, id_ir, exe_ir, mem_ir;
  logic [31:0] 			    if_pc, id_pc, exe_pc, mem_pc;
  logic 			    exe_pc_set, mem_pc_set;
  logic [31:0] 			    exe_data1, exe_data2;
  logic [31:0] 			    id_reg_data_out1, exe_reg_data_out1;
  logic [31:0] 			    exe_sp_in, exe_result;
  logic 			    exe_halt, mem_halt;
  logic 			    exe_stall, mem_stall;
  logic 			    exe_exc, mem_exc;
  logic [31:0] 			    mem_result;
  logic [31:0] 			    id_reg_data_out2, exe_reg_data_out2;
  logic [3:0] 			    mem_reg_write_addr;
  logic [1:0] 			    id_reg_write, exe_reg_write, mem_reg_write;
  logic [1:0] 			    id_sp_write, exe_sp_write, mem_sp_write;
  logic [31:0] 			    id_sp_data, exe_sp_data, mem_sp_data;
  logic 			    hazard_stall;
  logic [2:0] 			    hazard1, hazard2;
  logic [1:0] 			    sp_hazard;
  logic [2:0] 			    exe_ccr;
  logic [3:0] 			    id_bank, exe_bank, mem_bank;
  logic 			    mem_pc_set_last;
  
  assign halt = mem_halt;  
  assign exception = 4'h0;

  always_ff @(posedge clk_i)
    mem_pc_set_last <= mem_pc_set;
  
  ifetch #(.REQ_MAX(4)) fetch0(.clk_i(clk_i), .rst_i(rst_i),
			       .ir(if_ir),
			       .pc(if_pc),
			       .halt(exe_halt|mem_halt),
			       .stall_i(hazard_stall|exe_stall|
					mem_stall),
			       .bus(ins_bus.master),
			       .pc_set(mem_pc_set),
			       .pc_in(mem_pc));

  idecode decode0(.clk_i(clk_i), .rst_i(rst_i),
		  .ir_i((hazard_stall|
			 exe_exc|
			 exe_pc_set|
			 mem_pc_set ? 64'h0 : if_ir)),
		  .ir_o(id_ir),
		  .pc_i(mem_pc_set ? mem_pc : if_pc),
		  .pc_o(id_pc),
		  .bank_i(mem_bank),
		  .bank_o(id_bank),
		  .supervisor_i(supervisor),
		  .stall_i(exe_stall|mem_stall),
		  .sp_write_i(mem_sp_write),
		  .sp_write_o(id_sp_write),
		  .sp_data_i(mem_sp_data),
		  .sp_data_o(id_sp_data),
		  .reg_data_in(mem_result),
		  .reg_write_addr(mem_reg_write_addr),
		  .reg_write_i(mem_reg_write),
		  .reg_write_o(id_reg_write),
		  .reg_data_out1(id_reg_data_out1),
		  .reg_data_out2(id_reg_data_out2));

  hazard hazard0(.clk_i(clk_i), .rst_i(rst_i),
		 .if_ir(if_ir),
		 .id_ir(id_ir),
		 .id_reg_write(id_reg_write),
		 .exe_ir(exe_ir),
		 .exe_reg_write(exe_reg_write),
		 .mem_ir(mem_ir),
		 .mem_reg_write(mem_reg_write),
		 .id_sp_write(id_sp_write),
		 .exe_sp_write(exe_sp_write),
		 .mem_sp_write(mem_sp_write),
		 .stall(hazard_stall),
		 .hazard1(hazard1),
		 .hazard2(hazard2),
		 .sp_hazard(sp_hazard));
		
  always_comb
    begin
      case (hazard1) 
	3'h0: exe_data1 = id_reg_data_out1;
	3'h1: exe_data1 = mem_result;
	3'h2: exe_data1 = exe_result;
	3'h3: exe_data1 = mem_sp_data;
	3'h4: exe_data1 = exe_sp_data;
	default: exe_data1 = id_reg_data_out1;
      endcase // case (hazard1)
      case (hazard2) 
	3'h0: exe_data2 = id_reg_data_out2;
	3'h1: exe_data2 = mem_result;
	3'h2: exe_data2 = exe_result;
	3'h3: exe_data2 = mem_sp_data;
	3'h4: exe_data2 = exe_sp_data;
	default : exe_data2 = id_reg_data_out2;
      endcase // case (hazard2)
      case (sp_hazard)
	2'h0: exe_sp_in = id_sp_data;
	2'h1: exe_sp_in = exe_sp_data;
	2'h2: exe_sp_in = mem_sp_data;
	2'h3: exe_sp_in = id_sp_data;
      endcase // case (sp_hazard)
    end // always_comb
  
  execute exe0(.clk_i(clk_i), .rst_i(rst_i),
	       .reg_data1_i(exe_data1),
	       .reg_data1_o(exe_reg_data_out1),
	       .reg_data2_i(exe_data2),
	       .reg_data2_o(exe_reg_data_out2),
	       .result(exe_result),
	       .reg_write_i((exe_exc|exe_pc_set ? 2'h0 : id_reg_write)),
	       .reg_write_o(exe_reg_write),
	       .halt_o(exe_halt),
	       .stall_i(mem_stall),
	       .stall_o(exe_stall),
	       .sp_write_i(exe_pc_set ? 2'h0 : id_sp_write),
	       .sp_write_o(exe_sp_write),
	       .sp_data_i(exe_sp_in),
	       .sp_data_o(exe_sp_data),
	       .bank_i(id_bank),
	       .bank_o(exe_bank),
	       .pc_i(mem_pc_set ? mem_pc : id_pc),
	       .pc_o(exe_pc),
	       .pc_mem_i(mem_pc),
	       .pc_set_i(mem_pc_set),
	       .pc_set_o(exe_pc_set),
	       .supervisor(supervisor),
	       .interrupts(inter),
	       .interrupts_enabled(int_en),
	       .exc_i(mem_exc),
	       .exc_o(exe_exc),
	       .ir_i((exe_exc|exe_pc_set ? 64'h0 : id_ir)),
	       .ir_o(exe_ir),
	       .ccr_o(exe_ccr));

  memwb mem1(.clk_i(clk_i), .rst_i(rst_i),
	     .stall_i(exe_stall|mem_stall),
	     .halt_i(exe_halt),
	     .halt_o(mem_halt),
	     .bank_i(exe_bank),
	     .bank_o(mem_bank),
	     .reg_write_i(exe_reg_write),
	     .reg_write_o(mem_reg_write),
	     .sp_data_i(exe_sp_data),
	     .sp_data_o(mem_sp_data),
	     .reg_write_addr(mem_reg_write_addr),
	     .ir_i((exe_halt ? 64'h0 : exe_ir)),
	     .ir_o(mem_ir));
			
  mem mem0(.clk_i(clk_i), .rst_i(rst_i),
	   .reg_data1_i(exe_reg_data_out1),
	   .reg_data2_i(exe_reg_data_out2),
	   .stall_i(exe_stall),
	   .stall_o(mem_stall),
	   .result_i(exe_result),
	   .result_o(mem_result),
	   .sp_write_i(exe_sp_write),
	   .sp_write_o(mem_sp_write),
	   .sp_data_i(exe_sp_data),
	   .pc_i(mem_pc_set ? mem_pc : exe_pc),
	   .pc_o(mem_pc),
	   .pc_set_i(exe_pc_set),
	   .pc_set_o(mem_pc_set),
	   .ir_i((exe_halt ? 64'h0 : exe_ir)),
	   .exc_i(exe_exc),
	   .exc_o(mem_exc),
	   .bus(dat_bus.master));

endmodule // bexkat1p
