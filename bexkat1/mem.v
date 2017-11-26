`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module mem(input               clk_i,
	   input 	       rst_i,
	   input [31:0]        reg_data1_i,
	   input 	       stall_i,
	   input 	       halt_i,
	   output 	       halt_o,
	   input [31:0]        result_i,
	   output logic [31:0] result_o,
	   input [1:0] 	       reg_write_i,
	   output logic [1:0]  reg_write_o,
	   input [63:0]        ir_i,
	   output logic [63:0] ir_o,
	   output logic [31:0] bus_adr,
	   output logic        bus_we,
	   output logic        bus_cyc,
	   input 	       bus_ack,
	   input [31:0]        bus_in,
	   output logic [31:0] bus_out,
	   output logic [3:0]  bus_sel);
  
  wire [3:0] 		       ir_type  = ir_i[31:28];
  wire [3:0] 		       ir_op    = ir_i[27:24];
  
  logic [31:0] 		       result_next;
  logic [1:0] 		       reg_write_next;
  logic [63:0] 		       ir_next;
  logic 		       halt_next;
  
  assign bus_cyc = (ir_type == T_LOAD ||
		    ir_type == T_STORE);
  assign bus_we = (ir_type == T_STORE);
  assign bus_adr = result_i;
  assign bus_out = reg_data1_i;
  
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  ir_o <= 64'h0;
	  reg_write_o <= 2'h0;
	  result_o <= 32'h0;
	  halt_o <= 1'h0;
	end
      else
	begin
	  ir_o <= ir_next;
	  reg_write_o <= reg_write_next;
	  result_o <= result_next;
	  halt_o <= halt_next;
	end // else: !if(rst_i)
    end // always_ff @
  
  always_comb
    case (ir_op[1:0])
      2'h0: bus_sel = 4'hf;
      2'h1: bus_sel = (result_i[1] ? 4'b0011 : 4'b1100);
      2'h2: case (result_i[1:0])
	      2'b00: bus_sel = 4'b1000;
	      2'b01: bus_sel = 4'b0100;
	      2'b10: bus_sel = 4'b0010;
	      2'b11: bus_sel = 4'b0001;
	    endcase // case (result_i[1:0])
      2'h3: bus_sel = 4'hf;
    endcase // case (ir_op[1:0])
  
  always_comb
    begin
      if (stall_i)
	begin
	  halt_next = halt_o;
	  ir_next = ir_o;
	  result_next = result_o;
	  reg_write_next = reg_write_o;
	end // if (stall_i)
      else
	begin
	  halt_next = halt_i;
	  ir_next = ir_i;
	  result_next = result_i;
	  reg_write_next = reg_write_i;
	  
	  if (ir_type == T_LOAD)
	    result_next = bus_in;
	end // else: !if(stall_i)
    end // always_comb
  
endmodule // ifetch
