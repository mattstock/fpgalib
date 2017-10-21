module progmem(input 		   clk_i,
	       input 		   rst_i,
	       input 		   cyc_i, 
	       input [3:0] 	   sel_i,
	       input 		   we_i,
	       input [15:0] 	   adr_i,
	       input [31:0] 	   dat_i,
	       output 		   ack_o,
	       output logic [31:0] dat_o);

  logic [15:0] 	       addr, addr_next;
  logic [31:0] 	       mem[0:32768], mem_next[0:32768];
  logic 	       state, state_next;
  
  localparam S_IDLE = 1'h0, S_DONE = 1'h1;
  
  always dat_o = mem[adr_i];
  always ack_o = (state == S_DONE);

  initial begin
    $readmemh("memory.txt",mem);
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
	S_IDLE: begin
	  if (cyc_i) begin
	    if (we_i) begin
	      mem_next[adr_i][7:0] = (sel_i[0] ? dat_i[7:0] : mem[adr_i][7:0]);
	      mem_next[adr_i][15:8] = (sel_i[1] ? dat_i[15:8] : mem[adr_i][15:8]);
	      mem_next[adr_i][23:16] = (sel_i[2] ? dat_i[23:16] : mem[adr_i][23:16]);
	      mem_next[adr_i][31:24] = (sel_i[3] ? dat_i[31:24] : mem[adr_i][31:24]);
	    end
	    state_next = S_DONE;
	  end
	end
	S_DONE: begin
	  state_next = S_IDLE;
	end
      endcase // case (state)
    end
  
endmodule // progmem

   
