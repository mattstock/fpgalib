`include "../wb.vh"

module sdram32_controller_cache
  #(AWIDTH=27,
    DWIDTH=32)
  (input 	       clk_i,
   output 	       mem_clk_o,
   input 	       rst_i,
   if_wb.slave         bus0,
   if_wb.slave         bus1,
   output 	       we_n,
   output 	       cs_n,
   output 	       cke,
   output 	       cas_n,
   output 	       ras_n,
   output [3:0]        dqm,
   output [1:0]        ba,
   output [12:0]       addrbus_out,
   output 	       databus_dir,
   input [DWIDTH-1:0]  databus_in,
   output [DWIDTH-1:0] databus_out,
   if_wb.slave         stats0_bus,
   if_wb.slave         stats1_bus,
   output [3:0]        cache_status);

  logic [1:0] 	       cache_status0, cache_status1;
  
  assign cache_status = { cache_status0, cache_status1 };
  
  if_wb sdram0_bus(), sdram1_bus(), arb_bus();
 
  cache 
    #(.AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH))
  cache0(.clk_i(clk_i), .rst_i(rst_i),
	 .inbus(bus0.slave),
	 .outbus(sdram0_bus.master),
	 .stats(stats0_bus.slave),
	 .cache_status(cache_status0));

  cache 
    #(.AWIDTH(AWIDTH),
      .DWIDTH(DWIDTH))
  cache1(.clk_i(clk_i), .rst_i(rst_i),
	 .inbus(bus1.slave),
	 .outbus(sdram1_bus.master),
	 .stats(stats1_bus.slave),
	 .cache_status(cache_status1));

  arbiter arb0(.clk_i(clk_i),
	       .rst_i(rst_i),
	       .in0(sdram0_bus.slave),
	       .in1(sdram1_bus.slave),
	       .out(arb_bus.master));
  
  sdram32_controller sdram0(.clk_i(clk_i),
			    .rst_i(rst_i),
			    .bus(arb_bus.slave),
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
