`define NO_MODPORT_EXPRESSIONS
`include "bexkat1.vh"

module ram
  #(AWIDTH=15,
    INITNAME="../ram0.hex")
   (input  clk_i,
    input  rst_i,
    if_wb.slave bus);
  
  localparam MSIZE = 2 ** (AWIDTH+2);
  
  logic [7:0] 	       mem[0:MSIZE-1], mem_next[0:MSIZE-1];
  logic [AWIDTH+1:0]   idx;
  logic 	       state, state_next;
  logic [31:0] 	       dat_next;
  
  localparam S_IDLE = 1'b0;
  localparam S_ACTIVE = 1'b1;
  
  always idx = { bus.adr[AWIDTH+1:2], 2'b0 };
  always bus.ack = (state == S_ACTIVE);

  always bus.stall = 1'b0;
  
  initial
    begin
      $readmemh(INITNAME, mem);
    end
  
  always_ff @(posedge clk_i)
    mem <= mem_next;
  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	state <= S_IDLE;
	bus.dat_s <= 32'h0;
      end
    else
      begin
	state <= state_next;
	bus.dat_s <= dat_next;
      end

  always_comb
    begin
      mem_next = mem;
      dat_next = bus.dat_s;
      state_next = state;
      case (state)
	S_IDLE:
	  if (bus.cyc & bus.stb)
	    begin
	      state_next = S_ACTIVE;
	      if (bus.we)
		begin
		  if (bus.sel[0])
		    mem_next[idx] = bus.dat_m[31:24];
		  if (bus.sel[1])
		    mem_next[idx+1] = bus.dat_m[23:16];
		  if (bus.sel[2])
		    mem_next[idx+2] = bus.dat_m[15:8];
		  if (bus.sel[3])
		    mem_next[idx+3] = bus.dat_m[7:0];
		end // if (cyc_i & stb_i & we_i)
	      else
		case (bus.sel)
		  4'b1111: dat_next = { mem[idx], mem[idx+1],
					mem[idx+2], mem[idx+3] };
		  4'b0011: dat_next = { 16'h0, mem[idx+2], mem[idx+3] };
		  4'b1100: dat_next = { 16'h0, mem[idx], mem[idx+1] };
		  4'b0001: dat_next = { 24'h0, mem[idx+3] };
		  4'b0010: dat_next = { 24'h0, mem[idx+2] };
		  4'b0100: dat_next = { 24'h0, mem[idx+1] };
		  4'b1000: dat_next = { 24'h0, mem[idx] };
		  default: dat_next = 32'hdeadbeef;
		endcase // case (sel_i)
	    end // if (cyc_i & stb_i)
	S_ACTIVE:
	  if (!(bus.cyc & bus.stb))
	    state_next = S_IDLE;
	  else
	    begin
	      state_next = S_ACTIVE;
	      if (bus.we)
		begin
		  if (bus.sel[0])
		    mem_next[idx] = bus.dat_m[31:24];
		  if (bus.sel[1])
		    mem_next[idx+1] = bus.dat_m[23:16];
		  if (bus.sel[2])
		    mem_next[idx+2] = bus.dat_m[15:8];
		  if (bus.sel[3])
		    mem_next[idx+3] = bus.dat_m[7:0];
		end // if (cyc_i & stb_i & we_i)
	      else
		case (bus.sel)
		  4'b1111: dat_next = { mem[idx], mem[idx+1],
					mem[idx+2], mem[idx+3] };
		  4'b0011: dat_next = { 16'h0, mem[idx+2], mem[idx+3] };
		  4'b1100: dat_next = { 16'h0, mem[idx], mem[idx+1] };
		  4'b0001: dat_next = { 24'h0, mem[idx+3] };
		  4'b0010: dat_next = { 24'h0, mem[idx+2] };
		  4'b0100: dat_next = { 24'h0, mem[idx+1] };
		  4'b1000: dat_next = { 24'h0, mem[idx] };
		  default: dat_next = 32'hdeadbeef;
		endcase // case (sel_i)
	    end // else: !if(!(cyc_i & stb_i))
      endcase // case (state)
    end // always_comb
  
endmodule // ram
