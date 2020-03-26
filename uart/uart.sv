`include "../wb.vh"

module uart
  #(CLKFREQ = 500000000,
    BAUD = 9600)
  (input 	clk_i,
   input 	rst_i,
   if_wb.slave  bus,
   input 	rx,
   output 	tx,
   input 	cts,
   output 	rts,
   output [1:0] interrupt);

  assign bus.ack = (state == S_DONE);
  assign bus.dat_o = result;
  assign bus.stall = 1'b0;
  assign interrupt = 2'b00;
  assign rts = cts;
  
  typedef enum bit [2:0] { S_IDLE, S_WRITE, S_READ, S_READ2, S_READ3, S_DONE } s_bus_t;
  typedef enum bit [1:0] { TX_IDLE, TX_START, TX_DEQUEUE, TX_WAIT } s_tx_t;
  
  logic [31:0] 	    conf, conf_next, result, result_next;
  
// transmit logic
  s_tx_t 	    tx_shift, tx_shift_next;
  s_bus_t           state, state_next;
  logic [7:0] 	    rx_byte, rx_byte_next;
  logic 	    tx_ready, tx_empty, tx_full, rx_empty, rx_full, rx_queue;
  logic [7:0] 	    tx_top, rx_top, rx_in;

  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i) begin
	state <= S_IDLE;
	conf <= 32'h0;
	result <= 32'h0;
	rx_byte <= 8'h0;
	tx_shift <= TX_IDLE;
      end else begin
	state <= state_next;
	result <= result_next;
	conf <= conf_next;
	rx_byte <= rx_byte_next;
	tx_shift <= tx_shift_next;
      end
    end

  always_comb
    begin
      state_next = state;
      result_next = result;
      rx_byte_next = rx_byte;
      conf_next = conf;
      case (state)
	S_IDLE:
	  begin
	    if (bus.cyc & bus.stb)
	      begin
		case (bus.adr[2])
		  1'b0:
		    state_next = (bus.we ? S_WRITE : S_READ);
		  1'b1:
		    begin
		      if (bus.we)
			begin
			  if (bus.sel[3])
			    conf_next[31:24] = bus.dat_i[31:24];
			  if (bus.sel[2])
			    conf_next[23:16] = bus.dat_i[23:16];
			  if (bus.sel[1])
			    conf_next[15:8] = bus.dat_i[15:8];
			  if (bus.sel[0])
			    conf_next[7:0] = bus.dat_i[7:0];
			end
		      else
			result_next = conf;
		      state_next = S_DONE;
		    end
		endcase
	      end
	  end
	S_WRITE:
	  state_next = S_DONE;
	S_READ:
	  begin
	    if (rx_empty)
	      begin
		result_next[15:0] = { 2'b00, ~tx_full, 5'h00, rx_byte }; 
		state_next = S_DONE;
	      end
	    else
              state_next = S_READ2;
	  end
	S_READ2:
	  begin
	    rx_byte_next = rx_top;
	    state_next = S_READ3;
	  end
	S_READ3:
	  begin
	    result_next[15:0] = { 2'b10, ~tx_full, 5'h00, rx_byte };
	    state_next = S_DONE;
	  end
	S_DONE:
	  state_next = S_IDLE;
      endcase
    end
  
  // TX dequeue
  always_comb
    begin
      tx_shift_next = tx_shift;
      case (tx_shift)
	TX_IDLE:
	    if (tx_ready && ~tx_empty)
              tx_shift_next = TX_DEQUEUE;
	TX_DEQUEUE:
	  tx_shift_next = TX_START;
	TX_START:
	  tx_shift_next = TX_WAIT;
	TX_WAIT: 
	  if (~tx_ready)
            tx_shift_next = TX_IDLE;
      endcase
    end
  
  uart_tx #(.clkfreq(CLKFREQ),
	    .baud(BAUD)) tx0(.clk_i(clk_i),
			     .data(tx_top),
			     .start(tx_shift == TX_START),
			     .ready(tx_ready),
			     .serial_out(tx));

  uart_fifo tx_fifo0(.q(tx_top),
		     .empty(tx_empty),
		     .full(tx_full),
		     .data(bus.dat_i[7:0]),
		     .clock(clk_i),
		     .aclr(rst_i),
		     .wrreq(state == S_WRITE),
		     .rdreq(tx_shift == TX_DEQUEUE));
  
  uart_rx #(.CLKFREQ(CLKFREQ),
	    .BAUD(BAUD)) rx0(.clk_i(clk_i),
			     .rst_i(rst_i),
			     .data(rx_in),
			     .ready(rx_queue),
			     .serial_in(rx));
  uart_fifo rx_fifo0(.q(rx_top),
		     .empty(rx_empty),
		     .full(rx_full),
		     .data(rx_in),
		     .clock(clk_i),
		     .aclr(rst_i),
		     .wrreq(rx_queue),
		     .rdreq(state == S_READ));
  
endmodule
