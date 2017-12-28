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
   logic 			   dat_cyc;
   logic 			   dat_we;
   logic 			   rst_i;
   logic 			   dat_ack;
   logic [3:0] 			   dat_sel;
   logic [31:0] 		   dat_adr;
   logic [31:0] 		   dat_cpu_out;
   logic [31:0] 		   dat_cpu_in;
   logic [2:0] 			   inter;
   logic 			   clk_i;
   logic 			   int_en;

   assign txd = rxd;
   assign rts = cts;
   assign inter = 3'h0;
   assign ledr = { 2'b1, rxd, cts, locked, supervisor, halt,
		   dat_cyc, dat_ack, dat_we};
   
   
   bexkat1p cpu0(.clk_i(clk_i), .rst_i(rst_i),
		 .halt(halt), .inter(inter),
		 .exception(exception),
		 .supervisor(supervisor),
		 .int_en(int_en),
		 .cyc_o(dat_cyc),
		 .ack_i(dat_ack),
		 .adr_o(dat_adr),
		 .we_o(dat_we),
		 .sel_o(dat_sel),
		 .dat_i(dat_cpu_in),
		 .dat_o(dat_cpu_out));

   logic 		 ddelay[2:0];
   logic 		 idelay[2:0];
   
   assign dat_ack = ddelay[2];
   
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
	     ddelay[0] <= dat_cyc;
	  end // else: !if(rst_i)

   assign rst_i = ~locked;

   logic arst;
   
   sysclk clk0(.inclk0(raw_clock_50),
	       .c0(clk_i), .areset(arst), .locked(locked));
   
   mram ram0(.clock(clk_i),
	     .data(dat_cpu_out),
	     .address(dat_adr[16:2]),
	     .wren(dat_we),
	     .byteena(dat_sel),
	     .q(dat_cpu_in));

   logic [24:0] display;

   assign display = (key[1] ? dat_adr[24:0] : dat_cpu_in[24:0]);

   debounce #(.WIDTH(1)) pb0(.clk(raw_clock_50), .reset_n(1'b1), .data_in(~key[0]), 
			     .data_out(arst));
   
   hexdisp h0(display[3:0], hex0);
   hexdisp h1(display[7:4], hex1);
   hexdisp h2(display[11:8], hex2);
   hexdisp h3(display[15:12], hex3);
   hexdisp h4(display[19:16], hex4);
   hexdisp h5(display[23:20], hex5);
   
endmodule // top
