`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module idecode(input        clk_i,
	       input 	    rst_i,
	       input [63:0] ir);

  wire 			    ir_extaddr = ir[63:32];
  wire 			    ir_extval = ir[63:32];
  wire 			    ir_type = ir[31:28];
  wire 			    ir_op = ir[27:24];
  wire 			    ir_ra = ir[23:20];
  wire 			    ir_rb = ir[19:16];
  wire 			    ir_rc = ir[15:12];
  /* verilator lint_off UNUSED */
  wire [8:0] 		    ir_nop = ir[11:3];
  /* verilator lint_on UNUSED */
  wire [1:0] 		    ir_uval = ir[2:1];
  wire 			    ir_size = ir[0];
  
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	end
      else
	begin
	end // else: !if(rst_i)
    end // always_ff @

  always_comb
    begin
    end
  
endmodule // idecode
