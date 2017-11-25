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
	  input 	      halt_i,
	  output 	      halt_o,
	  output logic [31:0] result_o,
	  output logic [1:0]  reg_write_o,
	  output logic [31:0] pc_o,
	  input 	      pc_set_i,
	  output logic 	      pc_set_o,
	  output logic [3:0]  reg_write_addr);
  
  wire [3:0] 		      ir_type  = ir_i[31:28];
  wire [3:0] 		      ir_op    = ir_i[27:24];
  wire [3:0] 		      ir_ra = ir_i[23:20];
  wire 			      ir_size = ir_i[0];
  
  logic [31:0] 		      pc_next, result_next;
  logic [1:0] 		      reg_write_next;
  logic 		      pc_set_next;
  logic [3:0] 		      reg_write_addr_next;
  logic 		      halt_next;
  
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  pc_o <= 32'h0;
	  reg_write_o <= 2'h0;
	  result_o <= 32'h0;
	  reg_write_addr <= 4'h0;
	  pc_set_o <= 1'b0;
	  halt_o <= 1'h0;
	end
      else
	begin
	  pc_o <= pc_next;
	  reg_write_o <= reg_write_next;
	  result_o <= result_next;
	  reg_write_addr <= reg_write_addr_next;
	  pc_set_o <= pc_set_next;
	  halt_o <= halt_next;
	end // else: !if(rst_i)
    end // always_ff @
  
  always_comb
    begin
      pc_next = pc_i;
      result_next = result_i;
      reg_write_next = reg_write_i;
      reg_write_addr_next = ir_ra;
      pc_set_next = pc_set_i;
      halt_next = halt_i;
    end // always_comb
  
endmodule // ifetch
