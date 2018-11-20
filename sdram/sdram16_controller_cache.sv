`include "../wb.vh"

module sdram16_controller_cache(input 	      clk_i,
				output 	      mem_clk_o,
				input 	      rst_i,
				if_wb.slave   bus,
				output 	      we_n,
				output 	      cs_n,
				output 	      cke,
				output 	      cas_n,
				output 	      ras_n,
				output [1:0]  dqm,
				output [1:0]  ba,
				output [12:0] addrbus_out,
				output 	      databus_dir,
				input [15:0]  databus_in,
				output [15:0] databus_out);

  if_wb sdram();
   
  cache cache0(.clk_i(clk_i),
	       .rst_i(rst_i),
	       .inbus(bus.slave),
	       .outbus(sdram.master),
	       .stats_stb_i(1'b0));
   
  sdram16 sdram0(.clk_i(clk_i),
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
