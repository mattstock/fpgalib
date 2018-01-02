`include "bexkat1.vh"

module buscontrol
  (input  clk_i,
   input rst_i,
   wb_bus ins_bus,
   wb_bus dat_bus,
   wb_bus mem_bus);

  logic        full, push, empty, pop;
  logic [32:0] busop_in, busop_out;
  
  assign ins_bus.stall = dat_bus.cyc || mem_bus.stall || full;
  assign ins_bus.dat_i = mem_bus.dat_o;
  assign ins_bus.ack = ~busop_out[0] && mem_bus.ack;
  
  assign dat_bus.stall = mem_bus.stall || full;
  assign dat_bus.dat_i = mem_bus.dat_o;
  
  assign dat_bus.ack = busop_out[0] && mem_bus.ack;
  
  assign mem_bus.cyc = dat_bus.cyc | ins_bus.cyc;
  assign mem_bus.stb = (dat_bus.cyc ? dat_bus.stb : ins_bus.stb);
  assign mem_bus.dat_i = dat_bus.dat_o;
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
