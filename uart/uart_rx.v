module uart_rx
  #(CLKFREQ = 50000000,
    BAUD = 9600)
  (input        clk_i,
   input 	rst_i,
   output [7:0] data,
   output 	ready,
   input 	serial_in);

  logic [3:0] 	state, state_next;
  logic [7:0] 	result, result_next;
  logic [2:0] 	bit_spacing, bit_spacing_next;
  logic 	next_bit;
  logic 	baud8clk;
  logic 	rx_bit, rx_bit_next;
  logic [1:0] 	rx_sync, rx_sync_next;
  logic [1:0] 	rx_count, rx_count_next;

  assign data = result;
  assign ready = (state == 4'b0010 && next_bit && rx_bit);
  assign next_bit = baud8clk && (bit_spacing == 'h7);

  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	state <= 4'h0;
	result <= 8'h0;
	bit_spacing <= 3'h0;
	rx_sync <= 2'h0;
	rx_count <= 2'h0;
	rx_bit <= 1'h0;
      end
    else
      begin
	state <= state_next;
	result <= result_next;
	bit_spacing <= bit_spacing_next;
	rx_sync <= rx_sync_next;
	rx_count <= rx_count_next;
	rx_bit <= rx_bit_next;
      end

  always_comb
    begin
      state_next = state;
      rx_sync_next = rx_sync;
      rx_count_next = rx_count;
      rx_bit_next = rx_bit;
      if (baud8clk)
	begin
	  rx_sync_next = {rx_sync[0], serial_in};
	  if (rx_sync[1] && rx_count != 2'b11)
	    rx_count_next = rx_count + 1'b1;
	  else
	    if (~rx_sync[1] && rx_count != 2'b00)
	      rx_count_next = rx_count - 1'b1;
	  if (rx_count == 2'b00)
	    rx_bit_next = 1'b0;
	  else
	    if (rx_count == 2'b11)
	      rx_bit_next = 1'b1;
	  case (state)
	    4'b0000: if (~rx_bit) state_next <= 4'b1000;
	    4'b0001: if (next_bit) state_next <= 4'b1000;
	    4'b1000: if (next_bit) state_next <= 4'b1001;
	    4'b1001: if (next_bit) state_next <= 4'b1010;
	    4'b1010: if (next_bit) state_next <= 4'b1011;
	    4'b1011: if (next_bit) state_next <= 4'b1100;
	    4'b1100: if (next_bit) state_next <= 4'b1101;
	    4'b1101: if (next_bit) state_next <= 4'b1110;
	    4'b1110: if (next_bit) state_next <= 4'b1111;
	    4'b1111: if (next_bit) state_next <= 4'b0010;
	    4'b0010: if (next_bit) state_next <= 4'b0000;
	    default: state_next <= 4'b0000;
	  endcase // case (state)
	end // if (baud8clk)
      end // else: !if(rst_i)

  always_comb
    begin
      bit_spacing_next = bit_spacing;
      result_next = result;
      if (state == 4'h0)
	bit_spacing_next = 3'h0;
      else
	if (baud8clk)
	  bit_spacing_next = bit_spacing + 3'h1;
      if (baud8clk && next_bit && state[3])
	result_next = {rx_bit, result[7:1]};
    end
  
baudgen #(.clkfreq(CLKFREQ), .baud(8*BAUD)) rxbaud(.clk_i(clk_i), .enable(1'b1), .baudclk(baud8clk));

endmodule
