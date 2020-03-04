`include "../wb.vh"

`define VGA_MONO

module vga_master
  #(BPP = 8)
  (
   input 	    clk_i,
   input 	    rst_i,
   input 	    vga_clock25,
   input 	    vga_clock28,
   input            vga_rst_i, 	    
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
  // 0xc00 - video memory base address
  // 0xc01 - video mode, palette select
  
  logic [31:0] 	    inbus_dat_o, inbus_dat_i;
  logic [31:0] 	    outbus_dat_o, outbus_dat_i;
  
  if_wb textbus();
  if_wb gm_640x480x1bus();
  if_wb gm_640x480x8bus();
  if_wb gm_320x200x8bus();
  if_wb palettebus();
  
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
		    cursorpos, cursorpos_next;
  logic [31:0] 	    inbus_dat_o_next;
  logic [23:0] 	    cursorcolor, cursorcolor_next;
  logic [BPP-1:0]   td_r, td_g, td_b;
  logic [15:0] 	    x28_raw, y28_raw;
  logic 	    vs28, hs28;
  logic 	    blank28_n;
  
  logic [15:0] 	    x25_raw, y25_raw;
  logic [BPP-1:0]   gm_640x480x1_r, gm_640x480x1_g, gm_640x480x1_b;
  logic 	    vs25, hs25;
  logic 	    blank25_n;
  logic [BPP-1:0]   gm_640x480x8_r, gm_640x480x8_g, gm_640x480x8_b;
  logic 	    vs_640x480x8, hs_640x480x8;
  logic 	    blank_640x480x8_n;
  logic [BPP-1:0]   gm_320x200x8_r, gm_320x200x8_g, gm_320x200x8_b;
  logic 	    vs_320x200x8, hs_320x200x8;
  logic 	    blank_320x200x8_n;
  logic [2:0] 	    gm_active;
  
  assign sync_n = 1'b0;
  
  assign inbus.ack = (sstate == SS_DONE);
  assign inbus.stall = 1'h0;
  assign textbus.ack = outbus.ack;
  assign textbus.stall = outbus.stall;
  assign textbus.dat_s = outbus_dat_i;
  assign gm_640x480x1bus.dat_s = outbus_dat_i;
  assign gm_640x480x1bus.ack = outbus.ack;
  assign gm_640x480x1bus.stall = outbus.stall;
  assign gm_640x480x8bus.dat_s = outbus_dat_i;
  assign gm_640x480x8bus.ack = outbus.ack;
  assign gm_640x480x8bus.stall = outbus.stall;
  assign gm_320x200x8bus.dat_s = outbus_dat_i;
  assign gm_320x200x8bus.ack = outbus.ack;
  assign gm_320x200x8bus.stall = outbus.stall;

  assign palettebus.adr = inbus.adr;
  assign palettebus.cyc = inbus.cyc;
  assign palettebus.sel = inbus.sel;
  assign palettebus.we = inbus.we;
  assign palettebus.dat_m = inbus_dat_i;

  assign gm_active = setupreg[2:0];
  
  // timing changes based on graphics mode
  // we likely will need to gate this so that we don't interrupt
  // a bus cycle
  always_comb
    begin
      case (gm_active)
	3'h0: // 640x480x1 60Hz graphics
	  begin
	    r = gm_640x480x1_r;
	    g = gm_640x480x1_g;
	    b = gm_640x480x1_b;
	    vga_clock = vga_clock25;
	    vs = vs25;
	    hs = hs25;
	    blank_n = blank25_n;
	    outbus.cyc = gm_640x480x1bus.cyc;
	    outbus.adr = gm_640x480x1bus.adr;
	    outbus.stb = gm_640x480x1bus.stb;
	    outbus.we = gm_640x480x1bus.we;
	    outbus.sel = gm_640x480x1bus.sel;
	    outbus_dat_o = gm_640x480x1bus.dat_m;
	  end
	3'h1: // 640x480x8 60Hz palette
	  begin
	    r = gm_640x480x8_r;
	    g = gm_640x480x8_g;
	    b = gm_640x480x8_b;
	    vga_clock = vga_clock25;
	    vs = vs_640x480x8;
	    hs = hs_640x480x8;
	    blank_n = blank_640x480x8_n;
	    outbus.cyc = gm_640x480x8bus.cyc;
	    outbus.adr = gm_640x480x8bus.adr;
	    outbus.stb = gm_640x480x8bus.stb;
	    outbus.we = gm_640x480x8bus.we;
	    outbus.sel = gm_640x480x8bus.sel;
	    outbus_dat_o = gm_640x480x8bus.dat_m;
	  end
	3'h2: // 640x480x8 60Hz grayscale
	  begin
	    r = gm_640x480x8_r;
	    g = gm_640x480x8_g;
	    b = gm_640x480x8_b;
	    vga_clock = vga_clock25;
	    vs = vs_640x480x8;
	    hs = hs_640x480x8;
	    blank_n = blank_640x480x8_n;
	    outbus.cyc = gm_640x480x8bus.cyc;
	    outbus.adr = gm_640x480x8bus.adr;
	    outbus.stb = gm_640x480x8bus.stb;
	    outbus.we = gm_640x480x8bus.we;
	    outbus.sel = gm_640x480x8bus.sel;
	    outbus_dat_o = gm_640x480x8bus.dat_m;
	  end
	3'h3: // 320x200x8 60Hz palette
	  begin
	    r = gm_320x200x8_r;
	    g = gm_320x200x8_g;
	    b = gm_320x200x8_b;
	    vga_clock = vga_clock25;
	    vs = vs_320x200x8;
	    hs = hs_320x200x8;
	    blank_n = blank_320x200x8_n;
	    outbus.cyc = gm_320x200x8bus.cyc;
	    outbus.adr = gm_320x200x8bus.adr;
	    outbus.stb = gm_320x200x8bus.stb;
	    outbus.we = gm_320x200x8bus.we;
	    outbus.sel = gm_320x200x8bus.sel;
	    outbus_dat_o = gm_320x200x8bus.dat_m;
	  end
	3'h4: // 320x200x8 60Hz grayscale
	  begin
	    r = gm_320x200x8_r;
	    g = gm_320x200x8_g;
	    b = gm_320x200x8_b;
	    vga_clock = vga_clock25;
	    vs = vs_320x200x8;
	    hs = hs_320x200x8;
	    blank_n = blank_320x200x8_n;
	    outbus.cyc = gm_320x200x8bus.cyc;
	    outbus.adr = gm_320x200x8bus.adr;
	    outbus.stb = gm_320x200x8bus.stb;
	    outbus.we = gm_320x200x8bus.we;
	    outbus.sel = gm_320x200x8bus.sel;
	    outbus_dat_o = gm_320x200x8bus.dat_m;
	  end
	default: // 720x400 text mode
	  begin
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
	  end // case: 2'h2
      endcase // case (setupreg[1:0])
    end // always_comb
  
  // Slave state machine
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  setupreg <= 32'h01;
	  inbus_dat_o <= 32'h0;
	  cursorpos <= 32'h0;
	  cursorcolor <= 24'ha0a0a0;
	  sstate <= SS_IDLE;
	end
      else
	begin
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
      cursorpos_next = cursorpos;
      cursorcolor_next = cursorcolor;
      inbus_dat_o_next = inbus_dat_o;
      palettebus.stb = 1'h0;
      
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
	SS_PALETTE: 
	  begin
	    palettebus.stb = 1'h1;
	    if (~inbus.we)
	      inbus_dat_o_next = 32'hbeefdead;
	    sstate_next = SS_DONE;
	  end
	SS_PALETTE2:
	  begin
	    if (~inbus.we)
	      inbus_dat_o_next = 32'hdeadbeef;
	    sstate_next = SS_DONE;
	  end
	SS_FONT: sstate_next = SS_DONE;
	SS_DONE: sstate_next = SS_IDLE;
      endcase
    end
  
  textdrv #(.BPP(BPP)) textdriver0(.clk_i(clk_i),
				   .rst_i(rst_i | (gm_active != 3'h5)),
				   .blank_n(blank28_n),
				   .red(td_r),
				   .green(td_g),
				   .blue(td_b),
				   .video_clk(vga_clock28),
				   .vs(vs28),
				   .hs(hs28),
				   .cursorpos(cursorpos),
				   .cursormode(setupreg[7:4]),
				   .cursorcolor(cursorcolor),
				   .bus(textbus.master));
  
  gm_640x480x1 graphicsdriver0(.clk_i(clk_i),
			  .rst_i(rst_i | (gm_active != 3'h0)),
			  .vs(vs25),
			  .hs(hs25),
			  .blank_n(blank25_n),
			  .video_clk_i(vga_clock25),
			  .video_rst_i(vga_rst_i),
			  .red(gm_640x480x1_r),
			  .green(gm_640x480x1_g),
			  .blue(gm_640x480x1_b),
			  .bus(gm_640x480x1bus.master));

  gm_640x480x8 graphicsdriver1(.clk_i(clk_i),
			       .rst_i(rst_i | (gm_active != 3'h1 &&
					       gm_active != 3'h2)),
			       .color(gm_active == 3'h1),
			       .vs(vs_640x480x8),
			       .hs(hs_640x480x8),
			       .blank_n(blank_640x480x8_n),
			       .video_clk_i(vga_clock25),
			       .video_rst_i(vga_rst_i),
			       .red(gm_640x480x8_r),
			       .green(gm_640x480x8_g),
			       .blue(gm_640x480x8_b),
			       .bus(gm_640x480x8bus.master),
			       .palette_bus(palettebus.slave));

  gm_320x200x8 graphicsdriver2(.clk_i(clk_i),
			       .rst_i(rst_i | (gm_active != 3'h3 &&
					       gm_active != 3'h4)),
			       .color(gm_active == 3'h3),
			       .vs(vs_320x200x8),
			       .hs(hs_320x200x8),
			       .blank_n(blank_320x200x8_n),
			       .video_clk_i(vga_clock25),
			       .video_rst_i(vga_rst_i),
			       .red(gm_320x200x8_r),
			       .green(gm_320x200x8_g),
			       .blue(gm_320x200x8_b),
			       .bus(gm_320x200x8bus.master),
			       .palette_bus(palettebus.slave));

endmodule
