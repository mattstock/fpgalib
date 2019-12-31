`include "../wb.vh"

module spi_master
  #(CLKFREQ = 10000000,
    COUNT = 4)
  (
   input 	      clk_i,
   input 	      rst_i,
   input 	      miso,
   output 	      mosi,
   output 	      sclk,
   output [COUNT-1:0] selects,
   if_wb.slave        bus,
   input 	      wp);

  logic [31:0] 	      bus_dat_o, bus_dat_i;
  
// write
// 'h0: xxxxxxdd : spi byte out
// 'h1: sscfxixx : ss = selects, cf = config byte (speedselect, cpol, cpha)
// read
// 'h0: xxxxxxdd : spi byte in (clears ready flag)
// 'h1: sscfxiptr : ss = selects, cf = config byte, p = write protect, t = transmit ready, r = recv ready

`ifdef NO_MODPORT_EXPRESSIONS
  assign bus_dat_i = bus.dat_m;
  assign bus.dat_s = bus_dat_o;
`else
  assign bus_dat_i = bus.dat_i;
  assign bus.dat_o = bus_dat_o;
`endif
  
  logic 	      tx_start;
  logic 	      tx_done;
  logic [7:0] 	      rx_in;
  
  logic [7:0] 	      rx_byte, rx_byte_next;
  logic [COUNT-1:0]   selects_next;
  logic [7:0] 	      conf, conf_next;
  logic 	      state, state_next;
  logic 	      rx_unread, rx_unread_next;
  logic 	      tx_busy, tx_busy_next;
  logic [31:0] 	      dat_o_next;

  assign bus.ack = (state == S_DONE);
  assign bus.stall = 1'h0;
  
  typedef enum 	      bit { S_IDLE, S_DONE } state_t;

  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	rx_byte <= 8'h00;
	selects <= {COUNT{1'h1}};
	conf <= 'h00;
	bus_dat_o <= 32'h0;
	rx_unread <= 1'b0;
	tx_busy <= 1'b0;
	state <= S_IDLE;
      end
    else
      begin
	rx_byte <= rx_byte_next;
	selects <= selects_next;
	conf <= conf_next;
	bus_dat_o <= dat_o_next;
	state <= state_next;
	tx_busy <= tx_busy_next;
	rx_unread <= rx_unread_next;
      end

  always_comb
    begin
      rx_byte_next = rx_byte;
      conf_next = conf;
      selects_next = selects;
      dat_o_next = bus_dat_o;
      state_next = state;
      tx_busy_next = tx_busy;
      rx_unread_next = rx_unread;
      tx_start = 1'b0;
      
      case (state)
	S_IDLE:
	  begin
	    if (bus.cyc & bus.stb)
              case (bus.adr[2])
		1'h0:
		  begin
		    if (bus.we)
		      begin
			if (~tx_busy)
			  begin
			    tx_start = 1'b1;
			    tx_busy_next = 1'b1;
			  end
			state_next = S_DONE;
		      end
		    else
		      begin
			dat_o_next = { 24'h0, rx_byte };
			rx_unread_next = 1'b0;
			state_next = S_DONE;
		      end
		  end
		1'h1:
		  begin
		    if (bus.we)
		      begin
			if (bus.sel[3])
			  selects_next = bus_dat_i[COUNT-1+24:24];
			if (bus.sel[2])
			  conf_next = bus_dat_i[23:16];
		      end
		    else
		      begin
			dat_o_next = { selects, conf, 12'h00, 1'b1, 
				       wp, tx_busy, rx_unread };
		      end
		    state_next = S_DONE;
		  end
              endcase
	  end
	S_DONE: state_next = S_IDLE;
      endcase
      if (tx_done && tx_busy)
	begin
	  rx_byte_next = rx_in;
	  tx_busy_next = 1'b0;
	  rx_unread_next = 1'b1;
	end
    end
  
  spi_xcvr #(.CLKFREQ(CLKFREQ)) xcvr0(.clk_i(clk_i),
				      .rst_i(rst_i),
				      .conf(conf),
				      .start(tx_start),
				      .rx(rx_in),
				      .done(tx_done),
				      .tx(bus_dat_i[7:0]), 
				      .miso(miso),
				      .mosi(mosi),
				      .sclk(sclk));
  
endmodule
