module rom0(input 		   clk_i,
	    input 		rst_i,
	    input 		stb_i,
	    input 		cyc_i, 
	    input [3:0] 	sel_i,
	    input [14:0] 	adr_i,
	    output 		ack_o,
	    output logic [31:0] dat_o);

  logic [14:0] 		       addr, addr_next;
  logic [31:0] 		       mem[0:32767], mem_next[0:32767];
  logic 		       state, state_next;
  
  localparam S_IDLE = 1'h0, S_DONE = 1'h1;
  
  always dat_o = mem[adr_i];
  always ack_o = (state == S_DONE);

  initial begin
    $readmemh("../rom0.txt",mem);
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

   
