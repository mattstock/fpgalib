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
	   output logic [31:0] exe_data1,
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
	   output 	 cpu_inter_en,
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
	   output [31:0] dat_dat_o,
	   output [31:0] cache0_adr_o,
	   output 	 cache0_cyc_o,
	   output 	 cache0_ack_i,
	   output 	 cache0_stb_o,
	   output 	 cache0_stall_i,
	   output [31:0] cache0_dat_i,
	   output 	 cache0_we_o,
	   output [3:0]  cache0_sel_o,
	   output [31:0] cache0_dat_o,
	   output [1:0]  cache_status,
	   output [31:0] ram0_adr_o,
	   output 	 ram0_cyc_o,
	   output 	 ram0_ack_i,
	   output 	 ram0_stb_o,
	   output 	 ram0_stall_i,
	   output [31:0] ram0_dat_i,
	   output 	 ram0_we_o,
	   output [3:0]  ram0_sel_o,
	   output [31:0] ram0_dat_o,
	   output [7:0]  hex0,
	   output [7:0]  hex1,
	   output [7:0]  hex2,
	   output [7:0]  hex3,
	   output [7:0]  hex4,
	   output [7:0]  hex5,
	   output [7:0]  hex6,
	   output [7:0]  hex7);
   
  if_wb ins_bus(), dat_bus();
  if_wb ram0_ibus(), ram0_dbus();
  if_wb ram1_ibus(), ram1_dbus();
  if_wb io_dbus(), io_seg();
  if_wb io_timer(), io_uart();
  if_wb cachebus0(), stats0(), sdram0();
  
  logic [3:0] 		 timer_interrupts;
  logic [1:0] 		 serial0_interrupts;
  logic [3:0] 		 cpu_exception;
  logic 		 bus0_error;
  
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
   
  assign cache0_adr_o = cachebus0.adr;
  assign cache0_cyc_o = cachebus0.cyc;
  assign cache0_ack_i = cachebus0.ack;
  assign cache0_stb_o = cachebus0.stb;
  assign cache0_dat_i = cachebus0.dat_s;
  assign cache0_we_o = cachebus0.we;
  assign cache0_stall_i = cachebus0.stall;
  assign cache0_sel_o = cachebus0.sel;
  assign cache0_dat_o = cachebus0.dat_m;

  assign ram0_adr_o = sdram0.adr;
  assign ram0_cyc_o = sdram0.cyc;
  assign ram0_ack_i = sdram0.ack;
  assign ram0_stb_o = sdram0.stb;
  assign ram0_dat_i = sdram0.dat_s;
  assign ram0_we_o = sdram0.we;
  assign ram0_stall_i = sdram0.stall;
  assign ram0_sel_o = sdram0.sel;
  assign ram0_dat_o = sdram0.dat_m;
  
  ifetch #(.REQ_MAX(8)) fetch0(.clk_i(clk_i), .rst_i(rst_i),
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
		  .pc_i(mem_pc_set ? mem_pc : if_pc),
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
	       .pc_i(mem_pc_set ? mem_pc : id_pc),
	       .pc_o(exe_pc),
	       .pc_mem_i(mem_pc),
	       .pc_set_i(mem_pc_set),
	       .pc_set_o(exe_pc_set),
	       .supervisor(supervisor),
	       .interrupts(interrupts),
	       .interrupts_enabled(cpu_inter_en),
	       .exc_i(mem_exc),
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
	   .pc_i(mem_pc_set ? mem_pc : exe_pc),
	   .pc_o(mem_pc),
	   .pc_set_i(exe_pc_set),
	   .pc_set_o(mem_pc_set),
	   .ir_i((exe_halt ? 64'h0 : exe_ir)),
	   .exc_i(exe_exc),
	   .exc_o(mem_exc),
	   .bus(dat_bus.master));

  assign bus0_error = (ins_bus.cyc & ins_bus.stb & !ram1_ibus.stb);

  interrupt_encoder intenc0(.clk_i(clk_i),
			    .rst_i(rst_i),
			    .mmu(bus0_error),
			    .timer_in(timer_interrupts),
			    .serial0_in(serial0_interrupts),
			    .enabled(cpu_inter_en),
			    .cpu_exception(cpu_exception));

  if_wb                       p0_bus2();
  if_wb p1_bus0(), p1_bus1(), p1_bus2();
  if_wb p2_bus0(), p2_bus1(), p2_bus2();
  if_wb p3_bus0(),            p3_bus2();
  if_wb p4_bus0(), p4_bus1(), p4_bus2();
  if_wb p5_bus0(), p5_bus1(), p5_bus2();
  if_wb p6_bus0(), p6_bus1(), p6_bus2();
  if_wb                       p7_bus2();
  if_wb p8_bus0(), p8_bus1(), p8_bus2();
  if_wb p9_bus0(), p9_bus1(), p9_bus2();
  if_wb pa_bus0(), pa_bus1(), pa_bus2();
  if_wb pb_bus0(), pb_bus1(), pb_bus2();
  if_wb pc_bus0(), pc_bus1(), pc_bus2();
  if_wb pd_bus0(), pd_bus1(), pd_bus2();
  if_wb pe_bus0(), pe_bus1(), pe_bus2();
  if_wb pf_bus0(), pf_bus1(), pf_bus2();

  mmu mmu_bus0(.clk_i(clk_i), .rst_i(rst_i),
	       .mbus(ins_bus.slave),
	       .p0(ram0_ibus.master),
	       .p1(p1_bus0.master),
	       .p2(p2_bus0.master),
	       .p3(p3_bus0.master),
	       .p4(p4_bus0.master),
	       .p5(p5_bus0.master),
	       .p6(p6_bus0.master),
	       .p7(ram1_ibus.master),
	       .p8(p8_bus0.master),
	       .p9(p9_bus0.master),
	       .pa(pa_bus0.master),
	       .pb(pb_bus0.master),
	       .pc(pc_bus0.master),
	       .pd(pd_bus0.master),
	       .pe(pe_bus0.master),
	       .pf(pf_bus0.master));

  bus_term bus0_p1(p1_bus0.slave);
  bus_term bus0_p2(p2_bus0.slave);
  bus_term bus0_p3(p3_bus0.slave);
  bus_term bus0_p4(p4_bus0.slave);
  bus_term bus0_p5(p5_bus0.slave);
  bus_term bus0_p6(p6_bus0.slave);
  bus_term bus0_p8(p8_bus0.slave);
  bus_term bus0_p9(p9_bus0.slave);
  bus_term bus0_pa(pa_bus0.slave);
  bus_term bus0_pb(pb_bus0.slave);
  bus_term bus0_pc(pc_bus0.slave);
  bus_term bus0_pd(pd_bus0.slave);
  bus_term bus0_pe(pe_bus0.slave);
  bus_term bus0_pf(pf_bus0.slave);
  
  mmu mmu_bus1(.clk_i(clk_i), .rst_i(rst_i),
	       .mbus(dat_bus.slave),
	       .p0(ram0_dbus.master),
	       .p1(p1_bus1.master),
	       .p2(p2_bus1.master),
	       .p3(io_dbus.master),
	       .p4(p4_bus1.master),
	       .p5(p5_bus1.master),
	       .p6(p6_bus1.master),
	       .p7(ram1_dbus.master),
	       .p8(p8_bus1.master),
	       .p9(p9_bus1.master),
	       .pa(pa_bus1.master),
	       .pb(pb_bus1.master),
	       .pc(pc_bus1.master),
	       .pd(pd_bus1.master),
	       .pe(pe_bus1.master),
	       .pf(pf_bus1.master));
  
  bus_term bus1_p1(p1_bus1.slave);
  bus_term bus1_p2(p2_bus1.slave);
  bus_term bus1_p4(p4_bus1.slave);
  bus_term bus1_p5(p5_bus1.slave);
  bus_term bus1_p6(p6_bus1.slave);
  bus_term bus1_p8(p8_bus1.slave);
  bus_term bus1_p9(p9_bus1.slave);
  bus_term bus1_pa(pa_bus1.slave);
  bus_term bus1_pb(pb_bus1.slave);
  bus_term bus1_pc(pc_bus1.slave);
  bus_term bus1_pd(pd_bus1.slave);
  bus_term bus1_pe(pe_bus1.slave);
  bus_term bus1_pf(pf_bus1.slave);
  
  mmu #(.BASE(12)) mmu_bus2(.clk_i(clk_i), .rst_i(rst_i),
			    .mbus(io_dbus.slave),
			    .p0(p0_bus2.master),
			    .p1(p1_bus2.master),
			    .p2(p2_bus2.master),
			    .p3(p3_bus2.master),
			    .p4(p4_bus2.master),
			    .p5(p5_bus2.master),
			    .p6(p6_bus2.master),
			    .p7(p7_bus2.master),
			    .p8(p8_bus2.master),
			    .p9(p9_bus2.master),
			    .pa(pa_bus2.master),
			    .pb(pb_bus2.master),
			    .pc(pc_bus2.master),
			    .pd(pd_bus2.master),
			    .pe(pe_bus2.master),
			    .pf(pf_bus2.master));
  
  bus_term bus2_p0(p0_bus2.slave);
  bus_term bus2_p1(p1_bus2.slave);
  bus_term bus2_p2(p2_bus2.slave);
  bus_term bus2_p3(p3_bus2.slave);
  bus_term bus2_p4(p4_bus2.slave);
  bus_term bus2_p5(p5_bus2.slave);
  bus_term bus2_p6(p6_bus2.slave);
  bus_term bus2_p7(p7_bus2.slave);
  bus_term bus2_p8(p8_bus2.slave);
  bus_term bus2_p9(p9_bus2.slave);
  bus_term bus2_pa(pa_bus2.slave);
  bus_term bus2_pb(pb_bus2.slave);
  bus_term bus2_pc(pc_bus2.slave);
  bus_term bus2_pd(pd_bus2.slave);
  bus_term bus2_pe(pe_bus2.slave);
  bus_term bus2_pf(pf_bus2.slave);

  arbiter arb0(.clk_i(clk_i),
	       .rst_i(rst_i),
	       .in0(ram0_ibus.slave),
	       .in1(ram0_dbus.slave),
	       .out(cachebus0.master));

  bus_term_m stats_bus(stats0.master);
  
  cache #(.AWIDTH(13), .TAGSIZE(7)) cache0(.clk_i(clk_i),
					   .rst_i(rst_i),
					   .inbus(cachebus0.slave),
					   .outbus(sdram0.master),
					   .cache_status(cache_status),
					   .stats(stats0.slave));
  
  ram #(.AWIDTH(13),
	.INITNAME("../clear.hex")) ram0(.clk_i(clk_i),
					.rst_i(rst_i),
					.bus(sdram0.slave));
  
  ram2 #(.AWIDTH(13)) ram1(.clk_i(clk_i), .rst_i(rst_i),
			   .bus0(ram1_ibus.slave),
			   .bus1(ram1_dbus.slave));
  
  segctrl #(.SEG(8)) io_seg0(.clk_i(clk_i), .rst_i(rst_i),
			     .bus(io_seg.slave),
			     .sw(10'h0),
			     .out0(hex0),
			     .out1(hex1),
			     .out2(hex2),
			     .out3(hex3),
			     .out4(hex4),
			     .out5(hex5),
			     .out6(hex6),
			     .out7(hex7));

  timerint timerint0(.clk_i(clk_i),
		     .rst_i(rst_i),
		     .bus(io_timer.slave),
		     .interrupt(timer_interrupts));
  
endmodule // top
