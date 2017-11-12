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
	       output [63:0] 	   ir_o,
	       output [31:0] 	   pc_o);

   wire [31:0] 			   ir_extaddr = ir_i[63:32];
   wire [31:0] 			   ir_extval = ir_i[63:32];
   wire [3:0] 			   ir_type  = ir_i[31:28];
   wire [3:0] 			   ir_op    = ir_i[27:24];
   wire [3:0] 			   ir_ra    = ir_i[23:20];
   wire [31:0] 			   ir_sval = {{17{ir_i[15]}}, ir_i[15:1]};
   wire [31:0] 			   ir_uval  = {17'h0, ir_i[15:1]};
   wire 			   ir_size = ir_i[0];
   
   wire [2:0] 			   alu_func;

   logic [31:0] 		   alu_in1, alu_in2, alu_out;
   logic [2:0] 			   ccr_next;
   /* verilator lint_off UNOPTFLAT */
   logic 			   alu_c, alu_n, alu_v, alu_z;
   /* verilator lint_on UNOPTFLAT */
   logic [31:0] 		   pc_next, reg_data1_next;

   always_ff @(posedge clk_i or posedge rst_i)
     begin
	if (rst_i)
	  begin
	     ir_o <= 64'h0;
	     pc_o <= 32'h0;
	     reg_data1_o <= 32'h0;
	     ccr_o <= 3'h0;
	  end
	else
	  begin
	     ir_o <= ir_i;
	     pc_o <= pc_next;
	     reg_data1_o <= reg_data1_next;
	     ccr_o <= ccr_next;
	  end // else: !if(rst_i)
     end // always_ff @

   always_comb
     begin
	pc_next = pc_i;
	reg_data1_next = reg_data1_i;
	alu_in1 = reg_data1_i;
	alu_in2 = reg_data2;
	alu_func = alufunc_t'(ir_op[2:0]);
	case (ir_type)
	  T_LOAD:
	    begin
	       alu_func = ALU_ADD;
	       if (ir_size)
		 result = ir_extaddr;
	       else
		 alu_in2 = {ir_sval[29:0], 2'b00};
	    end
	  T_STORE:
	    begin
	       alu_func = ALU_ADD;
	       if (ir_size)
		 result = ir_extaddr;
	       else
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
	       if (ir_size)
		 result = ir_extaddr;
	       else
		 alu_in2 = {ir_sval[29:0], 2'b00};
	    end
	  T_CMP: alu_func = ALU_SUB;
	  T_ALU: if (ir_op[3]) alu_in2 = ir_sval;
	  default: begin end
	endcase // case (ir_type)
     end // always_comb
   
   always_comb
     begin
	reg_write = 2'h0;
	result = alu_out;
	ccr_next = ccr_o;
	result = alu_out;
	case (ir_type)
	  T_LDI:
	    if (ir_size)
	      result = ir_extval;
	    else
	      result = ir_uval;
	  T_CMP: ccr_next = { alu_c, alu_n ^ alu_v, alu_z };
	  T_MOV:
	    begin
	       result = reg_data1_i;
	       reg_write = ir_op[1:0];
	    end
	  T_ALU:
	    begin
	       reg_write = 2'h3;
	    end
	  default: begin end
	endcase // case (ir_type)
     end

   alu_comb alu0(.in1(alu_in1),
		 .in2(alu_in2),
		 .func(alu_func),
		 .out(alu_out),
		 .c_out(alu_c),
		 .z_out(alu_z),
		 .n_out(alu_n),
		 .v_out(alu_v));
   
endmodule // ifetch
