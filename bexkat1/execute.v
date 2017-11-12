`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module execute(input               clk_i,
	       input 		   rst_i,
	       input [63:0] 	   ir_i,
	       input [31:0] 	   pc_i,
	       input [31:0] 	   reg_data1,
	       input [31:0] 	   reg_data2,
	       output logic [31:0] result,
	       output logic [1:0]  reg_write,
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
   wire 			   ccr_ltu = ccr[2];
   wire 			   ccr_lt = ccr[1];
   wire 			   ccr_eq = ccr[0];

   logic [31:0] 			   alu_in1, alu_in2, alu_out;
   logic [2:0] 				   ccr, ccr_next;
   logic 				   alu_c, alu_n, alu_v, alu_z;
   logic [31:0] 			   pc_next;

   always_ff @(posedge clk_i or posedge rst_i)
     begin
	if (rst_i)
	  begin
	     ir_o <= 64'h0;
	     pc_o <= 32'h0;
	     ccr <= 3'h0;
	  end
	else
	  begin
	     ir_o <= ir_i;
	     pc_o <= pc_next;
	     ccr <= ccr_next;
	  end // else: !if(rst_i)
     end // always_ff @
   
   always_comb
     begin
	reg_write = 2'h0;
	result = alu_out;
	pc_next = pc_i;
	alu_func = alufunc_t'(ir_op[2:0]);
	alu_in1 = reg_data1;
	alu_in2 = reg_data2;
	ccr_next = ccr;
	result = alu_out;
	case (ir_type)
	  T_LDI:
	    if (ir_size)
	      result = ir_extval;
	    else
	      result = ir_uval;
	  T_LOAD:
	    if (ir_size)
	      result = ir_extaddr;
	    else
	      begin
		 alu_func = ALU_ADD;
		 alu_in2 = {ir_sval[29:0], 2'b00};
	      end
	  T_STORE:
	    if (ir_size)
	      result = ir_extaddr;
	    else
	      begin
		 alu_func = ALU_ADD;
		 alu_in2 = {ir_sval[29:0], 2'b00};
	      end
	  T_JUMP:
	    if (ir_size)
	      result = ir_extaddr;
	    else
	      begin
		 alu_func = ALU_ADD;
		 alu_in2 = {ir_sval[29:0], 2'b00};
	      end
	  T_CMP:
	    begin
	       alu_func = ALU_SUB;
	       ccr_next = { alu_c, alu_n ^ alu_v, alu_z };
	    end
	  T_MOV:
	    begin
	       result = reg_data1;
	       reg_write = ir_op[1:0];
	    end
	  T_ALU:
	    begin
	       if (ir_op[3]) alu_in2 = ir_sval;
	       reg_write = 2'h3;
	    end
	  T_BRANCH:
	    begin
	       alu_func = ALU_ADD;
	       alu_in1 = pc_i;
	       alu_in2 = {ir_sval[29:0], 2'b00};
	       case (ir_op)
		 4'h0: pc_next = alu_out; // bra
		 4'h1: if (ccr_eq) pc_next = alu_out;  // beq
		 4'h2: if (~ccr_eq) pc_next = alu_out; // bne
		 4'h3: if (~(ccr_ltu | ccr_eq)) pc_next = alu_out; // bgtu
		 4'h4: if (~(ccr_lt | ccr_eq)) pc_next = alu_out; // bgt
		 4'h5: if (~ccr_lt) pc_next = alu_out; // bge
		 4'h6: if (ccr_lt | ccr_eq) pc_next = alu_out; // ble
		 4'h7: if (ccr_lt) pc_next = alu_out; // blt
		 4'h8: if (~ccr_ltu) pc_next = alu_out; // bgeu
		 4'h9: if (ccr_ltu) pc_next = alu_out; // bltu
		 4'ha: if (ccr_ltu | ccr_eq) pc_next = alu_out; // bleu
		 default: begin end
	       endcase // case (ir_op)
	    end // case: T_BRANCH
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
