module io(input         clk_i,
	  input 	rst_i,
	  input 	cyc_i,
	  input 	stb_i,
	  input [3:0] 	sel_i,
	  input 	we_i,
	  input [2:0] 	adr_i,
	  input [31:0] 	dat_i,
	  output [31:0] dat_o,
	  output 	ack_o,
	  input [31:0] 	msg_in,
	  output [31:0] msg_out);

  assign msg_out = msg;
  assign ack_o = (state == S_DONE);
  
  typedef enum 		bit [1:0] { S_IDLE, S_WAIT, S_DONE } state_t;
 
  logic [31:0] 		msg, msg_next;
  state_t		state, state_next;
  
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i) begin
	state <= S_IDLE;
	msg <= 32'h0;
      end else begin
	state <= state_next;
	msg <= msg_next;
      end
    end

  always_comb
    begin
      state_next = state;
      msg_next = msg;
      case (state)
	S_IDLE: begin
	  if (cyc_i & stb_i) begin
	    msg_next = dat_i;
	    state_next = S_WAIT;
	  end
	end
	S_WAIT: begin
	  if (msg_in[31]) begin
	    msg_next = 32'h0;
	    state_next = S_DONE;
	  end
	end
	S_DONE: state_next = S_IDLE;
	default: state_next = S_IDLE;
      endcase // case (state)
    end
  
endmodule // io
