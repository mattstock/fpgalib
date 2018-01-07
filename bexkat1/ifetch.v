`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "../wb.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module ifetch(input               clk_i,
	      input 		  rst_i,
	      output [63:0] 	  ir,
	      output logic [31:0] pc,
				  if_wb.master bus,
	      input 		  pc_set,
	      input 		  halt,
	      input 		  stall_i,
	      input [31:0] 	  pc_in);
  
  logic [63:0] 			  ir_next, ir_real;
  logic [31:0] 			  pc_next, low_next, low;
  logic [31:0] 			  bus_adr_next, val;
  logic 			  full, empty;

  typedef enum bit [1:0] { S_RESET, S_FETCH, S_FETCH2, S_HALT } state_t;
  
  state_t 			  state, state_next;
  
  logic [31:0] dat_i, dat_o;
  
`ifdef NO_MODPORT_EXPRESSIONS
  assign dat_i = bus.dat_s;
  assign bus.dat_m = dat_o;
`else
  assign dat_i = bus.dat_i;
  assign bus.dat_o = dat_o;
`endif

  assign bus.cyc = ((state == S_FETCH || state == S_FETCH2) && !pc_set);
  assign bus.stb = bus.cyc;
  assign bus.sel = 4'hf;
  assign bus.we = 1'b0;
  assign dat_o = 32'h0;
  
  fifo #(.AWIDTH(4), .DWIDTH(32)) ffifo(.clk_i(clk_i), .rst_i(rst_i|pc_set),
					.push(bus.ack), .in(dat_i),
					.pop(!(bus.stall|stall_i)), .out(val),
					.full(full), .empty(empty));
  
  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	pc <= 32'hfffffffc;
	ir <= 64'h0;
	low <= 32'h0;
	bus.adr <= 32'hfffffffc;
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

  always_comb
    begin
      ir_next = ir;
      pc_next = pc;
      low_next = low;
      state_next = state;
      bus_adr_next = bus.adr;
       
      case (state)
	S_RESET:
	  state_next = S_FETCH;
	S_HALT:
	  state_next = S_HALT;
	S_FETCH:
	  begin
	    if (!bus.stall)
	      bus_adr_next = bus.adr + 32'h4;
	    if (pc_set)
	      begin
		pc_next = pc_in;
		bus_adr_next = pc_in;
		state_next = S_RESET;
	      end
	    if (!stall_i)
	      if (empty || pc_set)
		ir_next = 64'h0;
	      else
		begin
		  pc_next = pc + 32'h4;
       		  if (val[0])
		    begin
		      ir_next = 64'h0;
		      low_next = val;
		      state_next = S_FETCH2;
		    end
		  else
		    ir_next = { 32'h0, val };
		end // else: !if(empty || pc_set)
	    if (halt)
	      state_next = S_HALT;
	  end
	S_FETCH2:
	  begin
	    if (!bus.stall)
	      bus_adr_next = bus.adr + 32'h4;
	    if (pc_set)
	      begin
		pc_next = pc_in;
		bus_adr_next = pc_in;
		state_next = S_RESET;
	      end
	    if (!stall_i)
	      if (empty || pc_set)
		ir_next = 64'h0;
	      else
		begin
		  pc_next = pc + 32'h4;
		  ir_next = { val, low };
		  state_next = S_FETCH;
		end
	    if (halt)
	      state_next = S_HALT;
	  end
      endcase // case (state)
    end // always_comb
  
endmodule // ifetch
