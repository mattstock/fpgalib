`include "../wb.vh"

module gm_640x480x1
  #(BPP = 8)
  (
   input 	    clk_i,
   input 	    rst_i,
   input 	    video_clk_i,
   input            video_rst_i,
   output 	    vs,
   output 	    hs,
   output 	    blank_n, 
   output [BPP-1:0] red,
   output [BPP-1:0] green,
   output [BPP-1:0] blue,
   if_wb.master     bus);

  logic [31:0] 	bus_dat_i, bus_dat_o;
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
   * For this graphics mode, we use one bit per pixel, meaning that we
   * need to load in 20 32-bit words per line.  We trigger the load from
   * memory when we're in the active vertical window and we see the end of
   * the horizontal window.  We want to start loading data as quickly as we
   * can, since in the current work, the CPU clock is running at less than
   * half the speed of the VGA clock.
   */
  
  typedef enum 	bit [1:0] { S_IDLE, S_BUS, S_ACK_WAIT } state_t;
  
  state_t      state, state_next;
  logic [4:0]  idx, idx_next;
  logic [31:0] rowval, rowval_next;
  logic [4:0]  cpu_ha_sync, cpu_va_sync;
  logic        cpu_ha_falling, cpu_va_rising;
  logic [31:0] fifo_out;
  logic        fifo_read;
  logic [4:0]  ack_count, ack_count_next;
  logic        start_load;

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
	  idx <= 5'h0;
	  rowval <= 32'h0;
	  cpu_ha_sync <= 5'h0;
	  cpu_va_sync <= 5'h0;
	  ack_count <= 5'h0;
	end
      else
	begin
	  idx <= idx_next;
	  state <= state_next;
	  rowval <= rowval_next;
	  cpu_ha_sync <= { h_active, cpu_ha_sync[4:1] };
	  cpu_va_sync <= { v_active, cpu_va_sync[4:1] };
	  ack_count <= ack_count_next;
	end
    end

  always_comb
    begin
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
		ack_count_next = 5'h0;
	      end
	  end
	S_BUS:
	  begin
	    idx_next = idx + 5'd1;
	    if (idx == 5'd19) // 32 pixels per word, 20 words per line
	      begin
		state_next = S_ACK_WAIT;
	      end
	    if (bus.ack)
	      begin
		ack_count_next = ack_count + 5'h1;
	      end
	  end
	S_ACK_WAIT:
	  begin
	    if (ack_count == 5'd19)
	      begin
		idx_next = 5'd0;
		rowval_next = rowval + 7'h50;
		state_next = S_IDLE;
	      end
	    if (bus.ack)
	      begin
		ack_count_next = ack_count + 5'h1;
	      end
	  end
      endcase
    end

  /* Now the VGA clocked logic */
  logic [4:0]  x, x_next;
  logic        v_active, h_active;
  
  assign blank_n = v_active & h_active;

  always_ff @(posedge video_clk_i)
    begin
      x <= (h_active ? x_next : 5'h0);
    end
  
  always_comb
    begin
      x_next = (h_active ? x + 5'h1 : 5'h0);
      fifo_read = 1'h0;

      { red, green, blue } = (fifo_out[5'h1f-x] ? 24'hffffff : 24'h0);

      if (h_active && v_active && x == 5'h1f)
	begin
	  fifo_read = 1'h1;
	end
    end

  dualfifo
    #(.AWIDTH(5))
    fifo0(.wclk_i(clk_i),
	  .wrst_i(rst_i),
	  .rclk_i(video_clk_i),
	  .rrst_i(video_rst_i),
	  .write(bus.cyc && bus.ack),
	  .read(fifo_read),
	  .in(bus_dat_i),
	  .out(fifo_out));
  
  vga_controller25 vga13h(.v_active(v_active),
			  .h_active(h_active),
			  .vs(vs),
			  .hs(hs),
			  .clock(video_clk_i),
			  .rst_i(video_rst_i));

endmodule
