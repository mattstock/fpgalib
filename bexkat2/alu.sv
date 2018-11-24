// A simple ALU design
// Matt Stock 11/16/14

`include "bexkat2.vh"
import bexkat1Def::*;

module alu
  #(WIDTH=32)
   (input                    clk_i,
    input 		     rst_i,
    input [WIDTH-1:0] 	     in1,
    input [WIDTH-1:0] 	     in2,
    input 		     alufunc_t func,
    output logic [WIDTH-1:0] out,
    output logic 	     c_out,
    output logic 	     z_out,
    output logic 	     n_out,
    output logic 	     v_out);

  logic [WIDTH-1:0] 	     out_next;
  logic [3:0] 		     ccr_next;
  
  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	{ c_out, z_out, n_out, v_out } <= 4'h0;
	out <= 32'h0;
      end
    else
      begin
	{ c_out, z_out, n_out, v_out } <= ccr_next;
	out <= out_next;
      end

  always_comb
    begin
      case (func)
	ALU_AND:
	  begin
	    out_next = in1 & in2;
	    ccr_next[3] = 1'b0;
	    ccr_next[2] = ~|out_next;
	    ccr_next[1] = out_next[WIDTH-1];
	    ccr_next[0] = 1'b0;
	  end  
	ALU_OR:
	  begin
	    out_next = in1 | in2;
	    ccr_next[3] = 1'b0;
	    ccr_next[2] = ~|out_next;
	    ccr_next[1] = out_next[WIDTH-1];
	    ccr_next[0] = 1'b0;
	  end
	ALU_XOR:
	  begin
	    out_next = in1 ^ in2;
	    ccr_next[3] = 1'b0;
	    ccr_next[2] = ~|out_next;
	    ccr_next[1] = out_next[WIDTH-1];
	    ccr_next[0] = 1'b0;
	  end
	ALU_ADD:
	  begin
	    out_next = in1 + in2;
	    ccr_next[3] = (in1[WIDTH-1] & in2[WIDTH-1]) | 
			  (in2[WIDTH-1] & out_next[WIDTH-1]) | 
			  (out_next[WIDTH-1] & in1[WIDTH-1]);
	    ccr_next[2] = ~|out_next;
	    ccr_next[1] = out_next[WIDTH-1];
	    ccr_next[0] = (in1[WIDTH-1] & in2[WIDTH-1] & ~out_next[WIDTH-1]) |
			  (~in1[WIDTH-1] & ~in2[WIDTH-1] & out_next[WIDTH-1]);
	  end  
	ALU_SUB:
	  begin
	    out_next = in1 - in2;
	    ccr_next[3] = ~in1[WIDTH-1] & in2[WIDTH-1] | 
			  in2[WIDTH-1] & out_next[WIDTH-1] |
			  out_next[WIDTH-1] & ~in1[WIDTH-1];
	    ccr_next[2] = ~|out_next;
	    ccr_next[1] = out_next[WIDTH-1];
	    ccr_next[0] = (in1[WIDTH-1] & ~in2[WIDTH-1] & ~out_next[WIDTH-1]) |
			  (~in1[WIDTH-1] & in2[WIDTH-1] & out_next[WIDTH-1]);
	  end  
	ALU_LSHIFT:
	  begin
	    {ccr_next[3], out_next} = {1'b0, in1} << in2;
	    ccr_next[2] = ~|out_next;
	    ccr_next[1] = out_next[WIDTH-1];
	    ccr_next[0] = ccr_next[1] ^ ccr_next[3];
	  end
	ALU_RSHIFTA:
	  begin
	    out_next = $signed(in1) >>> in2;
	    ccr_next[3] = 1'b0;
	    ccr_next[2] = ~|out_next;
	    ccr_next[1] = out_next[WIDTH-1];
	    ccr_next[0] = ccr_next[1];
	  end
	ALU_RSHIFTL:
	  begin
	    out_next = in1 >> in2;
	    ccr_next[3] = 1'b0;
	    ccr_next[2] = ~|out_next;
	    ccr_next[1] = out_next[WIDTH-1];
	    ccr_next[0] = ccr_next[1];
	  end
      endcase // case (func)
    end
endmodule
