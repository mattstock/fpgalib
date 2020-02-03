`include "../wb.vh"

module gm_13h
  #(BPP = 8)
  (
   input 	    clk_i,
   input 	    rst_i,
   input 	    video_clk,
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
  logic [6:0]  idx, idx_next;
  logic [31:0] rowval, rowval_next;
  logic [9:0]  x, x_next;
  logic [8:0]  y, y_next;
  logic        newscreen;
  logic        v_active, h_active;
  logic        eos, eol;
  logic [31:0] linebuf[0:79], linebuf_next[0:79];
  
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
      case (x[2:1])
	2'h0: { red, green, blue } = {3{linebuf[x[9:3]][7:0]}};
	2'h1: { red, green, blue } = {3{linebuf[x[9:3]][15:8]}};
	2'h2: { red, green, blue } = {3{linebuf[x[9:3]][23:16]}};
	2'h3: { red, green, blue } = {3{linebuf[x[9:3]][31:24]}};
      endcase // case (x[2:1])
    end

  always_ff @(posedge clk_i or posedge newscreen)
    begin
      if (newscreen)
	begin
	  state <= S_IDLE;
	  idx <= 7'h0;
	  rowval <= 32'h0;
	  x <= 10'h0;
	  y <= 9'h0;
	  for (int i=0; i < 80; i = i + 1)
	    linebuf[i] <= 32'h0;
	end
      else
	begin
	  idx <= idx_next;
	  state <= state_next;
	  rowval <= rowval_next;
	  x <= x_next;
	  y <= y_next;
	  for (int i=0; i < 80; i = i + 1)
	    linebuf[i] <= linebuf_next[i];
	end
    end

  always_comb
    begin
      state_next = state;
      idx_next = idx;
      rowval_next = rowval;
      y_next = y;
      for (int i=0; i < 80; i = i + 1)
	linebuf_next[i] = linebuf[i];

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
		linebuf_next[idx] = bus_dat_i;
	      end
	  end
	S_STORE:
	  begin
	    if (idx < 7'd80) // 4 pixels per word, 80 words per line
	      begin
		state_next = S_BUS;
		idx_next = idx + 7'd1;
	      end
	    else
	      begin
		idx_next = 7'd0;
		if (y == 9'd479 || !v_active)
		  begin
		    rowval_next = 16'h0;
		  end
		else
		  begin
		    rowval_next = (y[0] ? rowval + 10'd80 : rowval);
		  end
		state_next = S_IDLE;
	      end
	  end
      endcase
    end

  vga_controller25 vga13h(.v_active(v_active),
			  .h_active(h_active),
			  .vs(vs),
			  .hs(hs),
			  .eos(eos),
			  .eol(eol),
			  .clock(video_clk),
			  .rst_i(rst_i));

endmodule
