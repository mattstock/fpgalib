`include "../wb.vh"

module sdram32_controller_cache(input 	      clk_i,
				output 	      mem_clk_o,
				input 	      rst_i,
				if_wb.slave   bus,
				output 	      we_n,
				output 	      cs_n,
				output 	      cke,
				output 	      cas_n,
				output 	      ras_n,
				output [3:0]  dqm,
				output [1:0]  ba,
				output [12:0] addrbus_out,
				output 	      databus_dir,
				input [31:0]  databus_in,
				output [31:0] databus_out,
				if_wb.slave   stats_bus,
				output [1:0]  cache_status);

  if_wb sdram();
   
  cache
    #(.AWIDTH(26))
  cache0(.clk_i(clk_i), .rst_i(rst_i),
	 .inbus(bus.slave),
	 .outbus(sdram.master),
	 .stats(stats_bus.slave),
	 .cache_status(cache_status));
  
  sdram32_controller sdram0(.clk_i(clk_i),
			    .rst_i(rst_i),
			    .bus(sdram.slave),
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
