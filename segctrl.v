`timescale 1ns / 1ns

`include "wb.vh"

module segctrl
  #(SEG=7,
    SW=10)
  (input            clk_i,
   input 	    rst_i,
   if_wb.slave      bus,
   input [SW-1:0]   sw,
   output [SEG-1:0] out0,
   output [SEG-1:0] out1,
   output [SEG-1:0] out2,
   output [SEG-1:0] out3,
   output [SEG-1:0] out4,
   output [SEG-1:0] out5,
   output [SEG-1:0] out6,
   output [SEG-1:0] out7);

  logic [31:0] 	    dat_i, dat_o;
  
`ifdef NO_MODPORT_EXPRESSIONS
  assign dat_i = bus.dat_m;
  assign bus.dat_s = dat_o;
`else
  assign dat_i = bus.dat_i;
  assign bus.dat_o = dat_o;
`endif

  assign bus.stall = 1'b0;
  assign bus.ack = state;
  assign dat_o = result;

  assign out0 = hexed[0][SEG-1:0];
  assign out1 = hexed[1][SEG-1:0];
  assign out2 = hexed[2][SEG-1:0];
  assign out3 = hexed[3][SEG-1:0];
  assign out4 = hexed[4][SEG-1:0];
  assign out5 = hexed[5][SEG-1:0];
  assign out6 = hexed[6][SEG-1:0];
  assign out7 = hexed[7][SEG-1:0];
  
  logic [31:0] 	    segvals, segvals_next;
  logic [7:0] 	    hexed[7:0];
  
  logic 	    state, state_next;
  logic [31:0] 	    result, result_next;
  
  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	state <= 1'b0;
	segvals <= 32'h0;
	result <= 32'h0;
      end
    else
      begin
	state <= state_next;
	segvals <= segvals_next;
	result <= result_next;
      end // else: !if(rst_i)
  
  always_comb
    begin
      state_next = state;
      result_next = result;
      segvals_next = segvals;

      case (state)
	1'h0:
	  if (bus.cyc && bus.stb)
	    begin
	      case (bus.adr[2])
		1'h0:
		  if (bus.we)
		    begin
		      if (bus.sel[3])
			segvals_next[31:24] = dat_i[31:24];
		      if (bus.sel[2])
			segvals_next[23:16] = dat_i[23:16];
		      if (bus.sel[1])
			segvals_next[15:8] = dat_i[15:8];
		      if (bus.sel[0])
			segvals_next[7:0] = dat_i[7:0];
		    end
		  else
		    begin
		      result_next = segvals;
		    end
		1'h1:
		  if (!bus.we)
		    result_next = { 22'h0, sw};
	      endcase // case (bus.adr[5])
	      state_next = 1'b1;
	    end
	1'h1:
	  state_next = 1'h0;
      endcase // case (state)
    end

  hexdisp hexdisp0(.in({ 1'b0, segvals[3:0]}), .out(hexed[0]));
  hexdisp hexdisp1(.in({ 1'b0, segvals[7:4]}), .out(hexed[1]));
  hexdisp hexdisp2(.in({ 1'b0, segvals[11:8]}), .out(hexed[2]));
  hexdisp hexdisp3(.in({ 1'b0, segvals[15:12]}), .out(hexed[3]));
  hexdisp hexdisp4(.in({ 1'b0, segvals[19:16]}), .out(hexed[4]));
  hexdisp hexdisp5(.in({ 1'b0, segvals[23:20]}), .out(hexed[5]));
  hexdisp hexdisp6(.in({ 1'b0, segvals[27:24]}), .out(hexed[6]));
  hexdisp hexdisp7(.in({ 1'b0, segvals[31:28]}), .out(hexed[7]));
  
endmodule
