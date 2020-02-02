`include "../wb.vh"

`define VGA_MONO

module vga_master
  #(BPP = 8)
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
  // 0xc00 - video memory base address
  // 0xc01 - video mode, palette select
  
  logic [31:0] 	    inbus_dat_o, inbus_dat_i;
  logic [31:0] 	    outbus_dat_o, outbus_dat_i;
  
  if_wb textbus();
  if_wb gm_monobus();
  if_wb gm_13hbus();
  
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
  logic [BPP-1:0]   gm_mono_r, gm_mono_g, gm_mono_b;
  logic [BPP-1:0]   gm_13h_r, gm_13h_g, gm_13h_b;
  logic 	    vs25, hs25;
  logic 	    blank25_n;

  assign sync_n = 1'b0;
  
  assign inbus.ack = (sstate == SS_DONE);
  assign inbus.stall = 1'h0;
  assign textbus.ack = outbus.ack;
  assign textbus.stall = outbus.stall;
  assign textbus.dat_s = outbus_dat_i;
  assign gm_monobus.dat_s = outbus_dat_i;
  assign gm_monobus.ack = outbus.ack;
  assign gm_monobus.stall = outbus.stall;
  assign gm_13hbus.dat_s = outbus_dat_i;
  assign gm_13hbus.ack = outbus.ack;
  assign gm_13hbus.stall = outbus.stall;

  // timing changes based on graphics mode
  // we likely will need to gate this so that we don't interrupt
  // a bus cycle
  always_comb
    begin
      case (setupreg[1:0])
	2'h0: // mono graphics
	  begin
	    r = gm_mono_r;
	    g = gm_mono_g;
	    b = gm_mono_b;
	    vga_clock = vga_clock25;
	    vs = vs25;
	    hs = hs25;
	    blank_n = blank25_n;
	    outbus.cyc = gm_monobus.cyc;
	    outbus.adr = gm_monobus.adr;
	    outbus.stb = gm_monobus.stb;
	    outbus.we = gm_monobus.we;
	    outbus.sel = gm_monobus.sel;
	    outbus_dat_o = gm_monobus.dat_m;
	  end
	2'h1: // 13h graphics
	  begin
	    r = gm_13h_r;
	    g = gm_13h_g;
	    b = gm_13h_b;
	    vga_clock = vga_clock25;
	    vs = vs25;
	    hs = hs25;
	    blank_n = blank25_n;
	    outbus.cyc = gm_13hbus.cyc;
	    outbus.adr = gm_13hbus.adr;
	    outbus.stb = gm_13hbus.stb;
	    outbus.we = gm_13hbus.we;
	    outbus.sel = gm_13hbus.sel;
	    outbus_dat_o = gm_13hbus.dat_m;
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
	  setupreg <= 32'h02;
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
	SS_PALETTE: sstate_next = SS_DONE;
	SS_PALETTE2: sstate_next = SS_DONE;
	SS_FONT: sstate_next = SS_DONE;
	SS_DONE: sstate_next = SS_IDLE;
      endcase
    end

  textdrv #(.BPP(BPP)) textdriver0(.clk_i(vga_clock28),
				   .rst_i(rst_i),
				   .blank_n(blank28_n),
				   .red(td_r),
				   .green(td_g),
				   .blue(td_b),
				   .vs(vs28),
				   .hs(hs28),
				   .cursorpos(cursorpos),
				   .cursormode(setupreg[7:4]),
				   .cursorcolor(cursorcolor),
				   .bus(textbus.master));
  
  gm_mono graphicsdriver0(.clk_i(vga_clock25),
			  .rst_i(rst_i),
			  .vs(vs25),
			  .hs(hs25),
			  .blank_n(blank25_n),
			  .red(gm_mono_r),
			  .green(gm_mono_g),
			  .blue(gm_mono_b),
			  .bus(gm_monobus.master));

  
endmodule
