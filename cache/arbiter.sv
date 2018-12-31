`include "../wb.vh"

module arbiter
  (input        clk_i,
   input        rst_i,
   if_wb.slave  in0,
   if_wb.slave  in1,
   if_wb.master out);

  always_comb
    begin
      in0.ack = 1'b0;
      in0.dat_o = 32'h0;
      in0.stall = out.stall;
      in1.ack = 1'b0;
      in1.dat_o = 32'h0;
      in1.stall = out.stall;
      out.cyc = 1'h0;
      out.stb = 1'h0;
      out.adr = 32'h0;
      out.we = 1'h0;
      out.sel = 4'h0;
      out.dat_o = 32'h0;
      if (in0.cyc)
	begin
	  out.cyc = in0.cyc;
	  out.stb = in0.stb;
	  out.sel = in0.sel;
	  out.adr = in0.adr;
	  out.dat_o = in0.dat_i;
	  out.we = in0.we;
	  in0.ack = out.ack;
	  in0.dat_o = out.dat_i;
	end // if (in0.cyc & in0.stb)
      else
	if (in1.cyc)
	  begin
	    out.cyc = in1.cyc;
	    out.stb = in1.stb;
	    out.sel = in1.sel;
	    out.adr = in1.adr;
	    out.dat_o = in1.dat_i;
	    out.we = in1.we;
	    in1.ack = out.ack;
	    in1.dat_o = out.dat_i;
	  end // if (in1.cyc & in1.stb)
    end
	
endmodule // arbiter
