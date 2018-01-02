`include "bexkat1.vh"

module buscontrol
  (input  clk_i,
   input rst_i,
   if_wb.slave ins_bus,
   if_wb.slave dat_bus,
   if_wb.master mem_bus);

  logic        full, push, empty, pop;
  logic [32:0] busop_in, busop_out;
  logic [31:0] dat_dat_i, dat_dat_o;
  logic [31:0] ins_dat_i, ins_dat_o;
  logic [31:0] mem_dat_i, mem_dat_o;

`ifdef NO_MODPORT_EXPRESSIONS
  assign dat_dat_i = dat_bus.dat_m;
  assign dat_bus.dat_s = dat_dat_o;
  assign ins_dat_i = ins_bus.dat_m;
  assign ins_bus.dat_s = ins_dat_o;
  assign mem_dat_i = mem_bus.dat_s;
  assign mem_bus.dat_m = mem_dat_o;
`else
  assign dat_dat_i = dat_bus.dat_i;
  assign dat_bus.dat_o = dat_dat_o;
  assign ins_dat_i = ins_bus.dat_i;
  assign ins_bus.dat_o = ins_dat_o;
  assign mem_dat_i = mem_bus.dat_i;
  assign mem_bus.dat_o = mem_dat_o;
`endif
  
  assign ins_bus.stall = dat_bus.cyc || mem_bus.stall || full;
  assign ins_dat_o = mem_dat_i;
  assign ins_bus.ack = ~busop_out[0] && mem_bus.ack;
  
  assign dat_bus.stall = mem_bus.stall || full;
  assign dat_dat_o = mem_dat_i;
  
  assign dat_bus.ack = busop_out[0] && mem_bus.ack;
  
  assign mem_bus.cyc = dat_bus.cyc | ins_bus.cyc;
  assign mem_bus.stb = (dat_bus.cyc ? dat_bus.stb : ins_bus.stb);
  assign mem_dat_o = dat_dat_i;
  assign mem_bus.we = (dat_bus.cyc ? dat_bus.we : 1'h0);
  assign mem_bus.adr = (dat_bus.cyc ? dat_bus.adr : ins_bus.adr);
  assign mem_bus.sel = (dat_bus.cyc ? dat_bus.sel : 4'hf);
  assign busop_in = (dat_bus.cyc ? {dat_bus.adr, 1'b1} : {ins_bus.adr, 1'b0});

  // track routing data
  fifo #(.DWIDTH(33)) fifo0(.clk_i(clk_i), .rst_i(rst_i),
			    .push(mem_bus.stb),
			    .pop(mem_bus.ack),
			    .full(full), .empty(empty),
			    .in(busop_in), .out(busop_out));

endmodule
