module ram
  #(AWIDTH=15,
    INITNAME="../ram0.hex")
  (input	       clk_i,
   input 	       rst_i,
   input 	       cyc_i,
   input 	       stb_i,
   input [3:0] 	       sel_i,
   input 	       we_i,
   input [AWIDTH-1:0]  adr_i,
   input [31:0]        dat_i,
   output logic        stall_o,
   output logic        ack_o,
   output logic [31:0] dat_o);
  
  localparam MSIZE = 2 ** (AWIDTH+2);
  
  logic [7:0] 	       mem[0:MSIZE-1], mem_next[0:MSIZE-1];
  logic [AWIDTH+1:0]   idx;
  logic 	       state, state_next;
  logic [31:0] 	       dat_next;
  
  localparam S_IDLE = 1'b0;
  localparam S_ACTIVE = 1'b1;
  
  always idx = { adr_i, 2'b0 };
  always ack_o = (state == S_ACTIVE);

  always stall_o = 1'b0;
  
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
	dat_o <= 32'h0;
      end
    else
      begin
	state <= state_next;
	dat_o <= dat_next;
      end

  always_comb
    begin
      mem_next = mem;
      dat_next = dat_o;
      state_next = state;
      case (state)
	S_IDLE:
	  if (cyc_i & stb_i)
	    begin
	      state_next = S_ACTIVE;
	      if (we_i)
		begin
		  if (sel_i[0])
		    mem_next[idx] = dat_i[31:24];
		  if (sel_i[1])
		    mem_next[idx+1] = dat_i[23:16];
		  if (sel_i[2])
		    mem_next[idx+2] = dat_i[15:8];
		  if (sel_i[3])
		    mem_next[idx+3] = dat_i[7:0];
		end // if (cyc_i & stb_i & we_i)
	      else
		case (sel_i)
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
	  if (!(cyc_i & stb_i))
	    state_next = S_IDLE;
	  else
	    begin
	      state_next = S_ACTIVE;
	      if (we_i)
		begin
		  if (sel_i[0])
		    mem_next[idx] = dat_i[31:24];
		  if (sel_i[1])
		    mem_next[idx+1] = dat_i[23:16];
		  if (sel_i[2])
		    mem_next[idx+2] = dat_i[15:8];
		  if (sel_i[3])
		    mem_next[idx+3] = dat_i[7:0];
		end // if (cyc_i & stb_i & we_i)
	      else
		case (sel_i)
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
