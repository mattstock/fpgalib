`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module wb(input               clk_i,
	  input 	      rst_i,
	  input [63:0] 	      ir_i,
	  input [31:0] 	      pc_i,
	  input [2:0] 	      ccr_i,
	  input [1:0] 	      reg_write_i,
	  input [31:0] 	      result_i,
	  output logic [31:0] result_o,
	  output logic [1:0]  reg_write_o,
	  output logic [31:0] pc_o,
	  output logic [3:0]  reg_write_addr);

   wire [3:0] 		      ir_type  = ir_i[31:28];
   wire [3:0] 		      ir_op    = ir_i[27:24];
   wire [3:0] 		      ir_ra = ir_i[23:20];
   wire 		      ir_size = ir_i[0];
   
   wire 		      ccr_ltu = ccr_i[2];
   wire 		      ccr_lt = ccr_i[1];
   wire 		      ccr_eq = ccr_i[0];
   
   logic [31:0] 	      pc_next, result_next;
   logic [1:0] 		      reg_write_next;
   
   assign reg_write_addr = ir_ra;
   
   always_ff @(posedge clk_i or posedge rst_i)
     begin
	if (rst_i)
	  begin
	     pc_o <= 32'h0;
	     reg_write_o <= 2'h0;
	     result_o <= 32'h0;
	  end
	else
	  begin
	     pc_o <= pc_next;
	     reg_write_o <= reg_write_next;
	     result_o <= result_next;
	  end // else: !if(rst_i)
     end // always_ff @

   always_comb
     begin
	pc_next = pc_i;
	result_next = result_i;
	reg_write_next = reg_write_i;

	case (ir_type)
	  T_BRANCH:
	    begin
	       case (ir_op)
		 4'h0: pc_next = result_i; // bra
		 4'h1: if (ccr_eq) pc_next = result_i;  // beq
		 4'h2: if (~ccr_eq) pc_next = result_i; // bne
		 4'h3: if (~(ccr_ltu | ccr_eq)) pc_next = result_i; // bgtu
		 4'h4: if (~(ccr_lt | ccr_eq)) pc_next = result_i; // bgt
		 4'h5: if (~ccr_lt) pc_next = result_i; // bge
		 4'h6: if (ccr_lt | ccr_eq) pc_next = result_i; // ble
		 4'h7: if (ccr_lt) pc_next = result_i; // blt
		 4'h8: if (~ccr_ltu) pc_next = result_i; // bgeu
		 4'h9: if (ccr_ltu) pc_next = result_i; // bltu
		 4'ha: if (ccr_ltu | ccr_eq) pc_next = result_i; // bleu
		 default: begin end
	       endcase // case (ir_op)
	    end // case: T_BRANCH
	  T_JUMP: pc_next = result_i;
	  default: begin end
	endcase // case (ir_type)
     end
  
endmodule // ifetch
