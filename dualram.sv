`include "wb.vh"

module dualram
  #(AWIDTH=16,
    DWIDTH=32)
  (
   input       clk_i,
   input       rst_i,
   if_wb.slave bus1);

  assign bus1.stall = 1'b0;
  assign bus1.ack = 1'b1;
  assign bus1.dat_o = 32'h20304050;
  
endmodule
