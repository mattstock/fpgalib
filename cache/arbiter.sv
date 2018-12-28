`include "../wb.vh"

module arbiter
  (input        clk_i,
   input        rst_i,
   if_wb.slave  in0,
   if_wb.slave  in1,
   if_wb.master out);

  typedef enum bit [1:0] { S_IDLE, S_IN0, S_IN1, S_DONE } state_t;

  state_t state, state_next;
  
  always_ff @(posedge clk_i or posedge rst_i)
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
      in0.stall = 1'b1;
      in0.ack = 1'b0;
      in0.dat_o = 32'h0;
      
      in1.stall = 1'b1;
      in1.ack = 1'b0;
      in1.dat_o = 32'h0;
      
      out.cyc = 1'h0;
      out.stb = 1'h0;
      out.adr = 32'h0;
      out.we = 1'h0;
      out.sel = 4'h0;
      out.dat_o = 32'h0;
      
      case (state)
	S_IDLE:
	  begin
	    if (in0.cyc && in0.stb)
	      state_next = S_IN0;
	    else
	      if (in1.cyc && in1.stb)
		state_next = S_IN1;
	  end
	S_IN0:
	  begin
	    out.cyc = in0.cyc;
	    out.stb = in0.stb;
	    out.sel = in0.sel;
	    out.adr = in0.adr;
	    out.dat_o = in0.dat_i;
	    out.we = in0.we;
	    in0.ack = out.ack;
	    in0.stall = out.stall;
	    in0.dat_o = out.dat_i;
	    if (~in0.cyc)
	      state_next = S_DONE;
	  end
	S_IN1:
	  begin
	    out.cyc = in1.cyc;
	    out.stb = in1.stb;
	    out.sel = in1.sel;
	    out.adr = in1.adr;
	    out.dat_o = in1.dat_i;
	    out.we = in1.we;
	    in1.ack = out.ack;
	    in1.stall = out.stall;
	    in1.dat_o = out.dat_i;
	    if (~in1.cyc)
	      state_next = S_DONE;
	  end
	S_DONE:
	  state_next = S_IDLE;
      endcase // case (state)
    end // always_comb
	
endmodule // arbiter
