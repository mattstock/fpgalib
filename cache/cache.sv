`include "../wb.vh"

// Assume that the busses are all byte-based.

// pipeline and block support
module cache
  #(AWIDTH=27,
    DWIDTH=32,
    ROWWIDTH=4,
    TAGSIZE=13)
  (input        clk_i,
   input 	rst_i,
		if_wb.slave inbus,
		if_wb.master outbus,
		if_wb.slave stats,
   output [1:0] cache_status);

  logic [DWIDTH-1:0] 	outbus_dat_i, outbus_dat_o;
  logic [DWIDTH-1:0] 	inbus_dat_i, inbus_dat_o;
  logic [DWIDTH-1:0] 	stats_dat_i, stats_dat_o;
  
`ifdef NO_MODPORT_EXPRESSIONS
  assign inbus_dat_i = inbus.dat_m;
  assign inbus.dat_s = inbus_dat_o;
  assign stats_dat_i = stats.dat_m;
  assign stats.dat_s = stats_dat_o;
  assign outbus_dat_i = outbus.dat_s;
  assign outbus.dat_m = outbus_dat_o;
`else
  assign inbus_dat_i = inbus.dat_i;
  assign inbus.dat_o = inbus_dat_o;
  assign stats_dat_i = stats.dat_i;
  assign stats.dat_o = stats_dat_o;
  assign outbus_dat_i = outbus.dat_i;
  assign outbus.dat_o = outbus_dat_o;
`endif

  // Number of bits in address to represent byte position in a word
  localparam BYTEBITS = $clog2(DWIDTH/8);
  // Number of bits to remove from index based on the number of
  // words we're putting in a single cache line
  localparam WORDBITS = $clog2(ROWWIDTH);
  // Based on the byte size of the memory, the size of the index
  localparam INDEXSIZE=AWIDTH-TAGSIZE-WORDBITS-BYTEBITS;
  // Size of the command fifo data width
  localparam FIFO_DWIDTH=AWIDTH+DWIDTH+'d4+'d1-BYTEBITS;  
  
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

  // 0 fill
  localparam padding = { 8'd32-AWIDTH{1'b0} };

  // front of house
  typedef enum 	bit [1:0] { BS_IDLE, BS_ACK,
			    BS_READ_WAIT, BS_WAIT } bs_state_t;

  bs_state_t    bus_state, bus_state_next;
  
  logic  	              fifo_read, fifo_empty, fifo_full, fifo_write;
  logic [FIFO_DWIDTH-1:0]     fifo_out, fifo_in, fifo_saved, fifo_saved_next;
  logic [DWIDTH-1:0] 	      fifo_dat_i;
  logic [AWIDTH-1-BYTEBITS:0] fifo_adr_i;
  logic [3:0] 		      fifo_sel_i;
  logic 		      fifo_we_i;

  logic [DWIDTH-1:0] 	inbus_dat_next;

  assign fifo_in = {inbus.we,
		    inbus.adr[AWIDTH-1+BYTEBITS-WORDBITS:BYTEBITS],
		    inbus_dat_i,
		    inbus.sel};
  assign fifo_we_i = fifo_saved[FIFO_DWIDTH-1];
  assign fifo_adr_i = fifo_saved[AWIDTH-1+DWIDTH+4-BYTEBITS:DWIDTH+4];
  assign fifo_dat_i = fifo_saved[DWIDTH+3:4];
  assign fifo_sel_i = fifo_saved[3:0];

  assign fifo_write = ~fifo_full & inbus.cyc & inbus.stb;
  assign inbus.stall = fifo_full;
  assign inbus.ack = (bus_state == BS_ACK);

  assign stats.stall = 1'b1;
  assign stats.ack = 1'b0;
  assign stats_dat_o = stats_dat_i;
  
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
	    if (~fifo_full)
	      bus_state_next = (inbus.we ? BS_ACK : BS_READ_WAIT);
	BS_READ_WAIT: // reads need to block until all transactions are complete
	  if (fifo_empty && state == S_DONE)
	    bus_state_next = BS_ACK;
	BS_ACK:
	  if (inbus.cyc)
	    if (inbus.stb)
	      begin
		if (~fifo_full)
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
			     S_INIT, S_BUSY2, S_BUSY3 } state_t;

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
  logic [INDEXSIZE-1:0] rowaddr;
  logic [1:0] 		wordsel;
  logic [ROWWIDTH-1:0] 	dirty [1:0];
  logic [1:0] 		valid, wren, hit, lru;
  logic 		anyhit;
  logic [DWIDTH-1:0] 	word0 [1:0], word1 [1:0], word2 [1:0], word3 [1:0];
  logic 		mem_stb;
  
  assign cache_status = hit;
  
  assign fifo_read = (state == S_IDLE & ~fifo_empty);
  assign tag_in = fifo_adr_i[AWIDTH-1-BYTEBITS:INDEXSIZE+WORDBITS];
  assign rowaddr = fifo_adr_i[INDEXSIZE+WORDBITS-1:WORDBITS];
  assign wordsel = fifo_adr_i[WORDBITS-1:0];
 
  assign anyhit = |hit;

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
      end
  
  always_comb
    begin
      outbus.adr = 32'h0;
      outbus_dat_o = 32'h0;
      outbus.we = 1'h0;
      outbus.cyc = 1'h0;
      outbus.stb = 1'h0;
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
	  if (~fifo_empty)
	    begin
	      fifo_saved_next = fifo_out;
	      state_next = S_BUSY;
	    end
	S_BUSY: 
	  state_next = S_BUSY2;
	S_BUSY2:
	  state_next = S_BUSY3;
	S_BUSY3:
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
	    if (fifo_we_i)
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
	    rowin_next[lruset][DIRTY3] = 1'b0; // clean
	    outbus.adr = { padding, tag_in, rowaddr, 4'h0 };
	    outbus.cyc = 1'h1;
	    outbus.stb = 1'h1;
	    outbus.we = 1'h0;
	    if (!outbus.stall && outbus.ack)
	      begin
		rowin_next[lruset][31:0] = outbus_dat_i;
		state_next = S_FILL2;
	      end
	  end // case: S_FILL
	S_FILL2:
	  begin
	    rowin_next[lruset][DIRTY2] = 1'b0; // clean
	    outbus.cyc = 1'h1;
	    outbus.stb = 1'h1;
	    outbus.we = 1'h0;
	    if (!outbus.stall && outbus.ack)
	      begin
		rowin_next[lruset][63:32] = outbus_dat_i;
		state_next = S_FILL3;
	      end
	  end
	S_FILL3:
	  begin
	    rowin_next[lruset][DIRTY1] = 1'b0; // clean
	    outbus.cyc = 1'h1;
	    outbus.stb = 1'h1;
	    outbus.we = 1'h0;
	    if (!outbus.stall && outbus.ack)
	      begin
		rowin_next[lruset][95:64] = outbus_dat_i;
		state_next = S_FILL4;
	      end
	  end
	S_FILL4:
	  begin
	    rowin_next[lruset][DIRTY0] = 1'b0; // clean
	    outbus.cyc = 1'h1;
	    outbus.stb = 1'h1;
	    outbus.we = 1'h0;
	    if (!outbus.stall && outbus.ack)
	      begin
		rowin_next[lruset][127:96] = outbus_dat_i;
		state_next = S_FILL5;
	      end
	  end
	S_FILL5:
	  begin
	    for (int i=0; i < 2; i = i + 1)
	      wren[i] = 1'b1;
	    fillreg_next = fillreg + 1'h1;
	    state_next = S_BUSY;
	  end
	S_FLUSH:
	  begin
	    outbus.adr = { padding, tag_cache[lruset], rowaddr, 4'h0 };
	    outbus_dat_o = word0[lruset];
	    outbus.cyc = 1'h1;
	    outbus.stb = 1'h1;
	    outbus.we = 1'h1;
	    if (!outbus.stall && outbus.ack)
	      state_next = S_FLUSH2;
	  end
	S_FLUSH2:
	  begin
	    outbus_dat_o = word1[lruset];
	    outbus.cyc = 1'h1;
	    outbus.stb = 1'h1;
	    outbus.we = 1'h1;
	    if (!outbus.stall && outbus.ack)
	      state_next = S_FLUSH3;
	  end
	S_FLUSH3:
	  begin
	    outbus_dat_o = word2[lruset];
	    outbus.cyc = 1'h1;
	    outbus.stb = 1'h1;
	    outbus.we = 1'h1;
	    if (!outbus.stall && outbus.ack)
	      state_next = S_FLUSH4;
	  end
	S_FLUSH4:
	  begin
	    outbus_dat_o = word3[lruset];
	    outbus.cyc = 1'h1;
	    outbus.stb = 1'h1;
	    outbus.we = 1'h1;
	    if (!outbus.stall && outbus.ack)
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
