module pipeline(input              raw_clock_50,
		output logic [7:0] hex0,
		output logic [7:0] hex1,
		output logic [7:0] hex2,
		output logic [7:0] hex3,
		output logic [7:0] hex4,
		output logic [7:0] hex5,
		input [1:0] 	   key,
		output logic [9:0] ledr);

   logic 			   locked;
   logic 			   supervisor;
   logic [3:0] 			   exception;
   logic 			   halt;
   logic 			   ins_cyc;
   logic 			   dat_cyc;
   logic 			   dat_we;
   logic 			   rst_i;
   logic 			   dat_ack;
   logic [3:0] 			   dat_sel;
   logic [31:0] 		   dat_adr;
   logic [31:0] 		   ins_adr;
   logic [31:0] 		   ins_dat;
   logic [31:0] 		   dat_cpu_out;
   logic [31:0] 		   dat_cpu_in;
   logic 			   ins_ack;
   logic [3:0] 			   ins_sel;
   logic 			   int_en;
   logic 			   ins_we;
   logic [2:0] 			   inter;

   assign inter = 3'h0;
   

   assign ledr = { 1'b1, locked, supervisor, halt,
		   dat_cyc, dat_ack, dat_we,
		   ins_cyc, ins_ack, ins_we};
   
   bexkat1p cpu0(.clk_i(clk_i), .rst_i(rst_i),
		 .ins_cyc_o(ins_cyc), .ins_ack_i(ins_ack),
		 .ins_adr_o(ins_adr), .ins_dat_i(ins_dat),
		 .ins_sel_o(ins_sel),
		 .ins_we_o(ins_we),
		 .halt(halt), .inter(inter),
		 .exception(exception),
		 .supervisor(supervisor),
		 .int_en(int_en),
		 .dat_cyc_o(dat_cyc), .dat_ack_i(dat_ack),
		 .dat_adr_o(dat_adr), .dat_we_o(dat_we),
		 .dat_sel_o(dat_sel),
		 .dat_dat_i(dat_cpu_in), .dat_dat_o(dat_cpu_out));

   logic 		 ddelay[2:0];
   logic 		 idelay[2:0];
   
   assign dat_ack = ddelay[2];
   assign ins_ack = idelay[2];
   
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
	     ddelay[0] <= dat_cyc;
	     idelay[2] <= idelay[1];
	     idelay[1] <= idelay[0];
	     idelay[0] <= ins_cyc;
	  end // else: !if(rst_i)

   assign rst_i = ~locked;
   
   sysclk clk0(.inclk0(raw_clock_50),
	       .c0(clk_i), .areset(~key[0]), .locked(locked));
   
   qram ram0(.clock(clk_i),
	     .data_a(32'h0),
	     .wren_a(1'b0),
	     .address_a(ins_adr[16:2]),
	     .q_a(ins_dat),
	     .data_b(dat_cpu_out),
	     .address_b(dat_adr[16:2]),
	     .wren_b(dat_we),
	     .byteena_b(dat_sel),
	     .q_b(dat_cpu_in));

   logic [24:0] display;

   assign display = (key[1] ? ins_adr[24:0] : ins_dat[24:0]);
   
   hexdisp h0(display[3:0], hex0);
   hexdisp h1(display[7:4], hex1);
   hexdisp h2(display[11:8], hex2);
   hexdisp h3(display[15:12], hex3);
   hexdisp h4(display[19:16], hex4);
   hexdisp h5(display[23:20], hex5);
   
endmodule // top
