`include "../wb.vh"

`define VGA_GRAPHICS

module vga_master
  #(VGA_MEMBASE = 32'h0,
    BPP = 8)
  (
   input 	    clk_i,
   input 	    rst_i,
   input            vga_clock25,
   input            vga_clock28,
   if_wb.slave      inbus,
   if_wb.master     outbus,
   output 	    vs,
   output 	    hs,
   output [BPP-1:0] r,
   output [BPP-1:0] g,
   output [BPP-1:0] b,
   output 	    blank_n,
   output 	    sync_n,
   output 	    vga_clock);

  // Configuration registers
  // 0x000 - palette memory 1
  // 0x400 - palette memory 2
  // 0x800 - font memory 1
  // 0xc00 - video memory base address
  // 0xc01 - video mode, palette select
  
  logic [31:0] 	    inbus_dat_o, inbus_dat_i;
  logic [31:0] 	    outbus_dat_o, outbus_dat_i;
  
  if_wb textbus();
  if_wb graphicsbus();
  if_wb palbus();
  
`ifdef NO_MODPORT_EXPRESSIONS
  assign inbus_dat_i = inbus.dat_m;
  assign inbus.dat_s = inbus_dat_o;
  assign outbus_dat_i = outbus.dat_s;
  assign outbus.dat_m = outbus_dat_o;
`else
  assign inbus_dat_i = inbus.dat_i;
  assign inbus.dat_o = inbus_dat_o;
  assign outbus_dat_i = outbus.dat_i;
  assign outbus.dat_o = outbus_dat_o;
`endif
  
  typedef enum 	    bit [2:0] { SS_IDLE, SS_PALETTE, 
				SS_PALETTE2, SS_FONT, SS_DONE } sstate_t;
  
  sstate_t           sstate, sstate_next;
  logic [31:0] 	    setupreg, setupreg_next,
		    vgabase, vgabase_next,
		    cursorpos, cursorpos_next;
  logic [31:0] 	    inbus_dat_o_next;
  logic [23:0] 	    cursorcolor, cursorcolor_next;
  logic [BPP-1:0]   td_r, td_g, td_b;
  logic [15:0] 	    x28_raw, y28_raw;
  logic 	    vs28, hs28;
  logic 	    blank28_n, eol28, eos28;
  logic 	    v_active28, h_active28;
  
  assign blank28_n = v_active28 & h_active28;

`ifdef VGA_GRAPHICS
  logic [15:0] 	    x25_raw, y25_raw;
  logic [BPP-1:0]   gd_r, gd_g, gd_b;
  logic 	    vs25, hs25;
  logic 	    v_active25, h_active25;
  logic 	    blank25_n, eol25, eos25;

  assign blank25_n = v_active25 & h_active25;
  
`endif
  
  assign inbus.ack = (sstate == SS_DONE);
  assign inbus.stall = 1'h0;
  assign textbus.ack = outbus.ack;
  assign textbus.stall = outbus.stall;
  assign textbus.dat_s = outbus_dat_i;
  assign graphicsbus.dat_s = outbus_dat_i;
  assign graphicsbus.ack = outbus.ack;
  assign graphicsbus.stall = outbus.stall;

  // timing changes based on graphics mode
  always_comb
    begin
`ifdef VGA_GRAPHICS
      if (setupreg[1])
	begin
`endif
	  r = td_r;
	  g = td_g;
	  b = td_b;
	  vga_clock = vga_clock28;
	  vs = vs28;
	  hs = hs28;
	  blank_n = blank28_n;
	  outbus.cyc = textbus.cyc;
	  outbus.stb = textbus.stb;
	  outbus.adr = textbus.adr;
	  outbus.we = textbus.we;
	  outbus.sel = textbus.sel;
	  outbus_dat_o = textbus.dat_m;
`ifdef VGA_GRAPHICS
	end
      else
	begin
	  r = gd_r;
	  g = gd_g;
	  b = gd_b;
	  vga_clock = vga_clock25;
	  vs = vs25;
	  hs = hs25;
	  blank_n = blank25_n;
	  outbus.cyc = graphicsbus.cyc;
	  outbus.adr = graphicsbus.adr;
	  outbus.stb = graphicsbus.stb;
	  outbus.we = graphicsbus.we;
	  outbus.sel = graphicsbus.sel;
	  outbus_dat_o = graphicsbus.dat_m;
	end // else: !if(setupreg[1])
`endif
    end // always_comb
  
  
  assign sync_n = 1'b0;
  
  // Slave state machine
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  vgabase <= VGA_MEMBASE;
	  setupreg <= 32'h02;
	  inbus_dat_o <= 32'h0;
	  cursorpos <= 32'h0;
	  cursorcolor <= 24'ha0a0a0;
	  sstate <= SS_IDLE;
	end
      else
	begin
	  vgabase <= vgabase_next;
	  setupreg <= setupreg_next;
	  inbus_dat_o <= inbus_dat_o_next;
	  cursorpos <= cursorpos_next;
	  cursorcolor <= cursorcolor_next;
	  sstate <= sstate_next;
	end
    end
  
  always_comb
    begin
      sstate_next = sstate;
      setupreg_next = setupreg;
      vgabase_next = vgabase;
      cursorpos_next = cursorpos;
      cursorcolor_next = cursorcolor;
      inbus_dat_o_next = inbus_dat_o;
      
      case (sstate)
	SS_IDLE:
	  if (inbus.cyc & inbus.stb)
            case (inbus.adr[11:10])
              2'h0: sstate_next = SS_PALETTE;
              2'h1: sstate_next = SS_PALETTE2;
              2'h2: sstate_next = SS_FONT;
              2'h3:
		begin
		  case (inbus.adr[9:2])
		    8'h0:
		      begin // c00 - vga base
			if (inbus.we)
			  begin
			    if (inbus.sel[3])
			      vgabase_next[31:24] = inbus_dat_i[31:24];
			    if (inbus.sel[2])
			      vgabase_next[23:16] = inbus_dat_i[23:16];
			    if (inbus.sel[1])
			      vgabase_next[15:8] = inbus_dat_i[15:8];
			    if (inbus.sel[0])
			      vgabase_next[7:0] = inbus_dat_i[7:0];
			  end
			else
			  inbus_dat_o_next = vgabase;
		      end
		    8'h1:
		      begin // c01 - graphics mode / cursor mode
			if (inbus.we)
			  begin
			    if (inbus.sel[3])
			      setupreg_next[31:24] = inbus_dat_i[31:24];
			    if (inbus.sel[2])
			      setupreg_next[23:16] = inbus_dat_i[23:16];
			    if (inbus.sel[1])
			      setupreg_next[15:8] = inbus_dat_i[15:8];
			    if (inbus.sel[0])
			      setupreg_next[7:0] = inbus_dat_i[7:0];
			  end
			else
			  inbus_dat_o_next = setupreg;
		      end
		    8'h2:
		      begin // c02 - cursor position
			if (inbus.we)
			  begin
			    if (inbus.sel[3])
			      cursorpos_next[31:24] = inbus_dat_i[31:24];
			    if (inbus.sel[2])
			      cursorpos_next[23:16] = inbus_dat_i[23:16];
			    if (inbus.sel[1])
			      cursorpos_next[15:8] = inbus_dat_i[15:8];
			    if (inbus.sel[0])
			      cursorpos_next[7:0] = inbus_dat_i[7:0];
			  end
			else
			  inbus_dat_o_next = cursorpos;
		      end // case: 8'h2
		    8'h3:
		      begin // c03 - cursor color
			if (inbus.we)
			  begin
			    if (inbus.sel[2])
			      cursorcolor_next[23:16] = inbus_dat_i[23:16];
			    if (inbus.sel[1])
			      cursorcolor_next[15:8] = inbus_dat_i[15:8];
			    if (inbus.sel[0])
			      cursorcolor_next[7:0] = inbus_dat_i[7:0];
			  end
			else
			  inbus_dat_o_next = cursorcolor;
		      end
		    default:
		      begin
			if (~inbus.we)
			  inbus_dat_o_next = 32'h0;
		      end
		  endcase
		  sstate_next = SS_DONE;
		end
              default:
		sstate_next = SS_DONE;
            endcase
	SS_PALETTE: sstate_next = SS_DONE;
	SS_PALETTE2: sstate_next = SS_DONE;
	SS_FONT: sstate_next = SS_DONE;
	SS_DONE: sstate_next = SS_IDLE;
      endcase
    end

  textdrv #(.BPP(BPP)) textdriver0(.clk_i(vga_clock28),
				   .rst_i(rst_i|eos28),
				   .eol(eol28),
				   .h_active(h_active28),
				   .v_active(v_active28),
				   .red(td_r),
				   .green(td_g),
				   .blue(td_b),
				   .cursorpos(cursorpos),
				   .cursormode(setupreg[7:4]),
				   .cursorcolor(cursorcolor),
				   .bus(textbus.master));
  
  vga_controller28 vga1(.vs(vs28),
			.hs(hs28),
			.v_active(v_active28),
			.h_active(h_active28),
			.eol(eol28),
			.eos(eos28),
			.clock(vga_clock28),
			.rst_i(rst_i));

`ifdef VGA_GRAPHICS

  graphicsdrv graphicsdriver0(.clk_i(vga_clock25),
			      .rst_i(rst_i|eos25),
			      .mode(setupreg[11:8]),
			      .v_active(v_active25),
			      .h_active(h_active25),
			      .eol(eol25),
			      .red(gd_r),
			      .green(gd_g),
			      .blue(gd_b),
			      .fb_bus(graphicsbus.master),
			      .pal_bus(palbus.master));
  
  vga_controller25 vga0(.v_active(v_active25),
			.h_active(h_active25),
			.vs(vs25),
			.hs(hs25),
			.eos(eos25),
			.eol(eol25),
			.clock(vga_clock25),
			.rst_i(rst_i));
  
`endif //  `ifdef VGA_GRAPHICS
  
endmodule
