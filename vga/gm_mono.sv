`include "../wb.vh"

module gm_mono
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

  typedef enum 	bit [1:0] { S_IDLE, S_BUS, S_ACK_WAIT } state_t;
  
  state_t      state, state_next;
  logic [4:0]  ack_count, ack_count_next;
  logic [4:0]  req_count, req_count_next;
  logic [31:0] rowval, rowval_next;
  logic [9:0]  x, x_next;
  logic [31:0] monobuf[0:19], monobuf_next[0:19];
  logic        v_active, h_active;
  logic        eos_raw, eol_raw;
  logic        eos[0:1], eol[0:1];
  
  assign bus.cyc = (state == S_BUS || state == S_ACK_WAIT);
  assign bus.stb = (state == S_BUS);
  assign bus.adr = rowval;
  assign bus_dat_o = 32'h0;
  assign bus.we = 1'h0;
  assign bus.sel = 4'hf;
  assign blank_n = v_active & h_active;

  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  state <= S_IDLE;
	  ack_count <= 5'h0;
	  req_count <= 5'h0;
	  rowval <= 32'h0;
	  for (int i=0; i < 20; i = i + 1)
	    monobuf[i] <= 32'h0;
	  eos[0] <= 1'h0;
	  eos[1] <= 1'h0;
	  eol[0] <= 1'h0;
	  eol[1] <= 1'h0;
	end
      else
	begin
	  state <= state_next;
	  ack_count <= ack_count_next;
	  req_count <= req_count_next;
	  rowval <= rowval_next;
	  for (int i=0; i < 20; i = i + 1)
	    monobuf[i] <= monobuf_next[i];
	  // simple synchronizer
	  eos[0] <= eos[1];
	  eos[1] <= eos_raw;
	  eol[0] <= eol[1];
	  eol[1] <= eol_raw;
	end
    end

  always_comb
    begin
      state_next = state;
      ack_count_next = ack_count;
      req_count_next = req_count;
      rowval_next = rowval;
      for (int i=0; i < 20; i = i + 1)
	monobuf_next[i] = monobuf[i];

      case (state)
	S_IDLE:
	  begin
	    if (eol[0])
	      begin
		state_next = S_BUS;
		ack_count_next = 5'h0;
		req_count_next = 5'h0;
	      end
	    if (eos[0])
	      rowval_next = 32'h0;
	  end
	S_BUS:
	  begin
	    if (req_count == 5'd20)
	      begin
		req_count_next = 5'h0;
		state_next = S_ACK_WAIT;
	      end
	    else
	      begin
		if (!bus.stall)
		  begin
		    req_count_next = req_count + 5'h1;
		    rowval_next = rowval + 32'h4;
		  end
	      end
	    if (bus.ack)
	      begin
		ack_count_next = ack_count + 5'h1;
		monobuf_next[ack_count] = bus_dat_i;
	      end
	    if (ack_count == 5'd20 || eol[0])
	      begin
		ack_count_next = 5'h0;
		state_next = S_IDLE;
	      end
	  end // case: S_BUS
	S_ACK_WAIT:
	  begin
	    if (bus.ack)
	      begin
		ack_count_next = ack_count + 5'h1;
		monobuf_next[ack_count] = bus_dat_i;
	      end
	    if (ack_count == 5'd20 || eol[0])
	      begin
		ack_count_next = 5'h0;
		state_next = S_IDLE;
	      end
	  end
      endcase // case (state)
    end
  
  always_comb
    begin
      { red, green, blue } = (monobuf[x[9:5]][5'h1f-x] ? 24'hffffff : 24'h0);
    end

  always_ff @(posedge clk_i or posedge eos_raw)
    begin
      if (eos_raw)
	begin
	  x <= 10'h0;
	end
      else
	begin
	  x <= x_next;
	end
    end

  always_comb
    begin
      x_next = (h_active ? x + 10'h1 : 10'h0);
    end

  vga_controller25 vga0(.v_active(v_active),
			.h_active(h_active),
			.vs(vs),
			.hs(hs),
			.eos(eos_raw),
			.eol(eol_raw),
			.clock(video_clk),
			.rst_i(rst_i));

endmodule
