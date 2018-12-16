include "../wb.vh"

module led_matrix
  #(COL=32,
    ROW=16)
  (input        clk_i,
   input 	rst_i,
   if_wb.slave  bus,
   input 	led_clk,
   output [2:0] demux,
   output [2:0] matrix0,
   output [2:0] matrix1,
   output 	matrix_stb,
   output 	matrix_clk,
   output 	matrix_oe_n);

  logic 	r,g,b;
  logic 	led_clk, select;
  logic [23:0] 	buffer, matrixmem_out;
  logic [7:0] 	r_level, g_level, b_level;
  logic 	ack_delay;

  logic [2:0] 	matrix0_next, matrix1_next;
  state_t       state, state_next;
  logic 	ab, ab_next;
  logic [4:0] 	colpos, colpos_next;
  logic [2:0] 	rowpos, rowpos_next;
  logic [2:0] 	pwmval, pwmval_next;
  logic [7:0] 	delay, delay_next;

  logic [31:0] 	dat_i, dat_o;

`ifdef NO_MODPORT_EXPRESSIONS
  assign dat_i = bus.dat_m;
  assign bus.dat_s = dat_o;
`else
  assign dat_i = bus.dat_i;
  assign bus.dat_o = dat_o;
`endif
  
  typedef enum 	bit [2:0] { S_IDLE, S_READ1, S_READ2,
			    S_CLOCK, S_LATCH, S_DELAY } state_t;

  assign demux = rowpos;
  assign select = bus.cyc & bus.stb

  always_ff @(posedge clk_i)
    ack_delay <= { ack_delay[0], select };

  always_comb
    begin
      bus.ack = ack_delay[1];
      dat_o = { 8'h0, matrixmem_out };
      { r_level, g_level, b_level } = buffer;
      r = r_level[pwmval];
      g = g_level[pwmval];
      b = b_level[pwmval];
      matrix_stb = (state == S_LATCH);
      matrix_clk = (state == S_CLOCK);
      oe_n = ~(state == S_DELAY);
    end

  always_ff @(posedge led_clk or posedge rst_i)
    if (rst_i)
      begin
	matrix0 <= 3'h0;
	matrix1 <= 3'h0;
	state <= S_IDLE;
	colpos <= 4'h0;
	rowpos <= 3'h0;
	ab <= 1'b0;
	pwmval <= 3'h7;
	delay <= 8'h0;
      end // if (rst_i)
    else
      begin
	matrix0 <= matrix0_next;
	matrix1 <= matrix1_next;
	state <= state_next;
	colpos <= colpos_next;
	rowpos <= rowpos_next;
	ab <= ab_next;
	pwmval <= pwmval_next;
	delay <= delay_next;
      end // else: !if(rst_i)

  always_comb
    begin
      state_next = state;
      matrix0_next = matrix0;
      matrix1_next = matrix1;
      colpos_next = colpos;
      rowpos_next = rowpos;
      ab_next = ab;
      pwmval_next = pwmval;
      delay_next = delay;

      case (state)
	S_IDLE:
	  begin
	    state_next = S_READ1;
	    ab_next = ~ab;
	  end
	S_READ1:
	  begin
	    state_next = S_READ2;
	    ab_next = ~ab;
	    matrix0_next = {r,g,b};
	  end
	S_READ2:
	  begin
	    state_next = S_CLOCK;
	    matrix1_next = {r,g,b};
	    colpos_next = colpos + 1'b1;
	  end
	S_CLOCK:
	  state_next = (colpos == 5'h0 ? S_LATCH : S_IDLE);
	S_LATCH:
	  begin
	    state_next = S_DELAY;
	    pwmval_next = pwmval - 1'b1;
	    case (pwmval)
	      3'h7: delay_next = 8'hff;
	      3'h6: delay_next = 8'h80;
	      3'h5: delay_next = 8'h40;
	      3'h4: delay_next = 8'h20;
	      3'h3: delay_next = 8'h10;
	      3'h2: delay_next = 8'h08;
	      3'h1: delay_next = 8'h04;
	      3'h0: delay_next = 8'h02;
	    endcase // case (pwmval)
	  end // case: S_LATCH
	S_DELAY:
	  begin
	    if (delay == 8'h0)
	      begin
		if (pwmval == 3'h0)
		  rowpos_next = rowpos + 1'b1;
		state_next = S_IDLE;
	      end
	    else
	      delay_next = delay - 1'h1;
	  end // case: S_DELAY
      endcase // case (state)
    end // always_comb

  matrixmem m0(.clock_a(led_clk),
	       .wren_a(1'b0),
	       .address_a({ab, rowpos, colpos}),
	       .q_a(buffer),
	       .clock_b(clk_i),
	       .data_b(dat_i[23:0]),
	       .wren_b(select & bus.we),
	       .address_b(bus.adr),
	       .byteena_b(bus.sel[2:0]),
	       .q_b(matrixmem_out));
  
endmodule
