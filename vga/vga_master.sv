`include "../wb.vh"

parameter VGA_MEMBASE = 34'h0c0000000;

module vga_master
  #(VGA_MEMBASE = 32'hc0000000)
  (
   input 	     clk_i,
   input 	     rst_i,
   if_wb.slave       inbus,
   if_wb.master      outbus,
   output 	     vs,
   output 	     hs,
   output [7:0]      r,
   output [7:0]      g,
   output [7:0]      b,
   output 	     blank_n,
   output 	     sync_n,
   input 	     vga_clock);

// Configuration registers
// 0x000 - palette memory 1
// 0x400 - palette memory 2
// 0x800 - font memory 1
// 0xc00 - video memory base address
// 0xc01 - video mode, palette select

  logic [31:0] 	     bus_dat_o, bus_dat_i;

`ifdef NO_MODPORT_EXPRESSIONS
  assign bus_dat_i = bus.dat_m;
  assign bus.dat_s = bus_dat_o;
`else
  assign bus_dat_i = bus.dat_i;
  assign bus.dat_o = bus_dat_o;
`endif

  typedef enum 	     bit [2:0] { SS_IDLE, SS_PALETTE, 
				 SS_PALETTE2, SS_FONT, SS_DONE } sstate_t;
  
  logic 	     sstate_t sstate, sstate_next;
  logic [31:0] 	     setupreg, setupreg_next,
		     vgabase, vgabase_next,
		     cursorpos, cursorpos_next;
  logic [31:0] 	     slave_dat_o_next;
  
  logic [7:0] 	     gd_r, gd_g, gd_b, td_r, td_g, td_b;
  logic 	     gd_cyc_o, td_cyc_o;
  logic [31:0] 	     gd_adr_o, td_adr_o;
  logic [15:0] 	     x_raw, y_raw;

assign master_dat_o = 32'h0;
assign slave_ack_o = (sstate == SSTATE_DONE);
assign master_we_o = 1'b0;
assign master_sel_o = 4'hf;
assign master_cyc_o = td_cyc_o;
assign master_stb_o = master_cyc_o;
assign master_adr_o = vgabase + td_adr_o;
assign r = td_r;
assign g = td_g;
assign b = td_b;

assign sync_n = 1'b0;

// Slave state machine
always @(posedge clk_i or posedge rst_i)
begin
  if (rst_i) begin
    vgabase <= VGA_MEMBASE[32:0];
    setupreg <= 32'h02;
    slave_dat_o <= 32'h0;
	 cursorpos <= 32'h0;
    sstate <= SSTATE_IDLE;
  end else begin
    vgabase <= vgabase_next;
    setupreg <= setupreg_next;
    slave_dat_o <= slave_dat_o_next;
	 cursorpos <= cursorpos_next;
    sstate <= sstate_next;
  end
end

always @*
begin
  sstate_next = sstate;
  setupreg_next = setupreg;
  vgabase_next = vgabase;
  cursorpos_next = cursorpos;
  slave_dat_o_next = slave_dat_o;
  
  case (sstate)
    SSTATE_IDLE:
      if (slave_cyc_i & slave_stb_i)
        case (slave_adr_i[9:8])
          2'h0: sstate_next = SSTATE_PALETTE;
          2'h1: sstate_next = SSTATE_PALETTE2;
          2'h2: sstate_next = SSTATE_FONT;
          2'h3: begin
            case (slave_adr_i[7:0])
              8'h0: begin // c00 - vga base
                if (slave_we_i) begin
                  if (slave_sel_i[3])
                    vgabase_next[31:24] = slave_dat_i[31:24];
                  if (slave_sel_i[2])
                    vgabase_next[23:16] = slave_dat_i[23:16];
                  if (slave_sel_i[1])
                    vgabase_next[15:8] = slave_dat_i[15:8];
                  if (slave_sel_i[0])
                    vgabase_next[7:0] = slave_dat_i[7:0];
                end else
                  slave_dat_o_next = vgabase;
              end
              8'h1: begin // c01 - graphics mode / cursor mode
                if (slave_we_i) begin
                  if (slave_sel_i[3])
                    setupreg_next[31:24] = slave_dat_i[31:24];
                  if (slave_sel_i[2])
                    setupreg_next[23:16] = slave_dat_i[23:16];
                  if (slave_sel_i[1])
                    setupreg_next[15:8] = slave_dat_i[15:8];
                  if (slave_sel_i[0])
                    setupreg_next[7:0] = slave_dat_i[7:0];
                end else
                  slave_dat_o_next = setupreg;
              end
				  8'h2: begin // c02 - cursor position
				    if (slave_we_i) begin
                    cursorpos_next[31:24] = slave_dat_i[31:24];
                  if (slave_sel_i[2])
                    cursorpos_next[23:16] = slave_dat_i[23:16];
                  if (slave_sel_i[1])
                    cursorpos_next[15:8] = slave_dat_i[15:8];
                  if (slave_sel_i[0])
                    cursorpos_next[7:0] = slave_dat_i[7:0];
                end else
                  slave_dat_o_next = cursorpos;
				  end
              default: begin
                if (~slave_we_i)
                  slave_dat_o_next = 32'h0;
              end
            endcase
            sstate_next = SSTATE_DONE;
          end
          default: sstate_next = SSTATE_DONE;
        endcase
    SSTATE_PALETTE: sstate_next = SSTATE_DONE;
    SSTATE_PALETTE2: sstate_next = SSTATE_DONE;
    SSTATE_FONT: sstate_next = SSTATE_DONE;
    SSTATE_DONE: sstate_next = SSTATE_IDLE;
  endcase
end

textdrv textdriver0(.clk_i(clk_i), .rst_i(rst_i), .x(x_raw), .y(y_raw),
  .r(td_r), .g(td_g), .b(td_b), .cyc_o(td_cyc_o), .cursorpos(cursorpos), .cursormode(setupreg[7:4]),
  .ack_i(master_ack_i), .adr_o(td_adr_o), .dat_i(master_dat_i), .vga_clock(vga_clock));

vga_controller vga0(.active(blank_n), .vs(vs), .hs(hs), .clock(vga_clock), .reset_n(~rst_i), .x(x_raw), .y(y_raw));

endmodule
