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

  typedef enum 	bit [1:0] { S_IDLE, S_BUS, S_ACK_WAIT } state_t;
  
  state_t      state, state_next;
  logic [7:0]  idx, idx_next;
  logic [7:0]  ack_count, ack_count_next;
  logic [31:0] rowval, rowval_next;
  logic [2:0]  cpu_ha_sync, cpu_va_sync;
  logic        cpu_ha_falling, cpu_va_rising;
  logic        start_load;
  logic [3:0]  y, y_next;
  
  assign start_load = cpu_ha_falling && cpu_va_sync[1:0] == 2'b11;
  assign cpu_ha_falling = cpu_ha_sync[1:0] == 2'b01;
  assign cpu_va_rising = cpu_va_sync[1:0] == 2'b10;
  assign bus.cyc = (state == S_BUS || state == S_ACK_WAIT);
  assign bus.stb = (state == S_BUS);
  assign bus.adr = rowval + { idx, 2'h0 };
  assign bus_dat_o = 32'h0;
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
	end
    end

  always_comb
    begin
      state_next = state;
      idx_next = idx;
      rowval_next = rowval;
      ack_count_next = ack_count;
      y_next = y;
      
      if (cpu_va_rising)
	begin
	  y_next = 4'h0;
	  rowval_next = 16'h0;
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
		state_next = S_IDLE;
	      end
	    if (bus.ack)
	      begin
		ack_count_next = ack_count + 8'h1;
	      end
	  end
      endcase
    end

  // Fonts
  logic [BPP-1:0] r1, g1, b1, r2, g2, b2;
  logic 	  fifo_write, fifo_full;
  logic [63:0] 	  fifo_in;

  assign fifo_write = bus.ack && !fifo_full;

  dualrom 
    #(.AWIDTH(7),
      .INITNAME("../../fpgalib/vga/font9x16.mif"),
      .DWIDTH(128)) fontmem(.clk_i(clk_i),
			    .rst_i(rst_i),
			    .bus0_adr(bus_dat_i[22:16]),
			    .bus0_data(font0_out),
			    .bus1_adr(bus_dat_i[6:0]),
			    .bus1_data(font1_out));


  // pull the colors out of the fb
  always_comb
    begin
      r1 = { bus_dat_i[31:30], 6'h0 };
      g1 = { bus_dat_i[29:27], 5'h0 };
      b1 = { bus_dat_i[26:24], 5'h0 };
      r2 = { bus_dat_i[15:14], 6'h0 };
      g2 = { bus_dat_i[13:11], 5'h0 };
      b2 = { bus_dat_i[10:8], 5'h0 };

      fifo_in = { r1, g1, b1, ack_count, r2, g2, b2, 8'hff };
    end
  
  // The fifo that spans the two clock domains
  dualfifo
    #(.AWIDTH(6), .DWIDTH(64))
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
  logic [63:0] fifo_out;
  logic        fifo_read, fifo_empty;
  
  assign blank_n = v_active & h_active;

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
	  { red, green, blue } = fifo_out[63:40];
	end
      else
	begin
	  if (x > 5'd8 && x < 5'd17)
	    { red, green, blue } = fifo_out[31:8];
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
