module top(input         clk_i,
	   input 	 rst_i,
	   output [63:0] if_ir,
	   output [63:0] id_ir,
	   output [31:0] if_pc,
	   output [31:0] id_pc,
	   output [31:0] bus_dat_i,
	   input [31:0]  pc_i,
	   input 	 pc_set,
	   input 	 stall_i,
	   output 	 if_stall,
	   output 	 id_stall,
	   output [31:0] reg_data_out1,
	   output [31:0] reg_data_out2,
	   input [31:0]  reg_data_in,
	   input [3:0] 	 reg_write_addr,
	   input [1:0] 	 reg_write,
	   output 	 bus_cyc_o,
	   output 	 bus_ack_i);

  logic 		 ack0_o;
  logic [31:0] 		 dat0_o;
  logic 		 if_stall, id_stall;
			 
  ifetch fetch0(.clk_i(clk_i), .rst_i(rst_i),
		.ir(if_ir),
		.pc(if_pc),
		.stall_o(if_stall),
		.bus_cyc(bus_cyc_o),
		.stall_i(stall_i),
		.bus_ack(bus_ack_i),
		.bus_in(bus_dat_i),
		.pc_set(pc_set),
		.pc_in(pc_i));

  idecode decode0(.clk_i(clk_i), .rst_i(rst_i),
		  .ir_i(if_ir),
		  .ir_o(id_ir),
		  .stall_i(if_stall),
		  .stall_o(id_stall),
		  .pc_i(if_pc),
		  .pc_o(id_pc),
		  .reg_data_in(reg_data_in),
		  .reg_write_addr(reg_write_addr),
		  .reg_write(reg_write),
		  .reg_data_out1(reg_data_out1),
		  .reg_data_out2(reg_data_out2));
  
  ram2 #(.AWIDTH(15)) ram0(.clk_i(clk_i), .rst_i(rst_i),
			   .cyc0_i(1'b0), .stb0_i(1'b0),
			   .sel0_i(4'h0), .we0_i(1'b0),
			   .adr0_i(15'h0), .dat0_i(32'h0),
			   .dat0_o(dat0_o), .ack0_o(ack0_o),
			   .cyc1_i(bus_cyc_o), .stb1_i(1'b1),
			   .adr1_i(if_pc[16:2]), .ack1_o(bus_ack_i),
			   .dat1_o(bus_dat_i));
  
endmodule // top
