// A simple ALU design
// Matt Stock 11/16/14

`include "bexkat1.vh"
import bexkat1Def::alu_t;

module alu
  #(WIDTH=32)
  (input 		    clk_i,
   input 		    rst_i,
   input [WIDTH-1:0] 	    in1,
   input [WIDTH-1:0] 	    in2,
   input alu_t 		    func,
   output logic [WIDTH-1:0] out,
   output logic 	    c_out,
   output 		    z_out,
   output 		    n_out,
   output logic 	    v_out);
  
  assign n_out = out[WIDTH-1];
  assign z_out = ~|out;
  
  logic [WIDTH-1:0] 		    out_next;
  
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  out <= 32'h0;
	end
      else
	begin
	  out <= out_next;
	end
    end
  
  always_comb
    begin
      out_next = out;
      case (func)
	bexkat1Def::ALU_AND: begin
	  out_next = in1 & in2;
	  v_out = 1'b0;
	  c_out = 1'b0;
	end  
	bexkat1Def::ALU_OR: begin
	  out_next = in1 | in2;
	  v_out = 1'b0;
	  c_out = 1'b0;
	end
	bexkat1Def::ALU_XOR: begin
	  out_next = in1 ^ in2;
	  v_out = 1'b0;
	  c_out = 1'b0;
	end
	bexkat1Def::ALU_ADD: begin
	  out_next = in1 + in2;
	  v_out = (in1[WIDTH-1] & in2[WIDTH-1] & ~out[WIDTH-1]) |
		  (~in1[WIDTH-1] & ~in2[WIDTH-1] & out[WIDTH-1]);
	  c_out = (in1[WIDTH-1] & in2[WIDTH-1]) | 
		  (in2[WIDTH-1] & out[WIDTH-1]) | 
		  (out[WIDTH-1] & in1[WIDTH-1]);
	end  
	bexkat1Def::ALU_SUB: begin
	  out_next = in1 - in2;
	  v_out = (in1[WIDTH-1] & ~in2[WIDTH-1] & ~out[WIDTH-1]) |
		  (~in1[WIDTH-1] & in2[WIDTH-1] & out[WIDTH-1]);
	  c_out = ~in1[WIDTH-1] & in2[WIDTH-1] | 
		  in2[WIDTH-1] & out[WIDTH-1] |
		  out[WIDTH-1] & ~in1[WIDTH-1];
	end  
	bexkat1Def::ALU_LSHIFT: begin
	  {c_out, out_next} = {1'b0, in1} << in2;
	  v_out = n_out ^ c_out;
	end
	bexkat1Def::ALU_RSHIFTA: begin
	  out_next = $signed(in1) >>> in2;
	  c_out = 1'b0;
	  v_out = n_out;
	end
	bexkat1Def::ALU_RSHIFTL: begin
	  out_next = in1 >> in2;
	  c_out = 1'b0;
	  v_out = n_out;
	end
      endcase
    end
endmodule
