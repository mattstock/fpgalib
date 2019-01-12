`include "../wb.vh"

module textdrv
  #(BPP = 8)
  (
   input 	    clk_i,
   input 	    rst_i,
   input 	    vga_clock,
   input [31:0]     cursorpos,
   input [3:0] 	    cursormode,
   input [15:0]     x,
   input [15:0]     y,
   output [BPP-1:0] r,
   output [BPP-1:0] g,
   output [BPP-1:0] b,
   if_wb.master     bus);

  logic [31:0] bus_dat_i, bus_dat_o;
  
`ifdef NO_MODPORT_EXPRESSIONS
  assign bus_dat_i = bus.dat_s;
  assign bus.dat_m = bus_dat_o;
`else
  assign bus_dat_i = bus.dat_i;
  assign bus.dat_o = bus_dat_o;
`endif

  logic [95:0] 	    fontval;
  logic [31:0] 	    char;
  logic [95:0] 	    font0_out, font1_out;
  logic [31:0] 	    buf_out;
  logic [15:0] 	    scanaddr;
  logic [15:0] 	    textrow, textcol;
  logic [BPP-1:0]   color0, color1;
  logic 	    oncursor;

  logic [9:0] 	    idx, idx_next;
  logic [31:0] 	    rowval, rowval_next;
  logic [15:0] 	    x_sync [2:0];
  logic [15:0] 	    y_sync [2:0];
  logic [31:0] 	    font_idx, font_idx_next;
  logic [25:0] 	    blink;

  typedef enum 	    bit [1:0] { S_IDLE, S_BUS, S_FONT, S_STORE } state_t;

  state_t 	    state, state_next;

  assign bus.cyc = (state == S_BUS);
  assign bus_dat_o = 32'h0;
  assign bus.we = 1'h0;
  assign bus.sel = 4'hf;
  
  assign scanaddr = x+1'b1;
  assign textrow = { 3'h0, y[15:3] };
  assign textcol = { 3'h0, x[15:3] };
  assign oncursor = ({textrow,textcol} == cursorpos) &&
		    ((blink[25] & cursormode[3:0] == 4'h1) ||
		     (cursormode[3:0] == 4'h2));

  // break out the rows of the font elements
  always_comb
    begin
      case (y[2:0])
	'h7: char = { color0, color1, font0_out[39:32], font1_out[39:32] };
	'h6: char = { color0, color1, font0_out[47:40], font1_out[47:40] };
	'h5: char = { color0, color1, font0_out[55:48], font1_out[55:48] };
	'h4: char = { color0, color1, font0_out[63:56], font1_out[63:56] };
	'h3: char = { color0, color1, font0_out[71:64], font1_out[71:64] };
	'h2: char = { color0, color1, font0_out[79:72], font1_out[79:72] };
	'h1: char = { color0, color1, font0_out[87:80], font1_out[87:80] };
	'h0: char = { color0, color1, font0_out[95:88], font1_out[95:88] };
	default: char = 16'h0;
      endcase
    end  
  
  logic [BPP-1:0] red, green, blue;

  assign red =   (x[3] ? { buf_out[23:22], 6'h0 } : { buf_out[31:30], 6'h0 });
  assign green = (x[3] ? { buf_out[21:19], 5'h0 } : { buf_out[29:27], 5'h0 });
  assign blue =  (x[3] ? { buf_out[18:16], 5'h0 } : { buf_out[26:24], 5'h0 });
  
  assign {r,g,b} = (buf_out[4'hf-x[3:0]] || oncursor ?
		    { red, green, blue } :
		    24'h000000);

  always_ff @(posedge clk_i)
    begin
      x_sync[2] <= x_sync[1];
      x_sync[1] <= x_sync[0];
      x_sync[0] <= x;
      y_sync[2] <= y_sync[1];
      y_sync[1] <= y_sync[0];
      y_sync[0] <= y;
    end

  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  state <= S_IDLE;
	  idx <= 10'h0;
	  rowval <= 32'h0;
	  font_idx <= 32'h0;
	  blink <= 25'h0;
	end
      else
	begin
	  idx <= idx_next;
	  state <= state_next;
	  rowval <= rowval_next;
	  font_idx <= font_idx_next;
	  blink <= blink + 1'h1;
	end
    end

  always_comb
    begin
      state_next = state;
      idx_next = idx;
      rowval_next = rowval;
      font_idx_next = font_idx;
      bus.adr = 32'h0;
      case (state)
	S_IDLE:
	  begin
	    if (y_sync[2] != y_sync[1])
	      begin
		state_next = S_BUS;
	      end
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
		if (y_sync[1] == 16'd479)
		  rowval_next = 32'h0;
		else
		  if (y_sync[1][2:0] == 16'h7)
		    rowval_next = rowval + 10'd160;
		state_next = S_IDLE;
	      end
	  end
      endcase
    end

  assign color0 = font_idx[31:24];
  assign color1 = font_idx[15:8];
  dualrom 
    #(.AWIDTH(7),
      .INITNAME("../../fpgalib/vga/font8x12.mif"),
      .DWIDTH(96)) fontmem(.clk_i(clk_i),
			   .rst_i(rst_i),
			   .bus0_adr(font_idx[22:16]),
			   .bus0_data(font0_out),
			   .bus1_adr(font_idx[6:0]),
			   .bus1_data(font1_out));
  
  textlinebuf linebuf0(.wrclock(clk_i),
		       .wraddress(idx[9:2]),
		       .wren(state == S_STORE),
		       .data(char),
		       .rdclock(vga_clock),
		       .rdaddress(scanaddr[11:4]),
		       .q(buf_out));

endmodule
