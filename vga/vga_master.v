module vga_avalon(
  input csi_clk,
  input csi_vga_clk,
  output reg cso_vga_clk,
  input rsi_reset,
  input avs_s0_write,
  input avs_s0_read,
  input [3:0] avs_s0_byteenable,
  input [31:0] avs_s0_writedata,
  output [31:0] avs_s0_readdata,
  input [9:0] avs_s0_address,
  output avs_s0_waitrequest_n,
  output [31:0] avm_m0_address,
  output reg avm_m0_write,
  output reg avm_m0_read,
  output [31:0] avm_m0_writedata,
  input [31:0] avm_m0_readdata,
  output [3:0] avm_m0_byteenable,
  input avm_m0_waitrequest_n,
  output coe_vs,
  output coe_hs,
  output [7:0] coe_r,
  output [7:0] coe_g,
  output [7:0] coe_b,
  output coe_sync_n,
  output coe_blank_n
);

parameter VGA_MEMBASE = 34'h0c0000000;

reg stb_o, we_o, cyc_o;

always cso_vga_clk = csi_vga_clk;
always avm_m0_read = stb_o & cyc_o & !we_o;
always avm_m0_write = stb_o & cyc_o & we_o;

vga_master #(.VGA_MEMBASE(VGA_MEMBASE)) vga0(.clk_i(csi_clk), .rst_i(rsi_reset), .slave_we_i(avs_s0_write & !avs_s0_read), .slave_dat_i(avs_s0_writedata),
  .slave_adr_i(avs_s0_address), .slave_dat_o(avs_s0_readdata), .slave_cyc_i(avs_s0_read|avs_s0_write),
  .slave_stb_i(avs_s0_read|avs_s0_write), .slave_sel_i(avs_s0_byteenable), .slave_ack_o(avs_s0_waitrequest_n),
  .master_adr_o(avm_m0_address), .master_cyc_o(cyc_o), .master_dat_i(avm_m0_readdata), .master_sel_o(avm_m0_byteenable),
  .master_ack_i(avm_m0_waitrequest_n), .master_we_o(we_o), .master_stb_o(stb_o), .vga_clock(csi_vga_clk), .master_dat_o(avm_m0_writedata),
  .vs(coe_vs), .hs(coe_hs), .r(coe_r), .g(coe_g), .b(coe_b), .blank_n(coe_blank_n), .sync_n(coe_sync_n)); 

endmodule

module vga_master(
  input clk_i,
  input rst_i,
  output [31:0] master_adr_o,
  output master_cyc_o,
  input [31:0] master_dat_i,
  output master_we_o,
  output [31:0] master_dat_o,
  output [3:0] master_sel_o,
  input master_ack_i,
  output master_stb_o,
  input [9:0] slave_adr_i,
  input [31:0] slave_dat_i,
  output reg [31:0] slave_dat_o,
  input slave_cyc_i,
  input slave_we_i,
  input [3:0] slave_sel_i,
  output slave_ack_o,
  input slave_stb_i,
  output vs,
  output hs,
  output [7:0] r,
  output [7:0] g,
  output [7:0] b,
  output blank_n,
  output sync_n,
  input vga_clock);

// Configuration registers
// 0x000 - palette memory 1
// 0x400 - palette memory 2
// 0x800 - font memory 1
// 0xc00 - video memory base address
// 0xc01 - video mode, palette select

parameter VGA_MEMBASE = 34'h0c0000000;

localparam [2:0] SSTATE_IDLE = 3'h0, SSTATE_PALETTE = 3'h1, SSTATE_PALETTE2 = 3'h2, SSTATE_FONT = 3'h3, SSTATE_DONE = 3'h4;

reg [2:0] sstate, sstate_next;
reg [31:0] setupreg, setupreg_next, vgabase, vgabase_next, cursorpos, cursorpos_next;
reg [31:0] slave_dat_o_next;

wire [7:0] gd_r, gd_g, gd_b, td_r, td_g, td_b;
wire gd_cyc_o, td_cyc_o;
wire [31:0] gd_adr_o, td_adr_o;
wire [15:0] x_raw, y_raw;

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
