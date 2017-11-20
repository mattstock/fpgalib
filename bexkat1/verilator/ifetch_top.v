module top(input         clk_i,
	   input 	 rst_i,
	   output [63:0] ir_o,
	   output [31:0] pc_o,
	   output [31:0] bus_dat_i,
	   input [31:0]  pc_i,
	   input 	 pc_set,
	   input 	 stall_i,
	   output 	 stall_o,
	   output 	 bus_cyc_o,
	   output 	 bus_ack_i);

  logic 		 ack0_o;
  logic [31:0] 		 dat0_o;
  
  ifetch fetch0(.clk_i(clk_i), .rst_i(rst_i),
		.ir(ir_o),
		.pc(pc_o),
		.stall_o(stall_o),
		.bus_cyc(bus_cyc_o),
		.stall_i(stall_i),
		.bus_ack(bus_ack_i),
		.bus_in(bus_dat_i),
		.pc_set(pc_set),
		.pc_in(pc_i));
  
  ram2 #(.AWIDTH(15)) ram0(.clk_i(clk_i), .rst_i(rst_i),
			   .cyc0_i(1'b0), .stb0_i(1'b0),
			   .sel0_i(4'h0), .we0_i(1'b0),
			   .adr0_i(15'h0), .dat0_i(32'h0),
			   .dat0_o(dat0_o), .ack0_o(ack0_o),
			   .cyc1_i(bus_cyc_o), .stb1_i(1'b1),
			   .adr1_i(pc_o[16:2]), .ack1_o(bus_ack_i),
			   .dat1_o(bus_dat_i));
  
endmodule // top
