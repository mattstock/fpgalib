`include "../wb.vh"

module gm_mono
  #(BPP = 8)
  (
   input 	    clk_i,
   input 	    rst_i,
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

  typedef enum 	bit [2:0] { S_IDLE, S_BUS, S_STORE, S_ACK_WAIT } state_t;
  
  state_t      state, state_next;
  logic [4:0]  idx, idx_next;
  logic [31:0] rowval, rowval_next;
  logic [9:0]  x, x_next;
  logic [8:0]  y, y_next;
  logic [31:0] monobuf[0:19], monobuf_next[0:19];
  logic        newscreen;
  
  assign bus.cyc = (state == S_BUS || state == S_ACK_WAIT);
  assign bus.stb = (state == S_BUS);
  assign bus.adr = rowval + { idx, 2'h0 };
  assign bus_dat_o = 32'h0;
  assign bus.we = 1'h0;
  assign bus.sel = 4'hf;
  assign blank_n = v_active & h_active;
  assign newscreen = rst_i | eos;
  
  always_comb
    begin
      { red, green, blue } = (monobuf[x[9:5]][5'h1f-x] ? 24'hffffff : 24'h0);
    end

  always_ff @(posedge clk_i or posedge newscreen)
    begin
      if (newscreen)
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
	    if (bus.ack)
	      begin
		state_next = S_STORE;
		monobuf_next[idx] = bus_dat_i;
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

  vga_controller25 vga0(.v_active(v_active),
			.h_active(h_active),
			.vs(vs),
			.hs(hs),
			.eos(eos),
			.eol(eol),
			.clock(clk_i),
			.rst_i(rst_i));

endmodule
