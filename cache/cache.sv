`include "../wb.vh"

// pipeline and block support
module cache
  #(AWIDTH=25,
    DWIDTH=32,
    ROWWIDTH=4,
    TAGSIZE=13)
  (input        clk_i,
   input 	rst_i,
		if_wb.slave inbus,
		if_wb.master outbus,
   output [1:0] cache_status,
   input 	stats_stb_i);

  logic [31:0] 	outbus_dat_i, outbus_dat_o;
  logic [31:0] 	inbus_dat_i, inbus_dat_o;
  
`ifdef NO_MODPORT_EXPRESSIONS
  assign inbus_dat_i = inbus.dat_m;
  assign inbus.dat_s = inbus_dat_o;
  assign outbus_dat_i = outbus.dat_s;
  assign outbus.dat_m = outbus_dat_o;
`else
  assign inbus_dat_i = inbus.dat_i;
  assign inbus.dat_o = inbus_dat_o;
  assign outbus_dat_i = outbus.dat_i;
  assign outbus.dat_o = outbus_dat_o;
`endif
  
  // for my own sanity
  localparam INDEXSIZE = AWIDTH-TAGSIZE-'d2;
  localparam FIFO_DWIDTH=AWIDTH+DWIDTH+'d4+'d1;  
  
  // 2 bits for valid and lru
  localparam ROWSIZE = 'd2 + ROWWIDTH + TAGSIZE + ROWWIDTH*DWIDTH;
  
  // index values into the cache rows
  localparam LRU = ROWSIZE-'d1;
  localparam VALID = LRU-'d1;
  localparam DIRTY3 = VALID-'d1;
  localparam DIRTY2 = DIRTY3-'d1;
  localparam DIRTY1 = DIRTY2-'d1;
  localparam DIRTY0 = DIRTY1-'d1;
  localparam TAGBASE = DIRTY0-TAGSIZE;
  
  // front of house
  typedef enum 	bit [1:0] { BS_IDLE, BS_ACK,
			    BS_READ_WAIT, BS_WAIT } bs_state_t;

  bs_state_t    bus_state, bus_state_next;
  
  logic 	fifo_read, fifo_empty, fifo_full, fifo_write;
  logic [FIFO_DWIDTH-1:0] fifo_out, fifo_in, fifo_saved, fifo_saved_next;
  logic [DWIDTH-1:0] 	fifo_dat_i;
  logic [AWIDTH-1:0] 	fifo_adr_i;
  logic [3:0] 		fifo_sel_i;
  logic 		fifo_we_i;

  logic [DWIDTH-1:0] 	inbus_dat_next;

  assign fifo_in = {inbus.we,
		    inbus.adr[AWIDTH+1:2],
		    inbus_dat_i,
		    inbus.sel};
  assign { fifo_we_i, fifo_adr_i, fifo_dat_i, fifo_sel_i } = fifo_saved;

  assign fifo_write = ~fifo_full & inbus.cyc & inbus.stb & ~stats_stb_i;
  assign inbus.stall = fifo_full;
  assign inbus.ack = (bus_state == BS_ACK);
  
  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	bus_state <= BS_IDLE;
      end
    else
      begin
	bus_state <= bus_state_next;
      end
  
  always_comb
    begin
      bus_state_next = bus_state;
      case (bus_state)
	BS_IDLE:
	  if (inbus.cyc & inbus.stb)
	    if (~fifo_full | stats_stb_i)
	      bus_state_next = (inbus.we ? BS_ACK : BS_READ_WAIT);
	BS_READ_WAIT: // reads need to block until all transactions are complete
	  if (fifo_empty && state == S_DONE)
	    bus_state_next = BS_ACK;
	BS_ACK:
	  if (inbus.cyc)
	    if (inbus.stb)
	      begin
		if (~fifo_full | stats_stb_i)
		  bus_state_next = (inbus.we ? BS_ACK : BS_READ_WAIT);
	      end
	    else
	      bus_state_next = BS_WAIT;
	  else // might need to clear the fifo too
	    bus_state_next = BS_IDLE;
	BS_WAIT:
	  if (~inbus.cyc)
	    bus_state_next = BS_IDLE;
      endcase
    end
  
  // back of house
  typedef enum 	 bit [5:0] { S_IDLE, S_BUSY, S_HIT, S_MISS, 
			     S_FILL, S_FILL2, S_FILL3, S_FILL4, 
			     S_FILL5, S_FLUSH, S_FLUSH2, S_FLUSH3,
			     S_FLUSH4, S_FLUSH5, S_DONE,
			     S_FILL_WAIT, S_FILL2_WAIT, S_FILL3_WAIT, S_FILL4_WAIT,
			     S_FLUSH_WAIT, S_FLUSH2_WAIT, S_FLUSH3_WAIT, S_FLUSH4_WAIT,
			     S_INIT, S_BUSY2 } state_t;

  state_t               state, state_next;
  logic [INDEXSIZE-1:0] initaddr, initaddr_next;
  logic [31:0] 		hitreg, hitreg_next;
  logic [31:0] 		flushreg, flushreg_next;
  logic [31:0] 		fillreg, fillreg_next;
  logic [ROWSIZE-1:0] 	rowin [1:0], rowin_next [1:0];
  logic 		lruset, lruset_next;
  logic 		hitset, hitset_next;
  
  logic [TAGSIZE-1:0] 	tag_in;
  logic [TAGSIZE-1:0] 	tag_cache [1:0];
  logic [ROWSIZE-1:0] 	rowout [1:0];
  logic [INDEXSIZE-1:0] rowaddr, rowaddr1, rowaddr2, rowaddr3;
  logic [1:0] 		wordsel;
  logic [ROWWIDTH-1:0] 	dirty [1:0];
  logic [1:0] 		valid, wren, hit, lru;
  logic 		anyhit;
  logic [DWIDTH-1:0] 	word0 [1:0], word1 [1:0], word2 [1:0], word3 [1:0];
  logic 		mem_stb;
  logic [AWIDTH-1:0] 	outbus_adr_next;
  
  assign cache_status = hit;
  
  assign fifo_read = (state == S_IDLE & ~fifo_empty);
  assign tag_in = fifo_adr_i[AWIDTH-1:INDEXSIZE+2];
  assign rowaddr = fifo_adr_i[INDEXSIZE+1:2];
  assign rowaddr1 = rowaddr + {{INDEXSIZE-1{1'h0}}, 1'h1};
  assign rowaddr2 = rowaddr << 1'h1;
  assign rowaddr3 = rowaddr1 << 1'h1;
 
  assign wordsel = fifo_adr_i[1:0];
  assign anyhit = |hit;

  assign outbus.stb = (state == S_FILL || state == S_FILL2 ||
		       state == S_FILL3 || state == S_FILL4 ||
		       state == S_FLUSH || state == S_FLUSH2 ||
		       state == S_FLUSH3 || state == S_FLUSH4);
  assign outbus.cyc = outbus.stb | (state == S_FILL_WAIT || state == S_FILL2_WAIT ||
				    state == S_FILL3_WAIT || state == S_FILL4_WAIT ||
				    state == S_FLUSH_WAIT || state == S_FLUSH2_WAIT ||
				    state == S_FLUSH3_WAIT || state == S_FLUSH4_WAIT);
  assign outbus.we = (state == S_FLUSH || state == S_FLUSH2 ||
		      state == S_FLUSH3 || state == S_FLUSH4);
  assign outbus.sel = 4'hf;

  always_comb
    begin
      for (int i=0; i < 2; i = i + 1)
	begin
	  lru[i] = rowout[i][LRU];
	  valid[i] = rowout[i][VALID];
	  dirty[i] = rowout[i][DIRTY3:DIRTY0];
	  tag_cache[i] = rowout[i][TAGBASE+TAGSIZE-1:TAGBASE];
	  word3[i] = rowout[i][127:96];
	  word2[i] = rowout[i][95:64];
	  word1[i] = rowout[i][63:32];
	  word0[i] = rowout[i][31:0];
	  hit[i] = (tag_cache[i] == tag_in) & valid[i];
	end
    end

  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	state <= S_INIT;
	for (int i=0; i < 2; i = i + 1)
	  rowin[i] <= 'h0;
	inbus_dat_o <= 32'h0;
	initaddr <= {INDEXSIZE{1'h1}};
	hitreg <= 32'h0;
	flushreg <= 32'h0;
	fillreg <= 32'h0;
	hitset <= 1'h0;
	lruset <= 1'h0;
	outbus.adr <= 32'h0;
	fifo_saved <= 'h0;
      end
    else
      begin
	state <= state_next;
	for (int i=0; i < 2; i = i + 1)
	  rowin[i] <= rowin_next[i];
	inbus_dat_o <= inbus_dat_next;
	initaddr <= initaddr_next;
	hitreg <= hitreg_next;
	flushreg <= flushreg_next;
	fillreg <= fillreg_next;
	hitset <= hitset_next;
	lruset <= lruset_next;
	fifo_saved <= fifo_saved_next;
	outbus.adr <= { {6'd32-AWIDTH{1'h0}}, outbus_adr_next};
      end
  
  always_comb
    begin
      state_next = state;
      for (int i=0; i < 2; i = i + 1) begin
	rowin_next[i] = rowin[i];
	wren[i] = 1'b0;
      end
      fifo_saved_next = fifo_saved;
      initaddr_next = initaddr;
      inbus_dat_next = inbus_dat_o;
      hitreg_next = hitreg;
      flushreg_next = flushreg;
      fillreg_next = fillreg;
      lruset_next = lruset;
      hitset_next = hitset;
      outbus_adr_next = outbus.adr[AWIDTH-1:0];
      outbus.we = 1'h0;
      outbus.stb = 1'h0;
      outbus_dat_o = 32'h0;
      
      case (state)
	S_INIT: 
	  begin
	    for (int i=0; i < 2; i = i + 1)
	      begin
		rowin_next[i][VALID] = 1'b0;
		wren[i] = 1'b1;
	      end
	    initaddr_next = initaddr - 1'b1;
	    if (initaddr == 'h0)
	      state_next = S_IDLE;
	  end
	S_IDLE:
	  if (inbus.cyc & inbus.stb & stats_stb_i)
	    begin
	      case (inbus.adr[5:2])
		'h0: inbus_dat_next = hitreg;
		'h1: inbus_dat_next = flushreg;
		'h2: inbus_dat_next = fillreg;
		default: inbus_dat_next = 32'h0;
	      endcase
	      state_next = S_DONE;
	    end
	  else  
	    if (~fifo_empty)
	      begin
		fifo_saved_next = fifo_out;
		state_next = S_BUSY;
	      end
	S_BUSY: 
	  state_next = S_BUSY2;
	S_BUSY2:
	  begin
	    for (int i=0; i < 2; i = i + 1)
	      rowin_next[i] = rowout[i];
	    hitset_next = hit[1];
	    lruset_next = lru[1];
	    state_next = (anyhit ? S_HIT : S_MISS);
	  end
	S_HIT:
	  begin
	    if (hitset)
	      begin
		rowin_next[1][LRU] = 1'b0;
		rowin_next[0][LRU] = 1'b1;
	      end
	    else
	      begin
		rowin_next[0][LRU] = 1'b0;
		rowin_next[1][LRU] = 1'b1;
	      end
	    if (fifo_we_i)
	      begin
		case (wordsel)
		  2'h0:
		    begin
		      rowin_next[hitset][DIRTY0] = 1'b1;
		      rowin_next[hitset][7:0] = (fifo_sel_i[0] ? fifo_dat_i[7:0] : word0[hitset][7:0]);
		      rowin_next[hitset][15:8] = (fifo_sel_i[1] ? fifo_dat_i[15:8] : word0[hitset][15:8]);
		      rowin_next[hitset][23:16] = (fifo_sel_i[2] ? fifo_dat_i[23:16] : word0[hitset][23:16]);
		      rowin_next[hitset][31:24] = (fifo_sel_i[3] ? fifo_dat_i[31:24] : word0[hitset][31:24]);
		    end
		  2'h1:
		    begin
		      rowin_next[hitset][DIRTY1] = 1'b1;
		      rowin_next[hitset][39:32] = (fifo_sel_i[0] ? fifo_dat_i[7:0] : word1[hitset][7:0]);
		      rowin_next[hitset][47:40] = (fifo_sel_i[1] ? fifo_dat_i[15:8] : word1[hitset][15:8]);
		      rowin_next[hitset][55:48] = (fifo_sel_i[2] ? fifo_dat_i[23:16] : word1[hitset][23:16]);
		      rowin_next[hitset][63:56] = (fifo_sel_i[3] ? fifo_dat_i[31:24] : word1[hitset][31:24]);
		    end
		  2'h2:
		    begin
		      rowin_next[hitset][DIRTY2] = 1'b1;
		      rowin_next[hitset][71:64] = (fifo_sel_i[0] ? fifo_dat_i[7:0] : word2[hitset][7:0]);
		      rowin_next[hitset][79:72] = (fifo_sel_i[1] ? fifo_dat_i[15:8] : word2[hitset][15:8]);
		      rowin_next[hitset][87:80] = (fifo_sel_i[2] ? fifo_dat_i[23:16] : word2[hitset][23:16]);
		      rowin_next[hitset][95:88] = (fifo_sel_i[3] ? fifo_dat_i[31:24] : word2[hitset][31:24]);
		    end
		  2'h3:
		    begin
		      rowin_next[hitset][DIRTY3] = 1'b1;
		      rowin_next[hitset][103:96] = (fifo_sel_i[0] ? fifo_dat_i[7:0] : word3[hitset][7:0]);
		      rowin_next[hitset][111:104] = (fifo_sel_i[1] ? fifo_dat_i[15:8] : word3[hitset][15:8]);
		      rowin_next[hitset][119:112] = (fifo_sel_i[2] ? fifo_dat_i[23:16] : word3[hitset][23:16]);
		      rowin_next[hitset][127:120] = (fifo_sel_i[3] ? fifo_dat_i[31:24] : word3[hitset][31:24]);
		    end
		endcase
	      end
	    else
	      begin
		case (wordsel)
		  2'h0: inbus_dat_next = word0[hitset];
		  2'h1: inbus_dat_next = word1[hitset];
		  2'h2: inbus_dat_next = word2[hitset];
		  2'h3: inbus_dat_next = word3[hitset];
		endcase
	      end
	    hitreg_next = hitreg + 1'h1;
	    state_next = S_DONE;
	  end
	S_DONE:
	  begin
	    if (~stats_stb_i)
	      for (int i=0; i < 2; i = i + 1)
		wren[i] = 1'h1;
	    state_next = S_IDLE;
	  end
	S_MISS:
	  begin
	    rowin_next[lruset][TAGBASE+TAGSIZE-1:TAGBASE] = tag_in;
	    state_next = (valid[lruset] & |dirty[lruset]  ? S_FLUSH : S_FILL);
	  end
	S_FILL:
	  begin
	    if (lruset)
	      begin
		rowin_next[1][LRU] = 1'b0;
		rowin_next[0][LRU] = 1'b1;
	      end
	    else
	      begin
		rowin_next[0][LRU] = 1'b0;
		rowin_next[1][LRU] = 1'b1;
	      end
	    rowin_next[lruset][VALID] = 1'b1;
	    rowin_next[lruset][DIRTY0] = 1'b0; // clean
	    rowin_next[lruset][31:0] = outbus_dat_i;
	    outbus_adr_next = { tag_in, rowaddr, 2'h0 };
	    state_next = S_FILL_WAIT;
	  end // case: S_FILL
	S_FILL_WAIT:
	  if (outbus.ack)
	    state_next = S_FILL2;
	S_FILL2:
	  begin
	    rowin_next[lruset][DIRTY1] = 1'b0; // clean
	    rowin_next[lruset][63:32] = outbus_dat_i;
	    outbus_adr_next = { tag_in, rowaddr1, 2'h0 };
	    state_next = S_FILL2_WAIT;
	  end
	S_FILL2_WAIT:
	  if (outbus.ack)
	    state_next = S_FILL3;
	S_FILL3:
	  begin
	    rowin_next[lruset][DIRTY2] = 1'b0; // clean
	    rowin_next[lruset][95:64] = outbus_dat_i;
	    outbus_adr_next = { tag_in, rowaddr2, 2'h0 };
	    state_next = S_FILL3_WAIT;
	  end
	S_FILL3_WAIT:
	  if (outbus.ack)
	    state_next = S_FILL4;
	S_FILL4:
	  begin
	    rowin_next[lruset][DIRTY3] = 1'b0; // clean
	    rowin_next[lruset][127:96] = outbus_dat_i;
	    outbus_adr_next = { tag_in, rowaddr3, 2'h0 };
	    state_next = S_FILL4_WAIT;
	  end
	S_FILL4_WAIT:
	  if (outbus.ack)
	    state_next = S_FILL5;
	S_FILL5:
	  begin
	    for (int i=0; i < 2; i = i + 1)
	      wren[i] = 1'b1;
	    fillreg_next = fillreg + 1'h1;
	    state_next = S_BUSY;
	  end
	S_FLUSH: begin
	  outbus_dat_o = word0[lruset];
	  /* verilator lint_off WIDTH */
	  assign outbus_adr_next = { tag_cache[lruset], rowaddr, 2'h0 };
	  /* verilator lint_on WIDTH */
	  if (outbus.ack)
	    state_next = S_FLUSH2;
	end
	S_FLUSH2:
	  begin
	    outbus_dat_o = word1[lruset];
	    if (outbus.ack)
	      state_next = S_FLUSH3;
	  end
	S_FLUSH3: begin
	  outbus_dat_o = word2[lruset];
	  if (outbus.ack) 
	    state_next = S_FLUSH4;
	end
	S_FLUSH4:
	  begin
	    outbus_dat_o = word3[lruset];
	    if (outbus.ack)
	      state_next = S_FLUSH5;
	  end
	S_FLUSH5:
	  begin
	    flushreg_next = flushreg + 1'h1;
	    state_next = S_FILL;
	  end
	default:
	  state_next = S_IDLE;
      endcase
    end
  
  cachemem #(.AWIDTH(INDEXSIZE), .DWIDTH(ROWSIZE))
    cmem0(.clk_i(clk_i),
	  .address((state == S_INIT ? initaddr : rowaddr)),
	  .we(wren[0]), .in(rowin[0]), .out(rowout[0]));
  cachemem #(.AWIDTH(INDEXSIZE), .DWIDTH(ROWSIZE))
    cmem1(.clk_i(clk_i),
	  .address((state == S_INIT ? initaddr : rowaddr)),
	  .we(wren[1]), .in(rowin[1]), .out(rowout[1]));

  fifo #(.DWIDTH(FIFO_DWIDTH)) infifo0(.clk_i(clk_i),
				       .rst_i(rst_i),
				       .push(fifo_write),
				       .pop(fifo_read),
				       .in(fifo_in),
				       .out(fifo_out),
				       .full(fifo_full),
				       .empty(fifo_empty));
  
endmodule
