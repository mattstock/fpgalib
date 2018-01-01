`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module ifetch(input               clk_i,
	      input 		  rst_i,
	      output [63:0] 	  ir,
	      output logic [31:0] pc,
	      wb_bus              bus,
	      input 		  pc_set,
	      input 		  stall_i,
	      input [31:0] 	  pc_in);
  
  logic [63:0] 			  ir_next, ir_real;
  logic [31:0] 			  pc_next, low_next, low;
  logic [31:0] 			  bus_adr_next, val;
  logic 			  full, empty;

  typedef enum bit [1:0] { S_RESET, S_FETCH, S_FETCH2 } state_t;
  
  state_t 			  state, state_next;

  assign bus.cyc = (state != S_RESET && !pc_set);
  assign bus.stb = bus.cyc;

  fifo #(.AWIDTH(4), .DWIDTH(32)) fifo0(.clk_i(clk_i), .rst_i(rst_i|pc_set),
					.push(bus.ack), .in(bus.dat_i),
					.pop(!bus.stall), .out(val),
					.full(full), .empty(empty));
  
  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	pc <= 32'h0;
	ir <= 64'h0;
	low <= 32'h0;
	bus.adr <= 32'h0;
	state <= S_RESET;
      end
    else
      begin
	pc <= pc_next;
	ir <= ir_next;
	low <= low_next;
	bus.adr <= bus_adr_next;
	state <= state_next;
      end

  // fill the instruction fifo from the bus
  always_comb
    begin
      bus_adr_next = bus.adr;
      if (!bus.stall && (state != S_RESET))
	bus_adr_next = (pc_set ? pc_in : bus.adr + 32'h4);
    end

  always_comb
    begin
      ir_next = ir;
      pc_next = pc;
      low_next = low;
      state_next = state;
      if (state == S_RESET)
	state_next = S_FETCH;
      if (pc_set)
	begin
	  pc_next = pc_in;
	  state_next = S_RESET;
	end
      if (!stall_i)
	if (empty || pc_set)
	  ir_next = 64'h0;
	else
	  begin
	    pc_next = pc + 32'h4;
	    case (state)
	      S_FETCH:
		if (val[0])
		  begin
		    ir_next = 64'h0;
		    low_next = val;
		    state_next = S_FETCH2;
		  end
		else
		  ir_next = { 32'h0, val };
	      S_FETCH2:
		begin
		  ir_next = { val, low };
		  state_next = S_FETCH;
		end // else: !if(val[0])
	      default:
		state_next = S_FETCH;
	    endcase // case (state)
	  end // else: !if(empty || pc_set)
    end // always_comb
  
endmodule // ifetch
