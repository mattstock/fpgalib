`define NO_MODPORT_EXPRESSIONS
`include "wb.vh"

module ram2
  #(AWIDTH=15,
    INITNAME="../ram0.hex")
  (input       clk_i,
   input       rst_i,
   if_wb.slave bus0,
   if_wb.slave bus1);
  
  localparam MSIZE = 2 ** (AWIDTH+2);
  
  logic [7:0] 	       mem[0:MSIZE-1], mem_next[0:MSIZE-1];
  logic [AWIDTH+1:0]   idx0, idx1;
  logic state0, state1, state0_next, state1_next;
  logic [31:0] dat0_next, dat1_next;
  
  localparam S_IDLE = 1'b0;
  localparam S_ACTIVE = 1'b1;
  
  assign idx0 = { bus0.adr[AWIDTH+1:2], 2'b0 };
  assign idx1 = { bus1.adr[AWIDTH+1:2], 2'b0 };
  assign bus0.ack = (state0 == S_ACTIVE);
  assign bus1.ack = (state1 == S_ACTIVE);
  assign bus0.stall = 1'b0;
  assign bus1.stall = 1'b0;
  
  initial
    begin
      $readmemh(INITNAME, mem);
    end
  
  always_ff @(posedge clk_i)
    mem <= mem_next;
  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	state0 <= S_IDLE;
	bus0.dat_s <= 32'h0;
	state1 <= S_IDLE;
	bus1.dat_s <= 32'h0;
      end
    else
      begin
	state0 <= state0_next;
	bus0.dat_s <= dat0_next;
	state1 <= state1_next;
	bus1.dat_s <= dat1_next;
      end

  // bus0 is read only
  always_comb
    begin
      dat0_next = bus0.dat_s;
      state0_next = state0;
      case (state0)
	S_IDLE:
	  if (bus0.cyc & bus0.stb)
	    begin
	      state0_next = S_ACTIVE;
	      dat0_next = { mem[idx0], mem[idx0+1],
			    mem[idx0+2], mem[idx0+3] };
	    end // if (cyc_i & stb_i)
	S_ACTIVE:
	  if (!(bus0.cyc & bus0.stb))
	    state0_next = S_IDLE;
	  else
	    begin
	      state0_next = S_ACTIVE;
	      dat0_next = { mem[idx0], mem[idx0+1],
			    mem[idx0+2], mem[idx0+3] };
	    end // else: !if(!(cyc_i & stb_i))
      endcase // case (state)
    end // always_comb

  // bus1 can do writes
  always_comb
    begin
      mem_next = mem;
      dat1_next = bus1.dat_s;
      state1_next = state1;
      case (state1)
	S_IDLE:
	  if (bus1.cyc & bus1.stb)
	    begin
	      state1_next = S_ACTIVE;
	      if (bus1.we)
		begin
		  if (bus1.sel[3])
		    mem_next[idx1] = bus1.dat_m[31:24];
		  if (bus1.sel[2])
		    mem_next[idx1+1] = bus1.dat_m[23:16];
		  if (bus1.sel[1])
		    mem_next[idx1+2] = bus1.dat_m[15:8];
		  if (bus1.sel[0])
		    mem_next[idx1+3] = bus1.dat_m[7:0];
		end // if (cyc_i & stb_i & we_i)
	      else
		dat1_next = { mem[idx1], mem[idx1+1],
			      mem[idx1+2], mem[idx1+3] };
	    end // if (cyc_i & stb_i)
	S_ACTIVE:
	  if (!(bus1.cyc & bus1.stb))
	    state1_next = S_IDLE;
	  else
	    begin
	      state1_next = S_ACTIVE;
	      if (bus1.we)
		begin
		  if (bus1.sel[3])
		    mem_next[idx1] = bus1.dat_m[31:24];
		  if (bus1.sel[2])
		    mem_next[idx1+1] = bus1.dat_m[23:16];
		  if (bus1.sel[1])
		    mem_next[idx1+2] = bus1.dat_m[15:8];
		  if (bus1.sel[0])
		    mem_next[idx1+3] = bus1.dat_m[7:0];
		end // if (cyc_i & stb_i & we_i)
	      else
		dat1_next = { mem[idx1], mem[idx1+1],
			      mem[idx1+2], mem[idx1+3] };
	    end // else: !if(!(cyc_i & stb_i))
      endcase // case (state)
    end // always_comb
  
endmodule // ram2
