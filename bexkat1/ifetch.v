`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module ifetch(input               clk_i,
	      input 		  rst_i,
	      output [63:0] 	  ir,
	      output logic [31:0] pc,
	      output logic 	  bus_cyc,
	      input 		  bus_ack,
	      input [31:0] 	  bus_in,
	      input 		  pc_set,
	      input 		  stall_i,
	      input [31:0] 	  pc_in);
  
  logic [63:0] 			  ir_next, ir_real;
  logic [31:0] 			  pc_next, low_next, low;
  
  typedef enum 			  bit { S_BUSWAIT, 
					S_BUSWAIT2 } state_t;
  state_t 			  state, state_next;
  
  assign bus_cyc = (state == S_BUSWAIT || state == S_BUSWAIT2);
  
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  state <= S_BUSWAIT;
	  ir <= 64'h0;
	  pc <= 32'h0;
	  low <= 32'h0;
	end
      else
	begin
	  state <= state_next;
	  ir <= ir_next;
	  pc <= pc_next;
	  low <= low_next;
	end // else: !if(rst_i)
    end // always_ff @
  
  always_comb
    begin
      state_next = state;
      ir_next = ir;
      pc_next = pc;
      low_next = low;

      case (state)
	S_BUSWAIT:
	  begin
	    if (bus_ack && !stall_i)
	      if (bus_in[0])
		begin
		  state_next = S_BUSWAIT2;
		  ir_next = 64'h0;
		  low_next = bus_in;
		  pc_next = pc + 'h4;
		end
	      else
		begin
		  if (pc_set)
		    begin
		      ir_next = 64'h0;
		      pc_next = pc_in; // from another stage
		    end
		  else
		    begin
		      ir_next = { 32'h0, bus_in };
		      pc_next = pc + 'h4;
		    end
		end // else: !if(bus_in[0])
	  end // case: S_BUSWAIT
	S_BUSWAIT2:
	  begin
	    ir_next = { bus_in, low };
	    if (bus_ack)
	      begin
		state_next = S_BUSWAIT;
		if (pc_set)
		  pc_next = pc_in; // from another stage
		else
		  pc_next = pc + 'h4;
	      end
	  end // case: S_BUSWAIT2
      endcase // case (state)
    end
  
endmodule // ifetch
