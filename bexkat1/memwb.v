`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module memwb(input               clk_i,
	     input 		 rst_i,
	     input 		 stall_i,
	     input 		 halt_i,
	     output 		 halt_o,
	     input [1:0] 	 reg_write_i,
	     output logic [1:0]  reg_write_o,
	     input [31:0] 	 sp_data_i,
	     output logic [31:0] sp_data_o,
	     input [63:0] 	 ir_i,
	     output logic [63:0] ir_o,
	     output logic [3:0]  reg_write_addr,
	     input [3:0] 	 bank_i,
	     output logic [3:0]  bank_o);

  logic [31:0] 		       sp_data_next;
  logic [1:0] 		       reg_write_next;
  logic [3:0] 		       reg_write_addr_next;
  logic 		       halt_next;
  logic [63:0] 		       ir_next;
  logic [3:0] 		       bank_next;

  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  reg_write_o <= 2'h0;
	  halt_o <= 1'h0;
	  sp_data_o <= 32'h0;
	  reg_write_addr <= 4'h0;
	  ir_o <= 64'h0;
	  bank_o <= 4'h0;
	end
      else
	begin
	  reg_write_o <= reg_write_next;
	  halt_o <= halt_next;
	  sp_data_o <= sp_data_next;
	  reg_write_addr <= reg_write_addr_next;
	  ir_o <= ir_next;
	  bank_o <= bank_next;
	end // else: !if(rst_i)
    end // always_ff @
  
  // register write back
  always_comb
    begin
      if (stall_i)
	begin
	  halt_next = halt_o;
	  reg_write_next = reg_write_o;
	  bank_next = bank_o;
	  sp_data_next = sp_data_o;
	  reg_write_addr_next = reg_write_addr;
	  ir_next = ir_o;
	end // if (stall_i)
      else
	begin
	  halt_next = halt_i;
	  reg_write_next = reg_write_i;
	  sp_data_next = sp_data_i;
	  bank_next = bank_i;
	  reg_write_addr_next = ir_i[23:20];
	  ir_next = ir_i;
	end // else: !if(stall_i)
    end // always_comb
  
endmodule // ifetch
