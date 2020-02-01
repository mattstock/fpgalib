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
`endif
  
  always_comb
    begin
      in0.ack = 1'h0;
      in0_dat_o = 32'h0;
      in0.stall = 1'h0;
      in1.ack = 1'h0;
      in1_dat_o = 32'h0;
      in1.stall = 1'h0;
      out.cyc = 1'h0;
      out.stb = 1'h0;
      out.adr = 32'h0;
      out.we = 1'h0;
      out.sel = 4'h0;
      out_dat_o = 32'h0;
      if (in0.cyc)
	begin
	  out.cyc = in0.cyc;
	  out.stb = in0.stb;
	  out.sel = in0.sel;
	  out.adr = in0.adr;
	  out_dat_o = in0_dat_i;
	  out.we = in0.we;
	  in0_dat_o = out_dat_i;
	  in0.stall = out.stall;
	  in0.ack = out.ack;
	end // if (in0.cyc & in0.stb)
      else
	if (in1.cyc)
	  begin
	    out.cyc = in1.cyc;
	    out.stb = in1.stb;
	    out.sel = in1.sel;
	    out.adr = in1.adr;
	    out_dat_o = in1_dat_i;
	    out.we = in1.we;
	    in1_dat_o = out_dat_i;
	    in1.stall = out.stall;
	    in1.ack = out.ack;
	  end // if (in1.cyc & in1.stb)
    end
	
endmodule // arbiter
