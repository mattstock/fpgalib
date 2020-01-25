`include "../wb.vh"

module bus_stub
  (input       clk_i,
   input       rst_i,
   if_wb.slave bus);

  logic [31:0] dat_i, dat_o;
  
`ifdef NO_MODPORT_EXPRESSIONS
  assign dat_i = bus.dat_m;
  assign bus.dat_s = dat_o;
`else
  assign dat_i = bus.dat_i;
  assign bus.dat_o = dat_o;
`endif

  assign bus.stall = 1'h0;
  assign dat_o = dat_i;
  
endmodule // bus_stub
