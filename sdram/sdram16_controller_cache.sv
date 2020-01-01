`include "../wb.vh"

`define CACHE_DISABLE

module sdram16_controller_cache
  #(AWIDTH=26,
    DWIDTH=32)
  (input 	       clk_i,
   output 	       mem_clk_o,
   input 	       rst_i,
		       if_wb.slave bus0,
		       if_wb.slave bus1,
		       if_wb.slave stats_bus,
   output 	       we_n,
   output 	       cs_n,
   output 	       cke,
   output 	       cas_n,
   output 	       ras_n,
   output [1:0]        dqm,
   output [1:0]        ba,
   output [12:0]       addrbus_out,
   output 	       databus_dir,
   input [DWIDTH-1:0]  databus_in,
   output [DWIDTH-1:0] databus_out,
   output [1:0]        cache_status);

  if_wb arb_bus();
`ifndef CACHE_DISABLE
  if_wb sdram0_bus();
`endif
 
  arbiter arb0(.clk_i(clk_i),
	       .rst_i(rst_i),
	       .in0(bus0.slave),
	       .in1(bus1.slave),
	       .out(arb_bus.master));

`ifndef CACHE_DISABLE   
  cache
    #(.AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH))
  cache0(.clk_i(clk_i),
	 .rst_i(rst_i),
	 .inbus(arb_bus.slave),
	 .outbus(sdram0_bus.master),
	 .stats(stats_bus.slave),
	 .cache_status(cache_status));
`else 
  assign cache_status = 2'h0;
`endif
  
  sdram16_controller sdram0(.clk_i(clk_i),
			    .rst_i(rst_i),
`ifdef CACHE_DISABLE
			    .bus(arb_bus.slave),
`else
			    .bus(sdram0_bus.slave),
`endif
			    .mem_clk_o(mem_clk_o), 
			    .we_n(we_n),
			    .cs_n(cs_n),
			    .cke(cke),
			    .cas_n(cas_n),
			    .ras_n(ras_n),
			    .dqm(dqm),
			    .ba(ba),
			    .addrbus_out(addrbus_out),
			    .databus_dir(databus_dir),
			    .databus_in(databus_in),
			    .databus_out(databus_out));
   
endmodule
