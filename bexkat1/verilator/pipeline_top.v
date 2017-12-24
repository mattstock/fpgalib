module top(input         clk_i,
	   input 	       rst_i,
	   input [2:0] 	       interrupts,
	   output [63:0]       if_ir,
	   output [63:0]       id_ir,
	   output [63:0]       exe_ir,
	   output [63:0]       mem_ir,
	   output [31:0]       if_pc,
	   output [31:0]       id_pc,
	   output [31:0]       exe_pc,
	   output [31:0]       mem_pc,
	   output 	       exe_pc_set,
	   output 	       mem_pc_set,
	   output [31:0]       exe_data1,
	   output [31:0]       exe_data2,
	   output [31:0]       id_reg_data_out1,
	   output [31:0]       exe_reg_data_out1,
	   output [31:0]       exe_sp_in,
	   output [31:0]       exe_result,
	   output 	       exe_halt,
	   output 	       mem_halt,
	   output 	       exe_stall,
	   output 	       mem_stall,
	   output 	       ins_stall_i,
	   output 	       dat_stall_i,
	   output 	       exe_exc,
	   output 	       mem_exc,
	   output 	       int_en,
	   output [31:0]       mem_result,
	   output [31:0]       id_reg_data_out2,
	   output [31:0]       exe_reg_data_out2,
	   output [3:0]        mem_reg_write_addr,
	   output [1:0]        id_reg_write,
	   output [1:0]        exe_reg_write,
	   output [1:0]        mem_reg_write,
	   output [1:0]        id_sp_write,
	   output [1:0]        exe_sp_write,
	   output [1:0]        mem_sp_write,
	   output [31:0]       id_sp_data,
	   output [31:0]       exe_sp_data,
	   output [31:0]       mem_sp_data,
	   output 	       hazard_stall,
	   output [2:0]        hazard1,
	   output [2:0]        hazard2,
	   output [1:0]        sp_hazard,
	   output [2:0]        exe_ccr,
	   output [3:0]        id_bank,
	   output [3:0]        exe_bank,
	   output [3:0]        mem_bank,
	   output 	       supervisor,
	   output logic        arb_we_o,
	   output logic        arb_ack_i,
	   output logic        arb_stall_i,
	   output logic        arb_stb_o,
	   output logic [3:0]  arb_sel_o,
	   output logic [31:0] arb_dat_i,
	   output logic [31:0] arb_dat_o,
	   output logic [14:0] arb_adr_o,
	   output [31:0]       ins_adr_o,
	   output 	       ins_cyc_o,
	   output 	       ins_ack_i,
	   output [31:0]       ins_dat_i,
	   output [31:0]       dat_adr_o,
	   output 	       dat_cyc_o,
	   output 	       dat_ack_i,
	   output 	       dat_stb_o,
	   output [31:0]       dat_dat_i,
	   output 	       dat_we_o,
	   output [3:0]        dat_sel_o,
	   output [31:0]       dat_dat_o);
  
  ifetch fetch0(.clk_i(clk_i), .rst_i(rst_i),
		.ir(if_ir),
		.pc(if_pc),
		.stall_i(hazard_stall|exe_halt|exe_stall|
			 mem_stall|dat_stall_i),
		.bus_stall_i(ins_stall_i|dat_stall_i),
		.bus_adr(ins_adr_o),
		.bus_cyc(ins_cyc_o),
		.bus_ack(ins_ack_i),
		.bus_in(ins_dat_i),
		.pc_set(mem_pc_set),
		.pc_in(mem_pc));

  idecode decode0(.clk_i(clk_i), .rst_i(rst_i),
		  .ir_i((hazard_stall|
			 exe_exc|
			 exe_pc_set|
			 mem_pc_set ? 64'h0 : if_ir)),
		  .ir_o(id_ir),
		  .pc_i(if_pc),
		  .pc_o(id_pc),
		  .bank_i(mem_bank),
		  .bank_o(id_bank),
		  .supervisor_i(supervisor),
		  .stall_i(exe_stall|mem_stall|dat_stall_i),
		  .sp_write_i(mem_sp_write),
		  .sp_write_o(id_sp_write),
		  .sp_data_i(mem_sp_data),
		  .sp_data_o(id_sp_data),
		  .reg_data_in(mem_result),
		  .reg_write_addr(mem_reg_write_addr),
		  .reg_write_i(mem_reg_write),
		  .reg_write_o(id_reg_write),
		  .reg_data_out1(id_reg_data_out1),
		  .reg_data_out2(id_reg_data_out2));

  hazard hazard0(.clk_i(clk_i), .rst_i(rst_i),
		 .if_ir(if_ir),
		 .id_ir(id_ir),
		 .id_reg_write(id_reg_write),
		 .exe_ir(exe_ir),
		 .exe_reg_write(exe_reg_write),
		 .mem_ir(mem_ir),
		 .mem_reg_write(mem_reg_write),
		 .id_sp_write(id_sp_write),
		 .exe_sp_write(exe_sp_write),
		 .mem_sp_write(mem_sp_write),
		 .stall(hazard_stall),
		 .hazard1(hazard1),
		 .hazard2(hazard2),
		 .sp_hazard(sp_hazard));
		
  always_comb
    begin
      case (hazard1) 
	3'h0: exe_data1 = id_reg_data_out1;
	3'h1: exe_data1 = mem_result;
	3'h2: exe_data1 = exe_result;
	3'h3: exe_data1 = mem_sp_data;
	3'h4: exe_data1 = exe_sp_data;
	default: exe_data1 = id_reg_data_out1;
      endcase // case (hazard1)
      case (hazard2) 
	3'h0: exe_data2 = id_reg_data_out2;
	3'h1: exe_data2 = mem_result;
	3'h2: exe_data2 = exe_result;
	3'h3: exe_data2 = mem_sp_data;
	3'h4: exe_data2 = exe_sp_data;
	default : exe_data2 = id_reg_data_out2;
      endcase // case (hazard2)
      case (sp_hazard)
	2'h0: exe_sp_in = id_sp_data;
	2'h1: exe_sp_in = exe_sp_data;
	2'h2: exe_sp_in = mem_sp_data;
	2'h3: exe_sp_in = id_sp_data;
      endcase // case (sp_hazard)
    end // always_comb
  
  execute exe0(.clk_i(clk_i), .rst_i(rst_i),
	       .reg_data1_i(exe_data1),
	       .reg_data1_o(exe_reg_data_out1),
	       .reg_data2_i(exe_data2),
	       .reg_data2_o(exe_reg_data_out2),
	       .result(exe_result),
	       .reg_write_i((exe_exc|exe_pc_set ? 2'h0 : id_reg_write)),
	       .reg_write_o(exe_reg_write),
	       .halt_o(exe_halt),
	       .stall_i(mem_stall|dat_stall_i),
	       .stall_o(exe_stall),
	       .sp_write_i(exe_pc_set ? 2'h0 : id_sp_write),
	       .sp_write_o(exe_sp_write),
	       .sp_data_i(exe_sp_in),
	       .sp_data_o(exe_sp_data),
	       .bank_i(id_bank),
	       .bank_o(exe_bank),
	       .pc_i(id_pc),
	       .pc_o(exe_pc),
	       .pc_set_o(exe_pc_set),
	       .supervisor(supervisor),
	       .interrupts(interrupts),
	       .interrupts_enabled(int_en),
	       .exc_o(exe_exc),
	       .ir_i((exe_exc|exe_pc_set ? 64'h0 : id_ir)),
	       .ir_o(exe_ir),
	       .ccr_o(exe_ccr));
  
  mem mem0(.clk_i(clk_i), .rst_i(rst_i),
	   .reg_data1_i(exe_reg_data_out1),
	   .reg_data2_i(exe_reg_data_out2),
	   .reg_write_i(exe_reg_write),
	   .reg_write_o(mem_reg_write),
	   .reg_write_addr(mem_reg_write_addr),
	   .result_i(exe_result),
	   .result_o(mem_result),
	   .bank_i(exe_bank),
	   .bank_o(mem_bank),
	   .halt_i(exe_halt),
	   .halt_o(mem_halt),
	   .ir_i((exe_halt ? 64'h0 : exe_ir)),
	   .ir_o(mem_ir),
	   .stall_i(exe_stall|dat_stall_i),
	   .stall_o(mem_stall),
	   .sp_write_i(exe_sp_write),
	   .sp_write_o(mem_sp_write),
	   .sp_data_i(exe_sp_data),
	   .sp_data_o(mem_sp_data),
	   .exc_i(exe_exc),
	   .exc_o(mem_exc),
	   .pc_i(exe_pc),
	   .pc_o(mem_pc),
	   .pc_set_i(exe_pc_set),
	   .pc_set_o(mem_pc_set),
	   .bus_adr_o(dat_adr_o),
	   .bus_cyc_o(dat_cyc_o),
	   .bus_ack_i(dat_ack_i),
	   .bus_stb_o(dat_stb_o),
	   .bus_dat_i(dat_dat_i),
	   .bus_we_o(dat_we_o),
	   .bus_dat_o(dat_dat_o),
	   .bus_sel_o(dat_sel_o));

  arbiter arb0(.clk_i(clk_i), .rst_i(rst_i),
	       .cyc_i({ins_cyc_o, dat_cyc_o}),
	       .we_i({1'b0, dat_we_o}),
	       .sel_i('{4'hf, dat_sel_o}),
	       .adr_i('{ins_adr_o[16:2], dat_adr_o[16:2]}),
	       .m_dat_i('{32'h0, dat_dat_o}),
	       .m_dat_o('{ins_dat_i, dat_dat_i}),
	       .stall_o({ins_stall_i, dat_stall_i}),
	       .ack_o({ins_ack_i, dat_ack_i}),
	       .we_o(arb_we_o),
	       .adr_o(arb_adr_o),
	       .s_dat_o(arb_dat_o),
	       .ack_i(arb_ack_i),
	       .s_dat_i(arb_dat_i),
	       .stall_i(arb_stall_i),
	       .sel_o(arb_sel_o),
	       .stb_o(arb_stb_o));

  ram ram0(.clk_i(clk_i), .rst_i(rst_i),
	   .cyc_i(arb_stb_o),
	   .stb_i(arb_stb_o),
	   .sel_i(arb_sel_o),
	   .we_i(arb_we_o),
	   .adr_i(arb_adr_o),
	   .dat_i(arb_dat_o),
	   .dat_o(arb_dat_i),
	   .stall_o(arb_stall_i),
	   .ack_o(arb_ack_i));

  /*
  ram2 #(.AWIDTH(15)) ram0(.clk_i(clk_i), .rst_i(rst_i),
			   .cyc0_i(dat_cyc_o), .stb0_i(1'b1),
			   .sel0_i(dat_sel_o), .we0_i(dat_we_o),
			   .adr0_i(dat_adr_o[16:2]), .dat0_i(dat_dat_o),
			   .dat0_o(dat_dat_i), .ack0_o(dat_ack_i),
			   .cyc1_i(ins_cyc_o), .stb1_i(1'b1),
			   .adr1_i(if_pc[16:2]), .ack1_o(ins_ack_i),
			   .dat1_o(ins_dat_i));
  */
endmodule // top
