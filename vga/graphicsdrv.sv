`include "../wb.vh"

module graphicsdrv
  #(BPP = 8)
  (
   input 	    clk_i,
   input 	    rst_i,
   input [3:0] 	    mode,
   input 	    eol,
   input 	    h_active,
   input 	    v_active,
   output [BPP-1:0] red,
   output [BPP-1:0] green,
   output [BPP-1:0] blue,
		    if_wb.master fb_bus,
		    if_wb.master pal_bus);

  // Mode 0: 640x480x1
  // Mode 1: 640x480x4 (classic EGA colors)
  // Mode 2: 640x480x8 (256 color palette)
  // Mode 3: 320x200x8 (double mode)
  
  logic [31:0] 	fb_bus_dat_i, fb_bus_dat_o;
  logic [31:0] 	pal_bus_dat_i, pal_bus_dat_o;

`ifdef NO_MODPORT_EXPRESSIONS
  assign fb_bus_dat_i = fb_bus.dat_s;
  assign fb_bus.dat_m = fb_bus_dat_o;
  assign pal_bus_dat_i = pal_bus.dat_s;
  assign pal_bus.dat_m = pal_bus_dat_o;
`else
  assign fb_bus_dat_i = fb_bus.dat_i;
  assign fb_bus.dat_o = fb_bus_dat_o;
  assign pal_bus_dat_i = pal_bus.dat_i;
  assign pal_bus.dat_o = pal_bus_dat_o;
`endif

  typedef enum 	bit [2:0] { S_IDLE, S_BUS, S_STORE, S_ACK_WAIT } state_t;
  
  state_t      state, state_next;
  logic [4:0]  idx, idx_next;
  logic [31:0] rowval, rowval_next;
  logic [9:0]  x, x_next;
  logic [8:0]  y, y_next;
  
  logic [31:0] monobuf[0:19], monobuf_next[0:19];

  assign fb_bus.cyc = (state == S_BUS || state == S_ACK_WAIT);
  assign fb_bus.stb = (state == S_BUS);
  assign fb_bus.adr = rowval + { idx, 2'h0 };
  assign fb_bus_dat_o = 32'h0;
  assign fb_bus.we = 1'h0;
  assign fb_bus.sel = 4'hf;
  
  assign pal_bus.cyc = 1'h0;
  assign pal_bus.stb = 1'h0;
  assign pal_bus_dat_o = 32'h0;
  assign pal_bus.adr = 32'h0;
  assign pal_bus.we = 1'h0;
  assign pal_bus.sel = 4'hf;
  
  always_comb
    begin
      { red, green, blue } = (monobuf[x[9:5]][5'h1f-x] ? 24'hffffff : 24'h0);
    end

  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  state <= S_IDLE;
	  idx <= 5'h0;
	  rowval <= 32'h0;
	  x <= 10'h0;
	  y <= 9'h0;
	  for (int i=0; i < 20; i = i + 1)
	    monobuf[i] <= 32'h0;
	end
      else
	begin
	  idx <= idx_next;
	  state <= state_next;
	  rowval <= rowval_next;
	  x <= x_next;
	  y <= y_next;
	  for (int i=0; i < 20; i = i + 1)
	    monobuf[i] <= monobuf_next[i];
	end
    end

  always_comb
    begin
      state_next = state;
      idx_next = idx;
      rowval_next = rowval;
      y_next = y;
      for (int i=0; i < 20; i = i + 1)
	monobuf_next[i] = monobuf[i];

      x_next = (h_active ? x + 10'h1 : 10'h0);
      
      if (v_active && eol)
	y_next = y + 9'h1;

      case (state)
	S_IDLE:
	  begin
	    if (eol)
	      begin
		state_next = S_BUS;
	      end
	  end
	S_BUS:
	  state_next = S_ACK_WAIT;
	S_ACK_WAIT:
	  begin
	    if (fb_bus.ack)
	      begin
		state_next = S_STORE;
		monobuf_next[idx] = fb_bus_dat_i;
	      end
	  end
	S_STORE:
	  begin
	    if (idx < 5'd20) // 32 pixels per word, 20 words per line
	      begin
		state_next = S_BUS;
		idx_next = idx + 5'd1;
	      end
	    else
	      begin
		idx_next = 5'd0;
		rowval_next = (y == 9'd479 || !v_active ? 16'h0 : rowval + 10'd640);
		state_next = S_IDLE;
	      end
	  end
      endcase
    end

endmodule
