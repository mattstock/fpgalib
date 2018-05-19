module top(input         clk_i,
	   input 	 rst_i,
	   output [63:0] if_ir,
	   output [63:0] id_ir,
	   output [63:0] exe_ir,
	   output [31:0] if_pc,
	   output [31:0] id_pc,
	   output [31:0] exe_pc,
	   output [31:0] bus_dat_i,
	   input [31:0]  pc_i,
	   input 	 pc_set,
	   input 	 stall_i,
	   output 	 if_stall,
	   output 	 id_stall,
	   output 	 exe_stall,
	   output [31:0] id_reg_data_out1,
	   output [31:0] exe_reg_data_out1,
	   output [31:0] exe_result,
	   output [31:0] id_reg_data_out2,
	   input [31:0]  wb_reg_data_in,
	   input [3:0] 	 wb_reg_write_addr,
	   input [1:0] 	 wb_reg_write,
	   output [1:0]  exe_reg_write,
	   output [2:0]  exe_ccr,
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
		  .reg_data_in(wb_reg_data_in),
		  .reg_write_addr(wb_reg_write_addr),
		  .reg_write(wb_reg_write),
		  .reg_data_out1(id_reg_data_out1),
		  .reg_data_out2(id_reg_data_out2));

  execute exe0(.clk_i(clk_i), .rst_i(rst_i),
	       .reg_data1_i(id_reg_data_out1),
	       .reg_data1_o(exe_reg_data_out1),
	       .reg_data2(id_reg_data_out2),
	       .result(exe_result),
	       .reg_write(exe_reg_write),
	       .stall_i(id_stall),
	       .stall_o(exe_stall),
	       .pc_i(id_pc),
	       .pc_o(exe_pc),
	       .ir_i(id_ir),
	       .ir_o(exe_ir),
	       .ccr_o(exe_ccr));
  
  ram2 #(.AWIDTH(15)) ram0(.clk_i(clk_i), .rst_i(rst_i),
			   .cyc0_i(1'b0), .stb0_i(1'b0),
			   .sel0_i(4'h0), .we0_i(1'b0),
			   .adr0_i(15'h0), .dat0_i(32'h0),
			   .dat0_o(dat0_o), .ack0_o(ack0_o),
			   .cyc1_i(bus_cyc_o), .stb1_i(1'b1),
			   .adr1_i(if_pc[16:2]), .ack1_o(bus_ack_i),
			   .dat1_o(bus_dat_i));
  
endmodule // top
