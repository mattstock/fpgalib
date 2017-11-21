`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module execute(input               clk_i,
	       input 		   rst_i,
	       input [63:0] 	   ir_i,
	       input [31:0] 	   pc_i,
	       input [31:0] 	   reg_data1_i,
	       input [31:0] 	   reg_data2,
	       output logic [31:0] result,
	       output logic [31:0] reg_data1_o,
	       output logic [1:0]  reg_write,
	       output logic [2:0]  ccr_o,
	       input 		   stall_i,
	       output 		   stall_o,
	       output [63:0] 	   ir_o,
	       output [31:0] 	   pc_o);

  wire [31:0] 			   ir_extaddr = ir_i[63:32];
  wire [31:0] 			   ir_extval = ir_i[63:32];
  wire [3:0] 			   ir_type  = ir_i[31:28];
  wire [3:0] 			   ir_op    = ir_i[27:24];
  wire [3:0] 			   ir_ra    = ir_i[23:20];
  wire [31:0] 			   ir_sval = {{17{ir_i[15]}}, ir_i[15:1]};
  wire [31:0] 			   ir_uval  = {17'h0, ir_i[15:1]};
  wire 				   ir_size = ir_i[0];
  
  wire [2:0] 			   alu_func;
  
  logic [31:0] 			   alu_in1, alu_in2, alu_out;
  logic [2:0] 			   ccr_next;
  /* verilator lint_off UNOPTFLAT */
  logic 			   alu_c, alu_n, alu_v, alu_z;
  /* verilator lint_on UNOPTFLAT */
  logic [31:0] 			   pc_next, reg_data1_next;
  logic [63:0] 			   ir_next;
  logic [31:0] 			   result_next;
  logic [1:0] 			   reg_write_next;
  
  assign stall_o = stall_i;
  
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  ir_o <= 64'h0;
	  pc_o <= 32'h0;
	  reg_data1_o <= 32'h0;
	  ccr_o <= 3'h0;
	  result <= 32'h0;
	  reg_write <= 2'h0;
	end
      else
	begin
	  ir_o <= ir_next;
	  pc_o <= pc_next;
	  reg_data1_o <= reg_data1_next;
	  ccr_o <= ccr_next;
	  result <= result_next;
	  reg_write <= reg_write_next;
	end // else: !if(rst_i)
    end // always_ff @

  always_comb
    begin
      ccr_next = ccr_o;
      if (ir_type == T_CMP && !stall_i)
	ccr_next = { alu_c, alu_n ^ alu_v, alu_z };
    end

  always_comb
    begin
      if (stall_i)
	result_next = result;
      else
	begin
	  case (ir_type)
	    T_LOAD:
	      if (ir_size)
		result_next = ir_extaddr;
	    T_LDI:
	      if (ir_size)
		result_next = ir_extval;
	      else
		result_next = ir_uval;
	    T_STORE:
	      if (ir_size)
		result_next = ir_extaddr;
	    T_JUMP:
	      if (ir_size)
		result_next = ir_extaddr;
	    T_MOV:
	      result_next = reg_data1_i;
	    default:
	      result_next = alu_out;
	  endcase // case (ir_type)
	end
    end
  
  always_comb
    begin
      alu_in1 = reg_data1_i;
      alu_in2 = reg_data2;
      alu_func = alufunc_t'(ir_op[2:0]);
      
      if (stall_i)
	begin
	  pc_next = pc_o;
	  ir_next = ir_o;
	  reg_data1_next = reg_data1_o;
	  reg_write_next = reg_write;
	end
      else
	begin
	  pc_next = pc_i;
	  ir_next = ir_i;
	  reg_data1_next = reg_data1_i;
	  reg_write_next = 2'h0;
	  case (ir_type)
	    T_CMP:
	      begin
		alu_func = ALU_SUB;
	      end
	    T_LOAD:
	      begin
		alu_func = ALU_ADD;
		if (!ir_size)
		  alu_in2 = {ir_sval[29:0], 2'b00};
	      end
	    T_LDI:
	      begin
		reg_write_next = 2'h3;
	      end
	    T_STORE:
	      begin
		alu_func = ALU_ADD;
		if (!ir_size)
		  alu_in2 = {ir_sval[29:0], 2'b00};
	      end
	    T_BRANCH:
	      begin
		alu_in1 = pc_i;
		alu_in2 = {ir_sval[29:0], 2'b00};
		alu_func = ALU_ADD;
	      end
	    T_JUMP:
	      begin
		alu_func = ALU_ADD;
		if (!ir_size)
		  alu_in2 = {ir_sval[29:0], 2'b00};
	      end
	    T_MOV:
	      begin
		reg_write_next = ir_op[1:0];
	      end
	    T_ALU: 
	      begin
		if (ir_op[3]) alu_in2 = ir_sval;
		reg_write_next = 2'h3;
	      end
	    default: begin end
	  endcase // case (ir_type)
	end // else: !if(stall_i)
    end // always_comb
  
  alu_comb alu0(.in1(alu_in1),
		.in2(alu_in2),
		.func(alu_func),
		.out(alu_out),
		.c_out(alu_c),
		.z_out(alu_z),
		.n_out(alu_n),
		.v_out(alu_v));
   
endmodule // ifetch
