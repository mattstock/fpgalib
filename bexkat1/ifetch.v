`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module ifetch(input               clk_i,
	      input 		  rst_i,
	      output [63:0] 	  ir,
	      output logic [31:0] pc,
	      input 		  bus_stall_i,
	      output logic 	  bus_cyc,
	      output logic [31:0] bus_adr,
	      input 		  bus_ack,
	      input [31:0] 	  bus_in,
	      input 		  pc_set,
	      input 		  stall_i,
	      input [31:0] 	  pc_in);
  
  logic [63:0] 			  ir_next, ir_real;
  logic [31:0] 			  pc_next, low_next, low;
  logic [31:0] 			  bus_adr_next, val;
  logic 			  full, empty;
  logic 			  state, state_next;

  assign bus_cyc = ~pc_set;

  fifo #(.AWIDTH(4), .DWIDTH(32)) fifo0(.clk_i(clk_i), .rst_i(rst_i|pc_set),
					.push(bus_ack), .in(bus_in),
					.pop(!stall_i), .out(val),
					.full(full), .empty(empty));
  
  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	pc <= 32'h0;
	ir <= 64'h0;
	low <= 32'h0;
	bus_adr <= 32'h0;
	state <= 1'h0;
      end
    else
      begin
	pc <= pc_next;
	ir <= ir_next;
	low <= low_next;
	bus_adr <= bus_adr_next;
	state <= state_next;
      end

  // fill the instruction fifo from the bus
  always_comb
    begin
      bus_adr_next = bus_adr;
      if (!bus_stall_i)
	bus_adr_next = (pc_set ? pc_in : bus_adr + 32'h4);
    end

  always_comb
    begin
      ir_next = ir;
      pc_next = pc;
      low_next = low;
      state_next = state;
      if (pc_set)
	pc_next = pc_in;
      if (stall_i || empty || pc_set)
	ir_next = 64'h0;
      else
	begin
	  pc_next = pc + 32'h4;
	  if (state == 1'b0)
	    if (val[0])
	      begin
		ir_next = 64'h0;
		low_next = val;
		state_next = 1'h1;
	      end
	    else
	      ir_next = { 32'h0, val };
	  else
	    begin
	      ir_next = { val, low };
	      state_next = 1'h0;
	    end // else: !if(val[0])
	end // else: !if(stall_i || empty)
    end // always_comb
  
endmodule // ifetch
