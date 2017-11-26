`timescale 1ns / 1ns
`include "bexkat1.vh"

import bexkat1Def::*;

module intcalc
  #(WIDTH=32)
  (input intfunc_t          func,
   input [WIDTH-1:0] 	    uin1,
   input [WIDTH-1:0] 	    uin2,
   input signed [WIDTH-1:0] sin1,
   input signed [WIDTH-1:0] sin2,
   output logic [WIDTH-1:0] out);
  
  logic signed [WIDTH-1:0]  divq, divr;
  logic [WIDTH-1:0] 	    divuq, divur;
  logic signed [2*WIDTH-1:0] mul_out;
  logic [2*WIDTH-1:0] 	     mulu_out;
  
  assign mul_out = sin1 * sin2;
  assign mulu_out = uin1 * uin2;
  assign divq = sin1 / sin2;
  assign divr = sin1 % sin2;
  assign divuq = uin1 / uin2;
  assign divur = uin1 % uin2;
  
  always_comb
    begin
      case (func)
	INT_MUL:
	  out = mul_out[WIDTH-1:0];
	INT_DIV:
	  out = divq;
	INT_MOD:
	  out = divr;
	INT_MULU:
	  out = mulu_out[WIDTH-1:0];
	INT_DIVU:
	  out = divuq;
	INT_MODU:
	  out = divur;
	INT_MULX:
	  out = mul_out[2*WIDTH-1:WIDTH];
	INT_MULUX:
	  out = mulu_out[2*WIDTH-1:WIDTH];
	INT_EXT:
	  out = { {16{sin2[15]}}, sin2[15:0] };
	INT_EXTB:
	  out = { {24{sin2[7]}}, sin2[7:0] };
	INT_COM:
	  out = ~uin2;
	INT_NEG:
	  out = -uin2;
	default:
	  out = 'h0;
      endcase
    end
   
endmodule
