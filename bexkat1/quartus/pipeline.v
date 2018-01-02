`include "../bexkat1.vh"

module pipeline(input              raw_clock_50,
		output logic [7:0] hex0,
		output logic [7:0] hex1,
		output logic [7:0] hex2,
		output logic [7:0] hex3,
		output logic [7:0] hex4,
		output logic [7:0] hex5,
		input [1:0] 	   key,
		input 		   rxd,
		output logic 	   txd,
		input 		   cts,
		output logic 	   rts,
		output logic [9:0] ledr);

  logic 			   locked;
  logic 			   supervisor;
  logic [3:0] 			   exception;
  logic 			   halt;
  logic 			   rst_i;
  logic [2:0] 			   inter;
  logic 			   clk_i;
  logic 			   int_en;
  
  if_wb extbus();
  
  assign txd = rxd;
  assign rts = cts;
  assign inter = 3'h0;
  assign ledr = { 2'b1, rxd, cts, locked, supervisor, halt,
		  extbus.cyc, extbus.ack, extbus.we};
  
  
  bexkat1p cpu0(.clk_i(clk_i), .rst_i(rst_i),
		.halt(halt), .inter(inter),
		.exception(exception),
		.supervisor(supervisor),
		.int_en(int_en),
		.bus(extbus.master));
  
  logic 			   ddelay[2:0];
  logic 			   idelay[2:0];
  
  assign extbus.ack = ddelay[2];
  assign extbus.stall = 1'b0;
  
  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	ddelay[0] <= 1'b0;
	ddelay[1] <= 1'b0;
	ddelay[2] <= 1'b0;
      end
    else
      begin
	ddelay[2] <= ddelay[1];
	ddelay[1] <= ddelay[0];
	ddelay[0] <= extbus.cyc;
      end // else: !if(rst_i)
  
  assign rst_i = ~locked;
  
  logic arst;
  
  sysclk clk0(.inclk0(raw_clock_50),
	      .c0(clk_i), .areset(arst), .locked(locked));
  
  mram ram0(.clock(clk_i),
	    .data(extbus.dat_m),
	    .address(extbus.adr[16:2]),
	    .wren(extbus.we),
	    .byteena(extbus.sel),
	    .q(extbus.dat_s));
  
  logic [24:0] display;
  
  assign display = (key[1] ? extbus.adr[24:0] : extbus.dat_s[24:0]);
  
  debounce #(.WIDTH(1)) pb0(.clk(raw_clock_50), .reset_n(1'b1), .data_in(~key[0]), 
			    .data_out(arst));
  
  hexdisp h0(display[3:0], hex0);
  hexdisp h1(display[7:4], hex1);
  hexdisp h2(display[11:8], hex2);
  hexdisp h3(display[15:12], hex3);
  hexdisp h4(display[19:16], hex4);
  hexdisp h5(display[23:20], hex5);
  
endmodule // top
