`timescale 1ns / 1ns
`define NO_MODPORT_EXPRESSIONS
`include "bexkat2.vh"
`include "wb.vh"
  
module top(input              clk_i,
	   input 	      rst_i,
	   input [2:0] 	      interrupts,
	   output 	      int_en,
	   output logic [3:0] exception,
	   output logic       supervisor,
	   output logic       halt,
	   output logic [1:0] cache_status,
	   output [31:0]      ins_adr_o,
	   output 	      ins_stall_i,
	   output 	      ins_ack_i,
	   output 	      ins_cyc_o,
	   output 	      ins_stb_o,
	   output [31:0]      ins_dat_i,
	   output [31:0]      dat_adr_o,
	   output 	      dat_cyc_o,
	   output 	      dat_ack_i,
	   output 	      dat_stb_o,
	   output 	      dat_stall_i,
	   output [31:0]      dat_dat_i,
	   output 	      dat_we_o,
	   output [3:0]       dat_sel_o,
	   output [31:0]      dat_dat_o,
	   output [31:0]      cache0_adr_o,
	   output 	      cache0_cyc_o,
	   output 	      cache0_ack_i,
	   output 	      cache0_stb_o,
	   output 	      cache0_stall_i,
	   output [31:0]      cache0_dat_i,
	   output 	      cache0_we_o,
	   output [3:0]       cache0_sel_o,
	   output [31:0]      cache0_dat_o,
	   output [31:0]      ram0_adr_o,
	   output 	      ram0_cyc_o,
	   output 	      ram0_ack_i,
	   output 	      ram0_stb_o,
	   output 	      ram0_stall_i,
	   output [31:0]      ram0_dat_i,
	   output 	      ram0_we_o,
	   output [3:0]       ram0_sel_o,
	   output [31:0]      ram0_dat_o);
   
  if_wb ins_bus(), dat_bus();
  if_wb ram0_ibus(), ram0_dbus();
  if_wb ram1_ibus(), ram1_dbus();
  if_wb cache0(), stats0(), sdram0();
  
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

  assign cache0_adr_o = cache0.adr;
  assign cache0_cyc_o = cache0.cyc;
  assign cache0_ack_i = cache0.ack;
  assign cache0_stb_o = cache0.stb;
  assign cache0_dat_i = cache0.dat_s;
  assign cache0_we_o = cache0.we;
  assign cache0_stall_i = cache0.stall;
  assign cache0_sel_o = cache0.sel;
  assign cache0_dat_o = cache0.dat_m;

  assign ram0_adr_o = ram0_dbus.adr;
  assign ram0_cyc_o = ram0_dbus.cyc;
  assign ram0_ack_i = ram0_dbus.ack;
  assign ram0_stb_o = ram0_dbus.stb;
  assign ram0_dat_i = ram0_dbus.dat_s;
  assign ram0_we_o = ram0_dbus.we;
  assign ram0_stall_i = ram0_dbus.stall;
  assign ram0_sel_o = ram0_dbus.sel;
  assign ram0_dat_o = ram0_dbus.dat_m;
  
  bexkat2 cpu0(.clk_i(clk_i), .rst_i(rst_i),
	       .ins_bus(ins_bus.master),
	       .dat_bus(dat_bus.master),
	       .halt(halt),
	       .int_en(int_en),
	       .inter(interrupts),
	       .exception(exception),
	       .supervisor(supervisor));
   
  if_wb p1_bus0(), p1_bus1();
  if_wb p2_bus0(), p2_bus1();
  if_wb p3_bus0(), p3_bus1();
  if_wb p4_bus0(), p4_bus1();
  if_wb p5_bus0(), p5_bus1();
  if_wb p6_bus0(), p6_bus1();
  if_wb p8_bus0(), p8_bus1();
  if_wb p9_bus0(), p9_bus1();
  if_wb pa_bus0(), pa_bus1();
  if_wb pb_bus0(), pb_bus1();
  if_wb pc_bus0(), pc_bus1();
  if_wb pd_bus0(), pd_bus1();
  if_wb pe_bus0(), pe_bus1();
  if_wb pf_bus0(), pf_bus1();

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
	       .p3(p3_bus1.master),
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
  bus_term bus1_p3(p3_bus1.slave);
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

  arbiter arb0(.clk_i(clk_i),
	       .rst_i(rst_i),
	       .in0(ram0_ibus.slave),
	       .in1(ram0_dbus.slave),
	       .out(cache0.master));

  cache #(.AWIDTH(11), .TAGSIZE(5)) cache0(.clk_i(clk_i), .rst_i(rst_i),
					   .inbus(cache0.slave),
					   .outbus(sdram0.master),
					   .cache_status(cache_status),
					   .stats(stats0.slave));
  
  sdram2 #(.AWIDTH(11),
	   .INITNAME("../clear.hex")) sdram0(.clk_i(clk_i), .rst_i(rst_i),
					 .bus(sdram0.slave));
  ram2 #(.AWIDTH(11)) ram1(.clk_i(clk_i), .rst_i(rst_i),
			   .bus0(ram1_ibus.slave),
			   .bus1(ram1_dbus.slave));
  
endmodule // top
