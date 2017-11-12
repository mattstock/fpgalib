// A simple ALU design
// Matt Stock 11/16/14

`include "bexkat1.vh"
import bexkat1Def::*;

module alu_comb
  #(WIDTH=32)
   (input [WIDTH-1:0] 	     in1,
    input [WIDTH-1:0] 	     in2,
    input 		     alufunc_t func,
    output logic [WIDTH-1:0] out,
    output logic 	     c_out,
    output logic 	     z_out,
    output logic 	     n_out,
    output logic 	     v_out);
   
   assign n_out = out[WIDTH-1];
   assign z_out = ~|out;
   
   always_comb
     begin
	case (func)
	  ALU_AND:
	    begin
	       out = in1 & in2;
	       v_out = 1'b0;
	       c_out = 1'b0;
	    end  
	  ALU_OR:
	    begin
	       out = in1 | in2;
	       v_out = 1'b0;
	       c_out = 1'b0;
	    end
	  ALU_XOR:
	    begin
	       out = in1 ^ in2;
	       v_out = 1'b0;
	       c_out = 1'b0;
	    end
	  ALU_ADD:
	    begin
	       out = in1 + in2;
	       v_out = (in1[WIDTH-1] & in2[WIDTH-1] & ~out[WIDTH-1]) |
		       (~in1[WIDTH-1] & ~in2[WIDTH-1] & out[WIDTH-1]);
	       c_out = (in1[WIDTH-1] & in2[WIDTH-1]) | 
		       (in2[WIDTH-1] & out[WIDTH-1]) | 
		       (out[WIDTH-1] & in1[WIDTH-1]);
	    end  
	  ALU_SUB:
	    begin
	       out = in1 - in2;
	       v_out = (in1[WIDTH-1] & ~in2[WIDTH-1] & ~out[WIDTH-1]) |
		       (~in1[WIDTH-1] & in2[WIDTH-1] & out[WIDTH-1]);
	       c_out = ~in1[WIDTH-1] & in2[WIDTH-1] | 
		       in2[WIDTH-1] & out[WIDTH-1] |
		       out[WIDTH-1] & ~in1[WIDTH-1];
	    end  
	  ALU_LSHIFT:
	    begin
	       {c_out, out} = {1'b0, in1} << in2;
	       v_out = n_out ^ c_out;
	    end
	  ALU_RSHIFTA:
	    begin
	       out = $signed(in1) >>> in2;
	       c_out = 1'b0;
	       v_out = n_out;
	    end
	  ALU_RSHIFTL:
	    begin
	       out = in1 >> in2;
	       c_out = 1'b0;
	       v_out = n_out;
	    end
	endcase // case (func)
     end
endmodule
