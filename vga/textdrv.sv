`include "../wb.vh"

// This module runs on the vga dot clock.
// We rely on the memory interface to synchronize things.

module textdrv
  #(BPP = 8)
  (
   input 	    clk_i,
   input 	    rst_i,
   input 	    video_clk_i,
   input 	    video_rst_i,
   input [31:0]     cursorpos,
   input [3:0] 	    cursormode,
   input [23:0]     cursorcolor,
   output 	    blank_n,
   output 	    vs,
   output 	    hs,
   output [BPP-1:0] red,
   output [BPP-1:0] green,
   output [BPP-1:0] blue,
   if_wb.master     bus);

  logic [31:0] 	    bus_dat_i, bus_dat_o;

`ifdef NO_MODPORT_EXPRESSIONS
  assign bus_dat_i = bus.dat_s;
  assign bus.dat_m = bus_dat_o;
`else
  assign bus_dat_i = bus.dat_i;
  assign bus.dat_o = bus_dat_o;
`endif

  /* This module is dual clocked - there's the CPU and memory clock on one
   * side, and then the VGA clock on the other.  We need to deal with crossing
   * domains in both directions.  To keep the code as clean as possible, we'll
   * start with the CPU side where we load the local buffer, and then use a
   * different block below that for the VGA and rendering side.
   * 
   * For this video mode, we use two bytes per character, which for a
   * 720x400, 80x25 char screen means 80 char/line / 2 char/word = 40 words
   * per line, and each word will "fill" 18 pixels.  We pipeline the load of
   * the words as well as the font lookup before the fifo so that the VGA
   * clocking can happen as quickly as possible.
   * 
   * The fifo is 2(24 bits + 9 pixels) = 66 bits wide.
   */

  typedef enum 	bit [1:0] { S_IDLE, S_BUS, S_ACK_WAIT, S_FAULT } state_t;
  
  state_t      state, state_next;
  logic [7:0]  idx, idx_next;
  logic [7:0]  ack_count, ack_count_next;
  logic [31:0] rowval, rowval_next;
  logic [2:0]  cpu_ha_sync, cpu_va_sync;
  logic        cpu_ha_falling, cpu_va_rising;
  logic        start_load;
  logic [3:0]  y, y_next;
  logic [11:0] page_count, page_count_next;
  
  assign start_load = cpu_ha_falling && cpu_va_sync[1:0] == 2'b11;
  assign cpu_ha_falling = cpu_ha_sync[1:0] == 2'b01;
  assign cpu_va_rising = cpu_va_sync[1:0] == 2'b10;
  assign bus.cyc = (state == S_BUS || state == S_ACK_WAIT);
  assign bus.stb = (state == S_BUS);
  assign bus.adr = rowval + { idx, 2'h0 };
  assign bus_dat_o = { 20'h0, page_count };
  assign bus.we = 1'h0;
  assign bus.sel = 4'hf;

  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  state <= S_IDLE;
	  idx <= 8'h0;
	  rowval <= 32'h0;
	  cpu_ha_sync <= 3'h0;
	  cpu_va_sync <= 3'h0;
	  ack_count <= 8'h0;
	  y <= 4'h0;
	  page_count <= 12'h0;
	end
      else
	begin
	  idx <= idx_next;
	  state <= state_next;
	  rowval <= rowval_next;
	  cpu_ha_sync <= { h_active, cpu_ha_sync[2], cpu_ha_sync[1] };
	  cpu_va_sync <= { v_active, cpu_va_sync[2], cpu_va_sync[1] };
	  ack_count <= ack_count_next;
	  y <= y_next;
	  page_count <= page_count_next;
	end
    end

  always_comb
    begin
      state_next = state;
      idx_next = idx;
      rowval_next = rowval;
      ack_count_next = ack_count;
      y_next = y;
      page_count_next = page_count;
      
      if (cpu_va_rising)
	begin
	  y_next = 4'h0;
	  rowval_next = 16'h0;
	  if (state != S_FAULT)
	    page_count_next = page_count + 12'h1;
	end
      
      case (state)
	S_IDLE:
	  begin
	    if (start_load)
	      begin
		state_next = S_BUS;
		ack_count_next = 8'h0;
	      end
	  end
	S_BUS:
	  begin
	    idx_next = idx + 8'd1;
	    if (idx == 8'd39)
	      begin
		state_next = S_ACK_WAIT;
	      end
	    if (bus.ack)
	      begin
		ack_count_next = ack_count + 8'h1;
	      end
	  end
	S_ACK_WAIT:
	  begin
	    if (ack_count == 8'd39)
	      begin
		idx_next = 8'd0;
		y_next = y + 4'h1;
		rowval_next = (y == 4'hf ? rowval + 10'ha0 : rowval);
		state_next = (fifo_full ? S_FAULT : S_IDLE);
	      end
	    if (bus.ack)
	      begin
		ack_count_next = ack_count + 8'h1;
	      end
	  end // case: S_ACK_WAIT
	S_FAULT:
	  begin
	  end
      endcase
    end

  // Fonts
  logic [7:0]     rgb0, rgb1, rgb0_buf, rgb1_buf;
  logic 	  fifo_write, fifo_full;
  logic [63:0] 	  fifo_in, fifo_in_next, fifo_buf;
  logic [127:0]   font0_out_next, font1_out_next;
  logic [127:0]   font0_out, font1_out;
  logic [6:0] 	  font0_adr, font1_adr;
  
  logic [3:0]	  ack_delay;
  
  dualrom 
    #(.AWIDTH(7),
      .INITNAME("../../fpgalib/vga/font9x16.mif"),
      .DWIDTH(128)) fontmem(.clk_i(clk_i),
			    .rst_i(rst_i),
			    .bus0_adr(font0_adr),
			    .bus0_data(font0_out),
			    .bus1_adr(font1_adr),
			    .bus1_data(font1_out));


  always_ff @(posedge clk_i)
    begin
      font0_adr <= bus_dat_i[22:16]; // 1
      font1_adr <= bus_dat_i[6:0];
      rgb0 <= rgb0_buf; // 2
      rgb1 <= rgb1_buf;
      rgb0_buf <= bus_dat_i[31:24]; // 1
      rgb1_buf <= bus_dat_i[15:8];
      ack_delay <= { bus.ack, ack_delay[3:1] }; // 1,2,3
      fifo_buf <= fifo_in_next;
      fifo_in <= fifo_buf;
    end
  
  assign fifo_write = ack_delay[0] && !fifo_full;

  // select the font line we care about
  // pull the colors out of the fb
  always_comb
    begin

      case (y[3:0])
	'hf: fifo_in_next = { rgb0, font0_out[7:0], rgb1, font1_out[7:0] };
	'he: fifo_in_next = { rgb0, font0_out[15:8], rgb1, font1_out[15:8] };
	'hd: fifo_in_next = { rgb0, font0_out[23:16], rgb1, font1_out[23:16] };
	'hc: fifo_in_next = { rgb0, font0_out[31:24], rgb1, font1_out[31:24] };
	'hb: fifo_in_next = { rgb0, font0_out[39:32], rgb1, font1_out[39:32] };
	'ha: fifo_in_next = { rgb0, font0_out[47:40], rgb1, font1_out[47:40] };
	'h9: fifo_in_next = { rgb0, font0_out[55:48], rgb1, font1_out[55:48] };
	'h8: fifo_in_next = { rgb0, font0_out[63:56], rgb1, font1_out[63:56] };
	'h7: fifo_in_next = { rgb0, font0_out[71:64], rgb1, font1_out[71:64] };
	'h6: fifo_in_next = { rgb0, font0_out[79:72], rgb1, font1_out[79:72] };
	'h5: fifo_in_next = { rgb0, font0_out[87:80], rgb1, font1_out[87:80] };
	'h4: fifo_in_next = { rgb0, font0_out[95:88], rgb1, font1_out[95:88] };
	'h3: fifo_in_next = { rgb0, font0_out[103:96], rgb1, font1_out[103:96] };
	'h2: fifo_in_next = { rgb0, font0_out[111:104], rgb1, font1_out[111:104] };
	'h1: fifo_in_next = { rgb0, font0_out[119:112], rgb1, font1_out[119:112] };
	'h0: fifo_in_next = { rgb0, font0_out[127:120], rgb1, font1_out[127:120] };
      endcase
    end
  
  // The fifo that spans the two clock domains
  dualfifo
    #(.AWIDTH(6), .DWIDTH(32))
    fifo0(.wclk_i(clk_i),
	  .wrst_i(rst_i),
	  .rclk_i(video_clk_i),
	  .rrst_i(video_rst_i),
	  .write(fifo_write),
	  .wfull(fifo_full),
	  .rempty(fifo_empty),
	  .read(fifo_read),
	  .in(fifo_in),
	  .out(fifo_out));
  
  // Now the VGA clocked logic
  logic [4:0]  x, x_next;
  logic        v_active, h_active;
  logic [31:0] fifo_out;
  logic        fifo_read, fifo_empty;
  logic [23:0] color0, color1;
  logic [7:0]  pcolor0, pcolor1;
  logic [7:0]  char0, char1;
  
  assign { pcolor0, char0, pcolor1, char1 } = fifo_out;
  assign blank_n = v_active & h_active;

  assign color0 = { pcolor0[7:6], 6'h0, 
		    pcolor0[5:3], 5'h0,
		    pcolor0[2:0], 5'h0 };
  assign color1 = { pcolor1[7:6], 6'h0, 
		    pcolor1[5:3], 5'h0,
		    pcolor1[2:0], 5'h0 };
  
  always_ff @(posedge video_clk_i)
    begin
      x <= (h_active ? x_next : 5'h0);
    end
  
  always_comb
    begin
      x_next = (h_active && !fifo_empty ? x + 5'h1 : 5'h0);
      fifo_read = 1'h0;

      { red, green, blue } = 24'h0;
      
      if (x < 5'd8)
	begin
	  { red, green, blue } = (char0[5'd7-x] ? color0 : 24'h0);
	end
      else
	begin
	  if (x > 5'd8 && x < 5'd17)
	    { red, green, blue } = (char1[5'd7-(x-9)] ? color1 : 24'h0);
	end

      if (v_active && x == 5'd17)
	begin
	  x_next = 5'h0;
	  fifo_read = 1'h1;
	end
    end

  vga_controller28 vga1(.vs(vs),
			.hs(hs),
			.v_active(v_active),
			.h_active(h_active),
			.clock(video_clk_i),
			.rst_i(video_rst_i));
  
endmodule
