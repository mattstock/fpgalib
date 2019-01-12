`include "../wb.vh"

module vga_master
  #(VGA_MEMBASE = 32'h0,
    BPP = 8)
  (
   input 	    clk_i,
   input 	    rst_i,
   if_wb.slave      inbus,
   if_wb.master     outbus,
   output 	    vs,
   output 	    hs,
   output [BPP-1:0] r,
   output [BPP-1:0] g,
   output [BPP-1:0] b,
   output 	    blank_n,
   output 	    sync_n,
   input 	    vga_clock);

  // Configuration registers
  // 0x000 - palette memory 1
  // 0x400 - palette memory 2
  // 0x800 - font memory 1
  // 0xc00 - video memory base address
  // 0xc01 - video mode, palette select
  
  logic [31:0] 	    inbus_dat_o, inbus_dat_i;
  logic [31:0] 	    outbus_dat_o, outbus_dat_i;
  
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
  
  logic [BPP-1:0]   gd_r, gd_g, gd_b, td_r, td_g, td_b;
  logic 	    gd_cyc_o, td_cyc_o;
  logic [31:0] 	    gd_adr_o, td_adr_o;
  logic [15:0] 	    x_raw, y_raw;
  
  assign outbus_dat_o = 32'h0;
  assign inbus.ack = (sstate == SS_DONE);
  assign inbus.stall = 1'h0;

  assign outbus.we = 1'b0;
  assign outbus.sel = 4'hf;
  assign outbus.cyc = td_cyc_o;
  assign outbus.stb = outbus.cyc;
  assign outbus.adr = vgabase + td_adr_o;
  assign r = td_r;
  assign g = td_g;
  assign b = td_b;
  
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
	  sstate <= SS_IDLE;
	end
      else
	begin
	  vgabase <= vgabase_next;
	  setupreg <= setupreg_next;
	  inbus_dat_o <= inbus_dat_o_next;
	  cursorpos <= cursorpos_next;
	  sstate <= sstate_next;
	end
    end
  
  always_comb
    begin
      sstate_next = sstate;
      setupreg_next = setupreg;
      vgabase_next = vgabase;
      cursorpos_next = cursorpos;
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
  
  textdrv #(.BPP(BPP)) textdriver0(.clk_i(clk_i),
				   .rst_i(rst_i),
				   .x(x_raw),
				   .y(y_raw),
				   .r(td_r),
				   .g(td_g),
				   .b(td_b),
				   .cyc_o(td_cyc_o),
				   .cursorpos(cursorpos),
				   .cursormode(setupreg[7:4]),
				   .ack_i(outbus.ack),
				   .adr_o(td_adr_o),
				   .dat_i(outbus_dat_i),
				   .vga_clock(vga_clock));
  
  vga_controller vga0(.active(blank_n),
		      .vs(vs),
		      .hs(hs),
		      .clock(vga_clock),
		      .reset_n(~rst_i),
		      .x(x_raw),
		      .y(y_raw));
  
endmodule
