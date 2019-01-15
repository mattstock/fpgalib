`include "../wb.vh"

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
  
`ifdef NO_MODPORT_EXPRESSIONS
  assign inbus_dat_i = inbus.dat_m;
  assign inbus.dat_s = inbus_dat_o;
`else
  assign inbus_dat_i = inbus.dat_i;
  assign inbus.dat_o = inbus_dat_o;
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
  logic [BPP-1:0]   gd_r, gd_g, gd_b;
  logic [15:0] 	    x25_raw, y25_raw;
  logic [15:0] 	    x28_raw, y28_raw;
  logic 	    vs25, hs25;
  logic 	    vs28, hs28;
  logic 	    blank25_n, blank28_n;
  
  assign inbus.ack = (sstate == SS_DONE);
  assign inbus.stall = 1'h0;

  // timing changes based on graphics mode
  always_comb
    begin
      if (setupreg[1])
	begin
	  r = td_r;
	  g = td_g;
	  b = td_b;
	  vga_clock = vga_clock28;
	  vs = vs28;
	  hs = hs28;
	  blank_n = blank28_n;
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
	end
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

  logic eol;

  
  textdrv #(.BPP(BPP)) textdriver0(.clk_i(vga_clock28),
				   .rst_i(rst_i),
				   .active(blank28_n),
				   .eol(eol),
				   .r(td_r),
				   .g(td_g),
				   .b(td_b),
				   .cursorpos(cursorpos),
				   .cursormode(setupreg[7:4]),
				   .cursorcolor(cursorcolor),
				   .bus(outbus.master));
  
  vga_controller25 vga0(.active(blank25_n),
			.vs(vs25),
			.hs(hs25),
			.clock(vga_clock25),
			.rst_i(rst_i),
			.x(x25_raw),
			.y(y25_raw));
  
  vga_controller28 vga1(.active(blank28_n),
			.vs(vs28),
			.hs(hs28),
			.eol(eol),
			.clock(vga_clock28),
			.rst_i(rst_i));
  
endmodule
