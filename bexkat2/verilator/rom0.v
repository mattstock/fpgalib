module rom0(input 		   clk_i,
	    input 		rst_i,
	    input 		stb_i,
	    input 		cyc_i, 
	    input [3:0] 	sel_i,
	    input [14:0] 	adr_i,
	    output 		ack_o,
	    output logic [31:0] dat_o);

  logic [14:0] 		       addr, addr_next;
  logic [7:0] 		       mem[0:131071], mem_next[0:131071];
  logic 		       state, state_next;
  logic [16:0] 		       idx;
  
  localparam S_IDLE = 1'h0, S_DONE = 1'h1;

  // this is a little hacky since we want to use readmem to initialize,
  // and we're using objdump -O verilog for output.  It uses a byte-based
  // format, meaning that we have to use bytes here as well and then
  // fuse them together for the output.
  always idx = { adr_i, 2'b0 };
  always dat_o = { mem[idx], mem[idx+1], mem[idx+2], mem[idx+3] };
  always ack_o = (state == S_DONE);

  initial begin
    $readmemh("../rom0.hex",mem);
  end

  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i) begin
	addr <= adr_i;
	state <= S_IDLE;
      end else begin
	addr <= addr_next;
	state <= state_next;
	mem <= mem_next;
      end
    end

  always_comb
    begin
      addr_next = addr;
      state_next = state;
      mem_next = mem;
      case (state)
	S_IDLE: if (cyc_i & stb_i) state_next = S_DONE;
	S_DONE: state_next = S_IDLE;
      endcase // case (state)
    end
  
endmodule // rom

   
