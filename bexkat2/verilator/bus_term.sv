`include "wb.vh"

module bus_term(if_wb.slave bus);
  logic [31:0] dat_i, dat_o;

`ifdef NO_MODPORT_EXPRESSIONS
  assign dat_i = bus.dat_m;
  assign bus.dat_s = dat_o;
`else
  assign dat_i = bus.dat_i;
  assign bus.dat_o = dat_o;
`endif

  assign dat_o = 32'h0;
  assign bus.stall = 1'h0;
  assign bus.ack = 1'h1;
  
endmodule // bus_term
