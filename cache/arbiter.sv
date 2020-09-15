`timescale 1ns / 1ns

`include "../wb.vh"

module arbiter
  (input        clk_i,
   input        rst_i,
   if_wb.slave  in0,
   if_wb.slave  in1,
   if_wb.master out);

  logic [31:0] out_dat_i, out_dat_o;
  logic [31:0] in0_dat_i, in0_dat_o;
  logic [31:0] in1_dat_i, in1_dat_o;
  
`ifdef NO_MODPORT_EXPRESSIONS
  assign in0_dat_i = in0.dat_m;
  assign in0.dat_s = in0_dat_o;
  assign in1_dat_i = in1.dat_m;
  assign in1.dat_s = in1_dat_o;
  assign out_dat_i = out.dat_s;
  assign out.dat_m = out_dat_o;
`else
  assign in0_dat_i = in0.dat_i;
  assign in0.dat_o = in0_dat_o;
  assign in1_dat_i = in1.dat_i;
  assign in1.dat_o = in1_dat_o;
  assign out_dat_i = out.dat_i;
  assign out.dat_o = out_dat_o;
`endif // !`ifdef NO_MODPORT_EXPRESSIONS

  typedef enum bit [1:0] { S_IDLE, S_IN0, S_IN1, S_END } state_t;

  state_t state, state_next;

  assign in0.stall = (state != S_IN0) | out.stall;
  assign in0_dat_o = out_dat_i;
  assign in1.stall = (state != S_IN1) | out.stall;
  assign in1_dat_o = out_dat_i;

  always_ff @(posedge clk_i)
    if (rst_i)
      begin
	state <= S_IDLE;
      end
    else
      begin
	state <= state_next;
      end

  always_comb
    begin
      state_next = state;
      in0.ack = 1'h0;
      in1.ack = 1'h0;
      out.cyc = 1'h0;
      out.stb = 1'h0;
      out.adr = 32'h0;
      out.we = 1'h0;
      out.sel = 4'h0;
      out_dat_o = 32'h0;
      
      case (state)
	S_IDLE:
	  begin
	    if (in1.cyc)
	      state_next = S_IN1;
	    else
	      if (in0.cyc)
		state_next = S_IN0;
  	  end
	S_IN0:
	  begin
	    if (!in0.cyc)
	      state_next = S_END;
	    out.cyc = in0.cyc;
	    out.stb = in0.stb;
	    out.sel = in0.sel;
	    out.adr = in0.adr;
	    out_dat_o = in0_dat_i;
	    out.we = in0.we;
	    in0.ack = out.ack;
	  end
	S_IN1:
	  begin
	    if (!in1.cyc)
	      state_next = S_END;
	    out.cyc = in1.cyc;
	    out.stb = in1.stb;
	    out.sel = in1.sel;
	    out.adr = in1.adr;
	    out_dat_o = in1_dat_i;
	    out.we = in1.we;
	    in1.ack = out.ack;
	  end
	S_END:
	  begin
	    state_next = S_IDLE;
	  end
      endcase // case (state)
    end // always_comb
  
endmodule // arbiter
