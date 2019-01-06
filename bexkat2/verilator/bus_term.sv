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

module bus_term_m(if_wb.master bus);
  logic [31:0] dat_i, dat_o;

`ifdef NO_MODPORT_EXPRESSIONS
  assign dat_i = bus.dat_s;
  assign bus.dat_m = dat_o;
`else
  assign dat_i = bus.dat_i;
  assign bus.dat_o = dat_o;
`endif

  assign dat_o = 32'h0;
  assign bus.cyc = 1'h0;
  assign bus.stb = 1'h0;
  assign bus.sel = 4'h0;
  assign bus.we = 1'h0;
  
endmodule // bus_term_m

