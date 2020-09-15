`timescale 1ns / 1ns

`include "../../fpgalib/wb.vh"

module mmu
  #(BASE=28)
  (input        clk_i,
   input        rst_i,
   if_wb.slave  mbus,
   if_wb.master p0,
   if_wb.master p1,
   if_wb.master p2,
   if_wb.master p3,
   if_wb.master p4,
   if_wb.master p5,
   if_wb.master p6,
   if_wb.master p7,
   if_wb.master p8,
   if_wb.master p9,
   if_wb.master pa,
   if_wb.master pb,
   if_wb.master pc,
   if_wb.master pd,
   if_wb.master pe,
   if_wb.master pf);

  logic [31:0] 	mbus_dat_i, mbus_dat_o;
  logic [31:0] 	p0_dat_i, p0_dat_o;
  logic [31:0] 	p1_dat_i, p1_dat_o;
  logic [31:0] 	p2_dat_i, p2_dat_o;
  logic [31:0] 	p3_dat_i, p3_dat_o;
  logic [31:0] 	p4_dat_i, p4_dat_o;
  logic [31:0] 	p5_dat_i, p5_dat_o;
  logic [31:0] 	p6_dat_i, p6_dat_o;
  logic [31:0] 	p7_dat_i, p7_dat_o;
  logic [31:0] 	p8_dat_i, p8_dat_o;
  logic [31:0] 	p9_dat_i, p9_dat_o;
  logic [31:0] 	pa_dat_i, pa_dat_o;
  logic [31:0] 	pb_dat_i, pb_dat_o;
  logic [31:0] 	pc_dat_i, pc_dat_o;
  logic [31:0] 	pd_dat_i, pd_dat_o;
  logic [31:0] 	pe_dat_i, pe_dat_o;
  logic [31:0] 	pf_dat_i, pf_dat_o;
	
`ifdef NO_MODPORT_EXPRESSIONS
  assign mbus_dat_i = mbus.dat_m;
  assign mbus.dat_s = mbus_dat_o;
  assign p0_dat_i = p0.dat_s;
  assign p0.dat_m = p0_dat_o;
  assign p1_dat_i = p1.dat_s;
  assign p1.dat_m = p1_dat_o;
  assign p2_dat_i = p2.dat_s;
  assign p2.dat_m = p2_dat_o;
  assign p3_dat_i = p3.dat_s;
  assign p3.dat_m = p3_dat_o;
  assign p4_dat_i = p4.dat_s;
  assign p4.dat_m = p4_dat_o;
  assign p5_dat_i = p5.dat_s;
  assign p5.dat_m = p5_dat_o;
  assign p6_dat_i = p6.dat_s;
  assign p6.dat_m = p6_dat_o;
  assign p7_dat_i = p7.dat_s;
  assign p7.dat_m = p7_dat_o;
  assign p8_dat_i = p8.dat_s;
  assign p8.dat_m = p8_dat_o;
  assign p9_dat_i = p9.dat_s;
  assign p9.dat_m = p9_dat_o;
  assign pa_dat_i = pa.dat_s;
  assign pa.dat_m = pa_dat_o;
  assign pb_dat_i = pb.dat_s;
  assign pb.dat_m = pb_dat_o;
  assign pc_dat_i = pc.dat_s;
  assign pc.dat_m = pc_dat_o;
  assign pd_dat_i = pd.dat_s;
  assign pd.dat_m = pd_dat_o;
  assign pe_dat_i = pe.dat_s;
  assign pe.dat_m = pe_dat_o;
  assign pf_dat_i = pf.dat_s;
  assign pf.dat_m = pf_dat_o;
`else
  assign mbus_dat_i = mbus.dat_i;
  assign mbus.dat_o = mbus_dat_o;
  assign p0_dat_i = p0.dat_i;
  assign p0.dat_o = p0_dat_o;
  assign p1_dat_i = p1.dat_i;
  assign p1.dat_o = p1_dat_o;
  assign p2_dat_i = p2.dat_i;
  assign p2.dat_o = p2_dat_o;
  assign p3_dat_i = p3.dat_i;
  assign p3.dat_o = p3_dat_o;
  assign p4_dat_i = p4.dat_i;
  assign p4.dat_o = p4_dat_o;
  assign p5_dat_i = p5.dat_i;
  assign p5.dat_o = p5_dat_o;
  assign p6_dat_i = p6.dat_i;
  assign p6.dat_o = p6_dat_o;
  assign p7_dat_i = p7.dat_i;
  assign p7.dat_o = p7_dat_o;
  assign p8_dat_i = p8.dat_i;
  assign p8.dat_o = p8_dat_o;
  assign p9_dat_i = p9.dat_i;
  assign p9.dat_o = p9_dat_o;
  assign pa_dat_i = pa.dat_i;
  assign pa.dat_o = pa_dat_o;
  assign pb_dat_i = pb.dat_i;
  assign pb.dat_o = pb_dat_o;
  assign pc_dat_i = pc.dat_i;
  assign pc.dat_o = pc_dat_o;
  assign pd_dat_i = pd.dat_i;
  assign pd.dat_o = pd_dat_o;
  assign pe_dat_i = pe.dat_i;
  assign pe.dat_o = pe_dat_o;
  assign pf_dat_i = pf.dat_i;
  assign pf.dat_o = pf_dat_o;
`endif

  // fixed wiring
  always_comb
    begin
      p0.cyc = mbus.cyc;
      p1.cyc = mbus.cyc;
      p2.cyc = mbus.cyc;
      p3.cyc = mbus.cyc;
      p4.cyc = mbus.cyc;
      p5.cyc = mbus.cyc;
      p6.cyc = mbus.cyc;
      p7.cyc = mbus.cyc;
      p8.cyc = mbus.cyc;
      p9.cyc = mbus.cyc;
      pa.cyc = mbus.cyc;
      pb.cyc = mbus.cyc;
      pc.cyc = mbus.cyc;
      pd.cyc = mbus.cyc;
      pe.cyc = mbus.cyc;
      pf.cyc = mbus.cyc;
      p0_dat_o = mbus_dat_i;
      p1_dat_o = mbus_dat_i;
      p2_dat_o = mbus_dat_i;
      p3_dat_o = mbus_dat_i;
      p4_dat_o = mbus_dat_i;
      p5_dat_o = mbus_dat_i;
      p6_dat_o = mbus_dat_i;
      p7_dat_o = mbus_dat_i;
      p8_dat_o = mbus_dat_i;
      p9_dat_o = mbus_dat_i;
      pa_dat_o = mbus_dat_i;
      pb_dat_o = mbus_dat_i;
      pc_dat_o = mbus_dat_i;
      pd_dat_o = mbus_dat_i;
      pe_dat_o = mbus_dat_i;
      pf_dat_o = mbus_dat_i;
      p0.sel = mbus.sel;
      p1.sel = mbus.sel;
      p2.sel = mbus.sel;
      p3.sel = mbus.sel;
      p4.sel = mbus.sel;
      p5.sel = mbus.sel;
      p6.sel = mbus.sel;
      p7.sel = mbus.sel;
      p8.sel = mbus.sel;
      p9.sel = mbus.sel;
      pa.sel = mbus.sel;
      pb.sel = mbus.sel;
      pc.sel = mbus.sel;
      pd.sel = mbus.sel;
      pe.sel = mbus.sel;
      pf.sel = mbus.sel;
      p0.we = mbus.we;
      p1.we = mbus.we;
      p2.we = mbus.we;
      p3.we = mbus.we;
      p4.we = mbus.we;
      p5.we = mbus.we;
      p6.we = mbus.we;
      p7.we = mbus.we;
      p8.we = mbus.we;
      p9.we = mbus.we;
      pa.we = mbus.we;
      pb.we = mbus.we;
      pc.we = mbus.we;
      pd.we = mbus.we;
      pe.we = mbus.we;
      pf.we = mbus.we;
      p0.adr = mbus.adr;
      p1.adr = mbus.adr;
      p2.adr = mbus.adr;
      p3.adr = mbus.adr;
      p4.adr = mbus.adr;
      p5.adr = mbus.adr;
      p6.adr = mbus.adr;
      p7.adr = mbus.adr;
      p8.adr = mbus.adr;
      p9.adr = mbus.adr;
      pa.adr = mbus.adr;
      pb.adr = mbus.adr;
      pc.adr = mbus.adr;
      pd.adr = mbus.adr;
      pe.adr = mbus.adr;
      pf.adr = mbus.adr;
    end // always_comb

  logic state, state_next;
  logic [3:0] active, active_next;
  
  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	active <= 4'hf;
	state <= 1'b0;
      end
    else
      begin
	active <= active_next;
	state <= state_next;
      end

  always_comb
    begin
      active_next = active;
      state_next = state;
      case (state)
	1'b0:
	  if (mbus.cyc)
	    begin
	      active_next = mbus.adr[BASE+3:BASE];
	      state_next = 1'b1;
	    end
	1'b1:
	  if (!mbus.cyc)
	    state_next = 1'b0;
      endcase
    end
      
  always_comb
    begin
      p0.stb = 1'b0;
      p1.stb = 1'b0;
      p2.stb = 1'b0;
      p3.stb = 1'b0;
      p4.stb = 1'b0;
      p5.stb = 1'b0;
      p6.stb = 1'b0;
      p7.stb = 1'b0;
      p8.stb = 1'b0;
      p9.stb = 1'b0;
      pa.stb = 1'b0;
      pb.stb = 1'b0;
      pc.stb = 1'b0;
      pd.stb = 1'b0;
      pe.stb = 1'b0;
      pf.stb = 1'b0;
      mbus_dat_o = 32'h0;
      mbus.ack = 1'b0;
      mbus.stall = 1'b0;
      
      case (state ? active : mbus.adr[BASE+3:BASE])
	4'h0:
	  begin
	    p0.stb = mbus.stb;
	    mbus_dat_o = p0_dat_i;
	    mbus.ack = p0.ack;
	    mbus.stall = p0.stall;
	  end
	4'h1:
	  begin
	    p1.stb = mbus.stb;
	    mbus_dat_o = p1_dat_i;
	    mbus.ack = p1.ack;
	    mbus.stall = p1.stall;
	  end
	4'h2:
	  begin
	    p2.stb = mbus.stb;
	    mbus_dat_o = p2_dat_i;
	    mbus.ack = p2.ack;
	    mbus.stall = p2.stall;
	  end
	4'h3:
	  begin	    
	    p3.stb = mbus.stb;
	    mbus_dat_o = p3_dat_i;
	    mbus.ack = p3.ack;
	    mbus.stall = p3.stall;
	  end
	4'h4:
	  begin	    
	    p4.stb = mbus.stb;
	    mbus_dat_o = p4_dat_i;
	    mbus.ack = p4.ack;
	    mbus.stall = p4.stall;
	  end
	4'h5:
	  begin
	    p5.stb = mbus.stb;
	    mbus_dat_o = p5_dat_i;
	    mbus.ack = p5.ack;
	    mbus.stall = p5.stall;
	  end
	4'h6:
	  begin
	    p6.stb = mbus.stb;
	    mbus_dat_o = p6_dat_i;
	    mbus.ack = p6.ack;
	    mbus.stall = p6.stall;
	  end
	4'h7:
	  begin
	    p7.stb = mbus.stb;
	    mbus_dat_o = p7_dat_i;
	    mbus.ack = p7.ack;
	    mbus.stall = p7.stall;
	  end
	4'h8:
	  begin
	    p8.stb = mbus.stb;
	    mbus_dat_o = p8_dat_i;
	    mbus.ack = p8.ack;
	    mbus.stall = p8.stall;
	  end
	4'h9:
	  begin
	    p9.stb = mbus.stb;
	    mbus_dat_o = p9_dat_i;
	    mbus.ack = p9.ack;
	    mbus.stall = p9.stall;
	  end
	4'ha:
	  begin
	    pa.stb = mbus.stb;
	    mbus_dat_o = pa_dat_i;
	    mbus.ack = pa.ack;
	    mbus.stall = pa.stall;
	  end
	4'hb:
	  begin
	    pb.stb = mbus.stb;
	    mbus_dat_o = pb_dat_i;
	    mbus.ack = pb.ack;
	    mbus.stall = pb.stall;
	  end
	4'hc:
	  begin
	    pc.stb = mbus.stb;
	    mbus_dat_o = pc_dat_i;
	    mbus.ack = pc.ack;
	    mbus.stall = pc.stall;
	  end
	4'hd:
	  begin
	    pd.stb = mbus.stb;
	    mbus_dat_o = pd_dat_i;
	    mbus.ack = pd.ack;
	    mbus.stall = pd.stall;
	  end
	4'he:
	  begin
	    pe.stb = mbus.stb;
	    mbus_dat_o = pe_dat_i;
	    mbus.ack = pe.ack;
	    mbus.stall = pe.stall;
	  end
	4'hf:
	  begin
	    pf.stb = mbus.stb;
	    mbus_dat_o = pf_dat_i;
	    mbus.ack = pf.ack;
	    mbus.stall = pf.stall;
	  end
	default:
	  begin end
      endcase // case (active)
    end // always_comb
endmodule
