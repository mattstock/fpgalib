`include "../wb.vh"

// This module runs on the vga dot clock.
// We rely on the memory interface to synchronize things.

module textdrv
  #(BPP = 8)
  (
   input 	    clk_i,
   input 	    rst_i,
   input [31:0]     cursorpos,
   input [3:0] 	    cursormode,
   input [23:0]     cursorcolor,
   input 	    v_active,
   input            h_active,
   input 	    eol,
   input 	    eos,
   output [BPP-1:0] r,
   output [BPP-1:0] g,
   output [BPP-1:0] b,
		    if_wb.master bus);

  logic [31:0] bus_dat_i, bus_dat_o;
  
`ifdef NO_MODPORT_EXPRESSIONS
  assign bus_dat_i = bus.dat_s;
  assign bus.dat_m = bus_dat_o;
`else
  assign bus_dat_i = bus.dat_i;
  assign bus.dat_o = bus_dat_o;
`endif

  logic [31:0] 	    char;
  logic [127:0]     font0_out, font1_out;
  logic [31:0] 	    buf_out;
  logic [15:0] 	    textrow;
  logic [15:0] 	    textcol, textcol_next;
  logic [15:0] 	    y, y_next;
  logic [4:0] 	    ninecol, ninecol_next;
  
  logic [BPP-1:0]   color0, color1;
  logic 	    oncursor;

  logic [9:0] 	    idx, idx_next;
  logic [31:0] 	    rowval, rowval_next;
  logic [31:0] 	    font_idx, font_idx_next;
  logic [23:0] 	    blink;
  
  typedef enum 	    bit [1:0] { S_IDLE, S_BUS, S_FONT, S_STORE } state_t;

  state_t 	    state, state_next;

  assign bus.cyc = (state == S_BUS);
  assign bus.stb = bus.cyc;
  assign bus_dat_o = 32'h0;
  assign bus.we = 1'h0;
  assign bus.sel = 4'hf;
  assign textrow = { 4'h0, y[15:4] };
  
  assign oncursor = ({textrow,textcol} == cursorpos) &&
		    ((blink[23] & cursormode == 4'h1) ||
		     (cursormode == 4'h2));

  // break out the rows of the font elements
  always_comb
    begin
      color0 = font_idx[31:24];
      color1 = font_idx[15:8];
      case (y[3:0])
	'hf: char = { color0, color1, font0_out[7:0], font1_out[7:0] };
	'he: char = { color0, color1, font0_out[15:8], font1_out[15:8] };
	'hd: char = { color0, color1, font0_out[23:16], font1_out[23:16] };
	'hc: char = { color0, color1, font0_out[31:24], font1_out[31:24] };
	'hb: char = { color0, color1, font0_out[39:32], font1_out[39:32] };
	'ha: char = { color0, color1, font0_out[47:40], font1_out[47:40] };
	'h9: char = { color0, color1, font0_out[55:48], font1_out[55:48] };
	'h8: char = { color0, color1, font0_out[63:56], font1_out[63:56] };
	'h7: char = { color0, color1, font0_out[71:64], font1_out[71:64] };
	'h6: char = { color0, color1, font0_out[79:72], font1_out[79:72] };
	'h5: char = { color0, color1, font0_out[87:80], font1_out[87:80] };
	'h4: char = { color0, color1, font0_out[95:88], font1_out[95:88] };
	'h3: char = { color0, color1, font0_out[103:96], font1_out[103:96] };
	'h2: char = { color0, color1, font0_out[111:104], font1_out[111:104] };
	'h1: char = { color0, color1, font0_out[119:112], font1_out[119:112] };
	'h0: char = { color0, color1, font0_out[127:120], font1_out[127:120] };
      endcase
    end  

  always_comb
    begin
      r = 8'h0;
      g = 8'h0;
      b = 8'h0;
      if (ninecol != 5'h8)
	begin
	  if (textcol[0])
	    begin
	      if (buf_out[4'h7-ninecol])
		begin
		  r = { buf_out[31:30], 6'h0 };
		  g = { buf_out[29:27], 5'h0 };
		  b = { buf_out[26:24], 5'h0 };
		end
	    end
	  else
	    begin
	      if (buf_out[4'hf-ninecol])
		begin
		  r = { buf_out[23:22], 6'h0 };
		  g = { buf_out[21:19], 5'h0 };
		  b = { buf_out[18:16], 5'h0 };
		end
	    end // else: !if(textcol[0])
	  if (oncursor)
	    {r, g, b} = cursorcolor;
	end // if (ninecol != 5'h8)
    end // always_comb
  
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  state <= S_IDLE;
	  idx <= 10'h0;
	  rowval <= 32'h0;
	  font_idx <= 32'h0;
	  blink <= 25'h0;
	  textcol <= 16'h0;
	  ninecol <= 5'h0;
	  y <= 15'h0;
	end
      else
	begin
	  idx <= idx_next;
	  state <= state_next;
	  rowval <= rowval_next;
	  font_idx <= font_idx_next;
	  blink <= blink + 1'h1;
	  textcol <= textcol_next;
	  ninecol <= ninecol_next;
	  y <= y_next;
	end
    end

  always_comb
    begin
      state_next = state;
      idx_next = idx;
      rowval_next = rowval;
      font_idx_next = font_idx;
      textcol_next = textcol;
      ninecol_next = ninecol;
      y_next = y;
      bus.adr = 32'h0;

      if (!h_active)
	begin
	  ninecol_next = 5'h0;
	  textcol_next = 15'h0;
	end
      else
	begin
	  if (ninecol == 5'h8)
	    begin
	      ninecol_next = 5'h0;
	      textcol_next = textcol + 15'h1;
	    end // if (ninecol == 5'h8)
	  else
	    ninecol_next = ninecol + 5'h1;
	end // else: !if(!active)

      if (v_active && eol)
	y_next = y + 15'h1;
	  
      if (eos)
	y_next = 15'h0;
      
      case (state)
	S_IDLE:
	  begin
	    if (eol)
	      state_next = S_BUS;
	  end
	S_BUS:
	  begin
	    bus.adr = rowval + idx;
	    if (bus.ack)
	      begin
		state_next = S_FONT;
		font_idx_next = bus_dat_i;
	      end
	  end
	S_FONT:
	  state_next = S_STORE;
	S_STORE:
	  begin
	    if (idx < 11'd160)
	      begin
		state_next = S_BUS;
		idx_next = idx + 10'd4;
	      end
	    else
	      begin
		idx_next = 10'd0;
		if (y == 16'd399)
		  rowval_next = 32'h0;
		else
		  if (y[3:0] == 16'hf)
		    rowval_next = rowval + 10'd160;
		state_next = S_IDLE;
	      end
	  end
      endcase
    end

  dualrom 
    #(.AWIDTH(7),
      .INITNAME("../../fpgalib/vga/font9x16.mif"),
      .DWIDTH(128)) fontmem(.clk_i(clk_i),
			    .rst_i(rst_i),
			    .bus0_adr(font_idx[22:16]),
			    .bus0_data(font0_out),
			    .bus1_adr(font_idx[6:0]),
			    .bus1_data(font1_out));
  
  textlinebuf linebuf0(.clock(clk_i),
		       .wraddress(idx[9:2]),
		       .wren(state == S_STORE),
		       .data(char),
		       .rdaddress(textcol_next[8:1]),
		       .q(buf_out));

endmodule
