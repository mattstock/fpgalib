`timescale 1ns / 1ns
`define NO_MODPORT_EXPRESSIONS
`include "bexkat1.vh"
`include "wb.vh"
  
module top(input         clk_i,
	   input 	 rst_i,
	   input [2:0] 	 interrupts,
	   output [63:0] if_ir,
	   output [63:0] id_ir,
	   output [63:0] exe_ir,
	   output [63:0] mem_ir,
	   output [31:0] if_pc,
	   output [31:0] id_pc,
	   output [31:0] exe_pc,
	   output [31:0] mem_pc,
	   output 	 exe_pc_set,
	   output 	 mem_pc_set,
	   output [31:0] exe_data1,
	   output [31:0] exe_data2,
	   output [31:0] id_reg_data_out1,
	   output [31:0] exe_reg_data_out1,
	   output [31:0] exe_sp_in,
	   output [31:0] exe_result,
	   output 	 exe_halt,
	   output 	 mem_halt,
	   output 	 exe_stall,
	   output 	 mem_stall,
	   output 	 exe_exc,
	   output 	 mem_exc,
	   output 	 int_en,
	   output [31:0] mem_result,
	   output [31:0] id_reg_data_out2,
	   output [31:0] exe_reg_data_out2,
	   output [3:0]  mem_reg_write_addr,
	   output [1:0]  id_reg_write,
	   output [1:0]  exe_reg_write,
	   output [1:0]  mem_reg_write,
	   output [1:0]  id_sp_write,
	   output [1:0]  exe_sp_write,
	   output [1:0]  mem_sp_write,
	   output [31:0] id_sp_data,
	   output [31:0] exe_sp_data,
	   output [31:0] mem_sp_data,
	   output 	 hazard_stall,
	   output [2:0]  hazard1,
	   output [2:0]  hazard2,
	   output [1:0]  sp_hazard,
	   output [2:0]  exe_ccr,
	   output [3:0]  id_bank,
	   output [3:0]  exe_bank,
	   output [3:0]  mem_bank,
	   output 	 supervisor,
	   output 	 arb_we_o,
	   output 	 arb_ack_i,
	   output 	 arb_cyc_o,
	   output 	 arb_stall_i,
	   output 	 arb_stb_o,
	   output [3:0]  arb_sel_o,
	   output [31:0] arb_dat_i,
	   output [31:0] arb_dat_o,
	   output [14:0] arb_adr_o,
	   output [31:0] ins_adr_o,
	   output 	 ins_stall_i,
	   output 	 ins_ack_i,
	   output 	 ins_cyc_o,
	   output 	 ins_stb_o,
	   output [31:0] ins_dat_i,
	   output [31:0] dat_adr_o,
	   output 	 dat_cyc_o,
	   output 	 dat_ack_i,
	   output 	 dat_stb_o,
	   output 	 dat_stall_i,
	   output [31:0] dat_dat_i,
	   output 	 dat_we_o,
	   output [3:0]  dat_sel_o,
	   output [31:0] dat_dat_o);
   
  if_wb ins_bus();
  if_wb dat_bus();
  if_wb arb_bus();

  assign arb_we_o = arb_bus.we;
  assign arb_ack_i = arb_bus.ack;
  assign arb_stall_i = arb_bus.stall;
  assign arb_stb_o = arb_bus.stb;
  assign arb_sel_o = arb_bus.sel;
  assign arb_dat_i = arb_bus.dat_m;
  assign arb_dat_o = arb_bus.dat_s;
  assign arb_adr_o = arb_bus.adr[14:0];
  assign arb_cyc_o = arb_bus.cyc;
  assign ins_adr_o = ins_bus.adr;
  assign ins_ack_i = ins_bus.ack;
  assign ins_cyc_o = ins_bus.cyc;
  assign ins_stall_i = ins_bus.stall;
  assign ins_stb_o = ins_bus.stb;
  assign ins_dat_i = ins_bus.dat_s;
  assign dat_adr_o = dat_bus.adr;
  assign dat_cyc_o = dat_bus.cyc;
  assign dat_ack_i = dat_bus.ack;
  assign dat_stb_o = dat_bus.stb;
  assign dat_dat_i = dat_bus.dat_s;
  assign dat_we_o = dat_bus.we;
  assign dat_stall_i = dat_bus.stall;
  assign dat_sel_o = dat_bus.sel;
  assign dat_dat_o = dat_bus.dat_m;
   
  ifetch fetch0(.clk_i(clk_i), .rst_i(rst_i),
		.ir(if_ir),
		.pc(if_pc),
		.halt(exe_halt|mem_halt),
		.stall_i(hazard_stall|exe_stall|
			 mem_stall),
		.bus(ins_bus.master),
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
		  .stall_i(exe_stall|mem_stall),
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
	       .stall_i(mem_stall),
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

  memwb mem1(.clk_i(clk_i), .rst_i(rst_i),
	     .stall_i(exe_stall|mem_stall),
	     .halt_i(exe_halt),
	     .halt_o(mem_halt),
	     .bank_i(exe_bank),
	     .bank_o(mem_bank),
	     .reg_write_i(exe_reg_write),
	     .reg_write_o(mem_reg_write),
	     .exc_i(exe_exc),
	     .exc_o(mem_exc),
	     .sp_data_i(exe_sp_data),
	     .sp_data_o(mem_sp_data),
	     .reg_write_addr(mem_reg_write_addr),
	     .ir_i((exe_halt ? 64'h0 : exe_ir)),
	     .ir_o(mem_ir));
			
  mem mem0(.clk_i(clk_i), .rst_i(rst_i),
	   .reg_data1_i(exe_reg_data_out1),
	   .reg_data2_i(exe_reg_data_out2),
	   .stall_i(exe_stall),
	   .stall_o(mem_stall),
	   .result_i(exe_result),
	   .result_o(mem_result),
	   .sp_write_i(exe_sp_write),
	   .sp_write_o(mem_sp_write),
	   .sp_data_i(exe_sp_data),
	   .pc_i(exe_pc),
	   .pc_o(mem_pc),
	   .pc_set_i(exe_pc_set),
	   .pc_set_o(mem_pc_set),
	   .ir_i((exe_halt ? 64'h0 : exe_ir)),
	   .exc_i(exe_exc),
	   .bus(dat_bus.master));

   buscontrol bus0(.clk_i(clk_i), .rst_i(rst_i),
		   .ins_bus(ins_bus.slave),
		   .dat_bus(dat_bus.slave),
		   .mem_bus(arb_bus.master));

  ram ram0(.clk_i(clk_i), .rst_i(rst_i),
	   .bus(arb_bus));
   
endmodule // top
