`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module ifetch(input               clk_i,
	      input 		  rst_i,
	      output logic [63:0] ir,
	      output logic [31:0] pc,
	      output logic 	  bus_cyc,
	      input 		  bus_ack,
	      input [31:0] 	  bus_in,
	      input 		  pc_set,
	      input 		  stall_i,
	      output 		  stall_o,
	      input [31:0] 	  pc_in);
  
  logic [63:0] 			  ir_next;
  logic [31:0] 			  pc_next;
  
  typedef enum 			  bit { S_BUSWAIT, 
					S_BUSWAIT2 } state_t;
  state_t 			  state, state_next;
  
  assign bus_cyc = (state == S_BUSWAIT || state == S_BUSWAIT2);
  assign stall_o = (state == S_BUSWAIT2);
  
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  state <= S_BUSWAIT;
	  ir <= 64'h0;
	  pc <= 32'h0;
	end
      else
	begin
	  state <= state_next;
	  ir <= ir_next;
	  pc <= pc_next;
	end // else: !if(rst_i)
    end // always_ff @
  
  always_comb
    begin
      state_next = state;
      ir_next = ir;
      pc_next = pc;

      if (!stall_i)
	case (state)
	  S_BUSWAIT:
	    begin
	      ir_next = { 32'h0, bus_in };
	      if (bus_ack)
		if (bus_in[0])
		  begin
		    state_next = S_BUSWAIT2;
		    pc_next = pc + 'h4;
		  end
		else
		  begin
		    if (pc_set)
		      pc_next = pc_in; // from another stage
		    else
		      pc_next = pc + 'h4;
		  end // else: !if(bus_in[0])
	    end
	  S_BUSWAIT2:
	    begin
	      ir_next[63:32] = bus_in;
	      if (bus_ack)
		begin
		  state_next = S_BUSWAIT;
		  if (pc_set)
		    pc_next = pc_in; // from another stage
		  else
		    pc_next = pc + 'h4;
		end
	    end
	endcase // case (state)
    end
  
endmodule // ifetch
