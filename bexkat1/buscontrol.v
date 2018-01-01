`include "bexkat1.vh"

module buscontrol
  (input  clk_i,
   input rst_i,
   wb_bus ins_bus,
   wb_bus dat_bus,
   wb_bus mem_bus);

  typedef enum bit[1:0] { S_RESET, S_INS, S_DAT } state_t;

  state_t      state, state_next;
  logic        full, push, empty, pop;
  logic [32:0] busop_in, busop_out;
  logic [31:0] val, val_next;
  
  assign ins_bus.stall = dat_bus.cyc || mem_bus.stall || full;
  assign ins_bus.dat_i = val;
  assign ins_bus.ack = (state == S_INS);
  
  assign dat_bus.stall = mem_bus.stall || full;
  assign dat_bus.dat_i = val;
  assign dat_bus.ack = (state == S_DAT);
  
  assign mem_bus.cyc = dat_bus.cyc | ins_bus.cyc;
  assign mem_bus.stb = dat_bus.stb | ins_bus.stb;
  assign mem_bus.dat_i = dat_bus.dat_o;
  assign mem_bus.we = (dat_bus.cyc ? dat_bus.we : 1'h0);
  assign mem_bus.adr = (dat_bus.cyc ? dat_bus.adr : ins_bus.adr);
  assign mem_bus.sel = (dat_bus.cyc ? dat_bus.sel : 4'hf);
  assign busop_in = (dat_bus.cyc ? {dat_bus.adr, 1'b1} : {ins_bus.adr, 1'b0});

  // track routing data
  fifo #(.DWIDTH(33)) fifo0(.clk_i(clk_i), .rst_i(rst_i),
			    .push(dat_bus.cyc || ins_bus.cyc),
			    .pop(mem_bus.ack),
			    .full(full), .empty(empty),
			    .in(busop_in), .out(busop_out));

  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	state <= S_RESET;
	val <= 32'h0;
      end
    else
      begin
	state <= state_next;
	val <= val_next;
      end

  always_comb
    begin
      state_next = state;
      val_next = mem_bus.dat_o;
      
      case (state)
	S_RESET:
	  state_next = (busop_out[0] ? S_DAT : S_INS);
	S_INS:
	  state_next = (busop_out[0] ? S_DAT : S_INS);
	S_DAT:
	  state_next = (busop_out[0] ? S_DAT : S_INS);
	default:
	  state_next = S_RESET;
      endcase // case (state)
    end
  
endmodule
