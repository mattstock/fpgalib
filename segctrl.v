`include "wb.vh"

module segctrl
  #(SEG=7)
  (input            clk_i,
   input 	    rst_i,
   if_wb.slave      bus,
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
  
  logic [4:0] 	    vals[7:0], vals_next[7:0];
  logic [7:0] 	    hexed[7:0];
  
  logic 	    state, state_next;
  logic [31:0] 	    result, result_next;
  
  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	state <= 1'b0;
	for (int i=0; i < 8; i = i + 1)
	  vals[i] <= 5'h0;
	result <= 32'h0;
      end
    else
      begin
	state <= state_next;
	for (int i=0; i < 8; i = i + 1)
	  vals[i] <= vals_next[i];
	result <= result_next;
      end // else: !if(rst_i)
  
  always_comb
    begin
      state_next = state;
      result_next = result;
      
      for (int i=0; i < 8; i = i + 1)
	vals_next[i] = vals[i];

      case (state)
	1'h0:
	  if (bus.cyc && bus.stb)
	    begin
	      state_next = 1'b1;
	      if (bus.we)
		vals_next[bus.adr[4:2]] = dat_i[4:0];
	      else
		result_next = { 27'h0, vals[bus.adr[4:2]][4:0] };
	    end
	1'h1:
	  state_next = 1'h0;
      endcase // case (state)
    end

  hexdisp hexdisp0(.in(vals[0]), .out(hexed[0]));
  hexdisp hexdisp1(.in(vals[1]), .out(hexed[1]));
  hexdisp hexdisp2(.in(vals[2]), .out(hexed[2]));
  hexdisp hexdisp3(.in(vals[3]), .out(hexed[3]));
  hexdisp hexdisp4(.in(vals[4]), .out(hexed[4]));
  hexdisp hexdisp5(.in(vals[5]), .out(hexed[5]));
  hexdisp hexdisp6(.in(vals[6]), .out(hexed[6]));
  hexdisp hexdisp7(.in(vals[7]), .out(hexed[7]));
  
endmodule
