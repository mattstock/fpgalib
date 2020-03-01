`include "../wb.vh"

module gm_mono
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
   */
  
  typedef enum 	bit [2:0] { S_IDLE, S_BUS, S_STORE, S_ACK_WAIT } state_t;
  
  state_t      state, state_next;
  logic [4:0]  idx, idx_next;
  logic [31:0] rowval, rowval_next;
  logic [2:0]  cpu_ha_sync, cpu_va_sync;
  logic        cpu_ha_falling, cpu_va_rising;
  logic [31:0] fifo_in, fifo_in_next, fifo_out;
  logic        fifo_read;

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
	  idx <= 5'h0;
	  rowval <= 32'h0;
	  cpu_ha_sync <= 3'h0;
	  cpu_va_sync <= 3'h0;
	  fifo_in <= 32'h0;
	end
      else
	begin
	  idx <= idx_next;
	  state <= state_next;
	  rowval <= rowval_next;
	  cpu_ha_sync <= { h_active, cpu_ha_sync[2], cpu_ha_sync[1] };
	  cpu_va_sync <= { v_active, cpu_va_sync[2], cpu_va_sync[1] };
	  fifo_in <= fifo_in_next;
	end
    end

  always_comb
    begin
      state_next = state;
      idx_next = idx;
      rowval_next = rowval;
      fifo_in_next = fifo_in;
      
      if (cpu_va_rising)
	begin
	  rowval_next = 16'h0;
	end
      
      case (state)
	S_IDLE:
	  begin
	    if (cpu_ha_falling && cpu_va_sync[1:0] == 2'b11)
	      begin
		state_next = S_BUS;
	      end
	  end
	S_BUS:
	  state_next = S_ACK_WAIT;
	S_ACK_WAIT:
	  begin
	    if (bus.ack)
	      begin
		state_next = S_STORE;
		fifo_in_next = bus_dat_i;
	      end
	  end
	S_STORE:
	  begin
	    if (idx != 5'd19) // 32 pixels per word, 20 words per line
	      begin
		state_next = S_BUS;
		idx_next = idx + 5'd1;
	      end
	    else
	      begin
		idx_next = 5'd0;
		rowval_next = rowval + 7'h50;
		state_next = S_IDLE;
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
	  .write(state == S_STORE),
	  .read(fifo_read),
	  .in(fifo_in),
	  .out(fifo_out));
  
  vga_controller25 vga13h(.v_active(v_active),
			  .h_active(h_active),
			  .vs(vs),
			  .hs(hs),
			  .clock(video_clk_i),
			  .rst_i(video_rst_i));

endmodule
