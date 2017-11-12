module top(input  clk_i,
	   input  rst_i,
	   output halt);
   
   wire 	  ins_cyc, dat_cyc, ins_ack, dat_ack, dat_we;
   wire [3:0] 	  dat_sel;
   wire [31:0] 	  dat_adr, ins_adr;
   wire [31:0] 	  ins_dat, dat_cpu_out, dat_cpu_in;

   /* verilator lint_off PINMISSING */
   bexkat1p cpu0(.clk_i(clk_i), .rst_i(rst_i),
		 .ins_cyc_o(ins_cyc), .ins_ack_i(ins_ack),
		 .ins_adr_o(ins_adr), .ins_dat_i(ins_dat),
		 .halt(halt), .inter(3'h0),
		 .dat_cyc_o(dat_cyc), .dat_ack_i(dat_ack),
		 .dat_adr_o(dat_adr), .dat_we_o(dat_we),
		 .dat_sel_o(dat_sel),
		 .dat_dat_i(dat_cpu_in), .dat_dat_o(dat_cpu_out));
   /* verilator lint_on PINMISSING */
   
   ram2 #(.AWIDTH(15)) ram0(.clk_i(clk_i), .rst_i(rst_i),
			  .cyc0_i(dat_cyc), .stb0_i(1'b1),
			  .sel0_i(dat_sel), .we0_i(dat_we),
			  .adr0_i(dat_adr[16:2]), .dat0_i(dat_cpu_out),
			  .dat0_o(dat_cpu_in), .ack0_o(dat_ack),
			  .cyc1_i(ins_cyc), .stb1_i(1'b1),
			  .adr1_i(ins_adr[16:2]), .ack1_o(ins_ack),
			  .dat1_o(ins_dat));
  
endmodule // top
