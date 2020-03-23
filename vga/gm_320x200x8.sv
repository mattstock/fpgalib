`include "../wb.vh"

module gm_320x200x8
  #(BPP = 8)
  (
   input 	    clk_i,
   input 	    rst_i,
   input 	    video_clk_i,
   input 	    video_rst_i,
   input 	    color,
   output 	    vs,
   output 	    hs,
   output 	    blank_n, 
   output [BPP-1:0] red,
   output [BPP-1:0] green,
   output [BPP-1:0] blue,
		    if_wb.master bus,
		    if_wb.slave palette_bus);

  logic [31:0] 	palette_bus_dat_i, palette_bus_dat_o;
  logic [31:0] 	bus_dat_i, bus_dat_o;
`ifdef NO_MODPORT_EXPRESSIONS
  assign bus_dat_i = bus.dat_s;
  assign bus.dat_m = bus_dat_o;
  assign palette_bus_dat_i = palette_bus.dat_m;
  assign palette_bus.dat_s = palette_bus_dat_o;
`else
  assign bus_dat_i = bus.dat_i;
  assign bus.dat_o = bus_dat_o;
  assign palette_bus_dat_i = palette_bus.dat_i;
  assign palette_bus.dat_o = palette_bus_dat_o;
`endif

  assign palette_bus.stall = 1'h0;
  assign palette_bus_dat_o = 32'h0;
  assign palette_bus.ack = 1'h0; // we don't really pay attention
  
  /* This module is dual clocked - there's the CPU and memory clock on one
   * side, and then the VGA clock on the other.  We need to deal with crossing
   * domains in both directions.  To keep the code as clean as possible, we'll
   * start with the CPU side where we load the local buffer, and then use a
   * different block below that for the VGA and rendering side.
   * 
   * For this graphics mode, we use one byte per pixel, which requires a total
   * of 80 32-bit words per line.  We pipeline the load of the words as well
   * as the palette lookup before the fifo so that the VGA clocking can
   * happen as quickly as possible.
   * 
   * The fifo is 24-bits * 4 pixels = 96 bits wide. 
   */
  
  typedef enum 	bit [1:0] { S_IDLE, S_BUS, S_ACK_WAIT } state_t;
  
  state_t      state, state_next;
  logic [7:0]  idx, idx_next;
  logic [7:0]  ack_count, ack_count_next;
  logic [31:0] rowval, rowval_next;
  logic [4:0]  cpu_ha_sync, cpu_va_sync;
  logic        cpu_ha_falling, cpu_va_rising;
  logic        start_load, toggle, toggle_next;
  
  assign start_load = cpu_ha_falling && cpu_va_sync[3:0] == 4'b1111;
  assign cpu_ha_falling = cpu_ha_sync[3:0] == 4'b0011;
  assign cpu_va_rising = cpu_va_sync[3:0] == 4'b1100;
  assign bus.cyc = (state == S_BUS || state == S_ACK_WAIT);
  assign bus.stb = (state == S_BUS);
  assign bus.adr = rowval + { idx, 2'h0 };
  assign bus_dat_o = 32'h0;
  assign bus.we = 1'h0;
  assign bus.sel = 4'hf;

  always_ff @(posedge clk_i)
    begin
      if (rst_i)
	begin
	  state <= S_IDLE;
	  idx <= 8'h0;
	  rowval <= 32'h0;
	  cpu_ha_sync <= 5'h0;
	  cpu_va_sync <= 5'h0;
	  ack_count <= 8'h0;
	  toggle <= 1'h0;
	end
      else
	begin
	  idx <= idx_next;
	  state <= state_next;
	  rowval <= rowval_next;
	  cpu_ha_sync <= { h_active, cpu_ha_sync[4:1] };
	  cpu_va_sync <= { v_active, cpu_va_sync[4:1] };
	  ack_count <= ack_count_next;
	  toggle <= toggle_next;
	end
    end

  always_comb
    begin
      toggle_next = toggle;
      state_next = state;
      idx_next = idx;
      rowval_next = rowval;
      ack_count_next = ack_count;
      
      if (cpu_va_rising)
	begin
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
	    idx_next = idx + 8'h1;
	    if (idx == 8'h4f)
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
	    if (ack_count == 8'h4f)
	      begin
		idx_next = 8'h0;
		toggle_next = ~toggle;
		rowval_next = (toggle ? rowval + 10'h140 : rowval);
		state_next = S_IDLE;
	      end
	    if (bus.ack)
	      begin
		ack_count_next = ack_count + 8'h1;
	      end
	  end
      endcase
    end

  /* Palette logic (CPU side)
   * Basic logic is to allow the palette bus to change these registers in
   * parallel (4 copies), and for the read addresses be the elements of the
   * input framebuffer bus.
   */
  logic        fifo_write, fifo_full;
  logic [95:0] fifo_in;
  
  assign fifo_write = bus.ack && !fifo_full;

  // Allow us to use the palette or to switch to grayscale.
  assign fifo_in = (color ?
		    { palette0[bus_dat_i[31:24]],
		      palette1[bus_dat_i[23:16]],
		      palette2[bus_dat_i[15:8]],
		      palette3[bus_dat_i[7:0]] } :
		    { {3{bus_dat_i[31:24]}},
		      {3{bus_dat_i[23:16]}},
		      {3{bus_dat_i[15:8]}},
		      {3{bus_dat_i[7:0]}} } );
		    
  logic [23:0] palette0[255:0],
	       palette1[255:0],
	       palette2[255:0],
	       palette3[255:0];

  always_ff @(posedge clk_i)
    begin
      if (palette_bus.cyc && palette_bus.stb && palette_bus.we)
	begin // add sel to this
	  if (palette_bus.sel[2])
	    begin
	      palette0[palette_bus.adr[9:2]][23:16] <= palette_bus_dat_i[23:16];
	      palette1[palette_bus.adr[9:2]][23:16] <= palette_bus_dat_i[23:16];
	      palette2[palette_bus.adr[9:2]][23:16] <= palette_bus_dat_i[23:16];
	      palette3[palette_bus.adr[9:2]][23:16] <= palette_bus_dat_i[23:16];
	    end
	  if (palette_bus.sel[1])
	    begin
	      palette0[palette_bus.adr[9:2]][15:8] <= palette_bus_dat_i[15:8];
	      palette1[palette_bus.adr[9:2]][15:8] <= palette_bus_dat_i[15:8];
	      palette2[palette_bus.adr[9:2]][15:8] <= palette_bus_dat_i[15:8];
	      palette3[palette_bus.adr[9:2]][15:8] <= palette_bus_dat_i[15:8];
	    end
	  if (palette_bus.sel[0])
	    begin
	      palette0[palette_bus.adr[9:2]][7:0] <= palette_bus_dat_i[7:0];
	      palette1[palette_bus.adr[9:2]][7:0] <= palette_bus_dat_i[7:0];
	      palette2[palette_bus.adr[9:2]][7:0] <= palette_bus_dat_i[7:0];
	      palette3[palette_bus.adr[9:2]][7:0] <= palette_bus_dat_i[7:0];
	    end
	end // if (palette_bus.cyc && palette_bus.stb && palette_bus.we)
    end // always_ff @ (posedge clk_i)
  
  // The fifo that spans the two clock domains
  dualfifo
    #(.AWIDTH(9), .DWIDTH(96))
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
  logic [2:0]  x, x_next;
  logic        v_active, h_active;
  logic [95:0] fifo_out;
  logic        fifo_read, fifo_empty;
  
  assign blank_n = v_active & h_active;

  always_ff @(posedge video_clk_i)
    begin
      x <= (h_active ? x_next : 3'h0);
    end
  
  always_comb
    begin
      x_next = (h_active && !fifo_empty ? x + 3'h1 : 3'h0);
      fifo_read = 1'h0;

      case (x[2:1])
	2'h0: { red, green, blue } = fifo_out[95:72];
	2'h1: { red, green, blue } = fifo_out[71:48];
	2'h2: { red, green, blue } = fifo_out[47:24];
	2'h3: { red, green, blue } = fifo_out[23:0];
      endcase

      if (h_active && v_active && x == 3'h7)
	begin
	  fifo_read = 1'h1;
	end
    end

  vga_controller25 vga13h(.v_active(v_active),
			  .h_active(h_active),
			  .vs(vs),
			  .hs(hs),
			  .clock(video_clk_i),
			  .rst_i(video_rst_i));

endmodule
