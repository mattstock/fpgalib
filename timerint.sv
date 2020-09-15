`timescale 1ns / 1ns

`include "wb.vh"

module timerint(input        clk_i,
		input 	     rst_i,
		if_wb.slave  bus,
		output [3:0] interrupt);

  logic [31:0] 		     dat_i, dat_o;

`ifdef NO_MODPORT_EXPRESSIONS
  assign dat_i = bus.dat_m;
  assign bus.dat_s = dat_o;
`else
  assign dat_i = bus.dat_i;
  assign bus.dat_o = dat_o;
`endif
  
  assign dat_o = result;
  assign bus.stall = 1'h0;
  assign bus.ack = (state == S_DONE);
  assign interrupt = { status[3] & control[7],
		       status[2] & control[6],
		       status[1] & control[5],
		       status[0] & control[4] };
  
  typedef enum 		     bit [1:0] { S_IDLE, S_BUSY, S_DONE } state_t;
  
  logic [31:0] 		     control, control_next;
  logic [31:0] 		     counter, counter_next;
  logic [31:0] 		     result, result_next;
  logic [31:0] 		     status, status_next;
  logic [31:0] 		     cmpval [3:0], cmpval_next [3:0];
  logic [31:0] 		     cntval [3:0], cntval_next [3:0];
  logic [1:0] 		     idx;
  
  state_t                    state, state_next;

  always idx = bus.adr[3:2];
  
  always_ff @(posedge clk_i, posedge rst_i)
    if (rst_i)
      begin
	for (int i=0; i < 4; i = i + 1)
	  begin
            cntval[i] <= 32'h0;
            cmpval[i] <= 32'h0;
	  end
	control <= 32'h0;
	counter <= 32'h0;
	result <= 32'h0;
	status <= 32'h0;
	state <= S_IDLE;
      end
    else
      begin
	for (int i=0; i < 4; i = i + 1)
	  begin
            cntval[i] <= cntval_next[i];
            cmpval[i] <= cmpval_next[i];
	  end
	control <= control_next;
	status <= status_next;
	counter <= counter + 1'h1;
	result <= result_next;
	state <= state_next;
      end
  
  always_comb
    begin
      for (int i=0; i < 4; i = i + 1)
	begin
	  cntval_next[i] = cntval[i];
	  cmpval_next[i] = cmpval[i];
	end
      control_next = control;
      result_next = result;
      status_next = status;
      state_next = state;
      
      case (state)
	S_IDLE:
	  begin
	    if (bus.cyc & bus.stb)
              state_next = S_BUSY;
	  end
	S_BUSY:
	  begin
	    casez (bus.adr[5:2])
              4'b0000:
		if (bus.we)
		  begin
		    control_next[7:0] = (bus.sel[0] 
					 ? dat_i[7:0]
					 : control[7:0]);
		    control_next[15:8] = (bus.sel[1] 
					  ? dat_i[15:8]
					  : control[15:8]);
		    control_next[23:16] = (bus.sel[2] 
					   ? dat_i[23:16] 
					   : control[23:16]);
		    control_next[31:24] = (bus.sel[3] 
					   ? dat_i[31:24] 
					   : control[31:24]);
		  end
		else
		  result_next = control;
              4'b0001:
		if (bus.we)
		  begin
		    status_next[7:0] = (bus.sel[0] 
					? dat_i[7:0] ^ status[7:0]
					: status[7:0]);
		    status_next[15:8] = (bus.sel[1] 
					 ? dat_i[15:8] ^ status[15:8]
					 : status[15:8]);
		    status_next[23:16] = (bus.sel[2] 
					  ? dat_i[23:16] ^ status[23:16]
					  : status[23:16]);
		    status_next[31:24] = (bus.sel[3] 
					  ? dat_i[31:24] ^ status[31:24]
					  : status[31:24]);
		  end
		else
		  result_next = status;
              4'b01??:
		if (bus.we)
		  begin
		    cmpval_next[idx][7:0] = (bus.sel[0] 
					     ? dat_i[7:0]
					     : cmpval[idx][7:0]);
		    cmpval_next[idx][15:8] = (bus.sel[1] 
					      ? dat_i[15:8] 
					      : cmpval[idx][15:8]);
		    cmpval_next[idx][23:16] = (bus.sel[2] 
					       ? dat_i[23:16] 
					       : cmpval[idx][23:16]);
		    cmpval_next[idx][31:24] = (bus.sel[3] 
					       ? dat_i[31:24] 
					       : cmpval[idx][31:24]);
		  end
		else
		  result_next = cmpval[idx];
              4'b10??:
		if (bus.we)
		  begin
		    cntval_next[idx][7:0] = (bus.sel[0] 
					     ? dat_i[7:0] 
					     : cntval[idx][7:0]);
		    cntval_next[idx][15:8] = (bus.sel[1] ? dat_i[15:8] 
					      : cntval[idx][15:8]);
		    cntval_next[idx][23:16] = (bus.sel[2] ? dat_i[23:16] 
					       : cntval[idx][23:16]);
		    cntval_next[idx][31:24] = (bus.sel[3] ? dat_i[31:24] 
					       : cntval[idx][31:24]);
		  end
		else
		  result_next = cntval[idx];
              4'b1100:
		result_next = counter;
              default:
		result_next = 32'h0;
	    endcase
	    state_next = S_DONE;
	  end
	S_DONE: state_next = S_IDLE;
	default: state_next = S_IDLE;
      endcase
      
      // Handle any new timer events
      for (int i=0; i < 4; i = i + 1)
	if (control[i] & (cmpval[i] == counter))
	  begin
            status_next[i] = 1'b1;
            cntval_next[i] = cntval[i] + 1'b1;
	  end
    end
  
endmodule
