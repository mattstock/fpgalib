`include "../bexkat1.vh";

module top(input         clk_i,
	   input  rst_i,

	   output halt);

  if_wb rambus();
  if_wb cpubus();
  
  bexkat1p cpu0(.clk_i(clk_i), .rst_i(rst_i),
		.bus(cpubus.master),
		.halt(halt),
		.inter(inter),
		.exception(exception),
		.supervisor(supervisor),
		.int_en(int_en));
  
  ram ram0(.clk_i(clk_i), .rst_i(rst_i),
	   .bus(rambus.slave));
  
endmodule // top
