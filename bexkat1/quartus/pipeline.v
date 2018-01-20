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
  
  if_wb ins_bus();
  if_wb dat_bus();

  assign txd = rxd;
  assign rts = cts;
  assign inter = 3'h0;
  assign ledr = { rxd, cts, locked, supervisor, halt,
		  ins_bus.cyc, ins_bus.ack,
		  dat_bus.cyc, dat_bus.ack, dat_bus.we};
  
  
  bexkat1p cpu0(.clk_i(clk_i), .rst_i(rst_i),
		.halt(halt), .inter(inter),
		.exception(exception),
		.supervisor(supervisor),
		.int_en(int_en),
		.ins_bus(ins_bus.master),
		.dat_bus(dat_bus.master));
  
  logic 			   ddelay[2:0];
  logic 			   idelay[2:0];
  
  assign ins_bus.ack = idelay[2];
  assign dat_bus.ack = ddelay[2];
  assign ins_bus.stall = 1'b0;
  assign dat_bus.stall = 1'b0;
  
  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	ddelay[0] <= 1'b0;
	ddelay[1] <= 1'b0;
	ddelay[2] <= 1'b0;
	idelay[0] <= 1'b0;
	idelay[1] <= 1'b0;
	idelay[2] <= 1'b0;
      end
    else
      begin
	ddelay[2] <= ddelay[1];
	ddelay[1] <= ddelay[0];
	ddelay[0] <= dat_bus.cyc;
	idelay[2] <= idelay[1];
	idelay[1] <= idelay[0];
	idelay[0] <= ins_bus.cyc;
      end // else: !if(rst_i)
  
  assign rst_i = ~locked;
  
  logic arst;
  
  sysclk clk0(.inclk0(raw_clock_50),
	      .c0(clk_i), .areset(arst), .locked(locked));
  
  mram ram0(.clock(clk_i),
	    .data_a(ins_bus.dat_m),
	    .address_a(ins_bus.adr[16:2]),
	    .wren_a(ins_bus.we),
	    .byteena_a(ins_bus.sel),
	    .q_a(ins_bus.dat_s),
	    .data_b(dat_bus.dat_m),
	    .address_b(dat_bus.adr[16:2]),
	    .wren_b(dat_bus.we),
	    .byteena_b(dat_bus.sel),
	    .q_b(dat_bus.dat_s));
  
  logic [24:0] display;
  
  assign display = (key[1] ? ins_bus.adr[24:0] : ins_bus.dat_s[24:0]);
  
  debounce #(.WIDTH(1)) pb0(.clk(raw_clock_50), .reset_n(1'b1), .data_in(~key[0]), 
			    .data_out(arst));
  
  hexdisp h0(display[3:0], hex0);
  hexdisp h1(display[7:4], hex1);
  hexdisp h2(display[11:8], hex2);
  hexdisp h3(display[15:12], hex3);
  hexdisp h4(display[19:16], hex4);
  hexdisp h5(display[23:20], hex5);
  
endmodule // top
