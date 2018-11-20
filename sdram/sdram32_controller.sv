`include "../wb.vh"
module sdram_controller(input 	   	    clk_i,
			output 		    mem_clk_o,
			input 		    rst_i,
			if_wb.slave         bus,
			output 		    we_n,
			output 		    cs_n,
			output 		    cke,
			output 		    cas_n,
			output 		    ras_n,
			output logic [3:0]  dqm,
			output logic [1:0]  ba,
			output logic 	    databus_dir,
			output logic [12:0] addrbus_out,
			input [31:0] 	    databus_in,
			output logic [31:0] databus_out);

   assign {cs_n, cas_n, ras_n, we_n} = cmd;

   localparam [3:0]
     CMD_DESL = 4'hf,
     CMD_NOP = 4'h7,
     CMD_READ = 4'h3,
     CMD_WRITE = 4'h2,
     CMD_ACTIVATE = 4'h5,
     CMD_PRECHARGE = 4'h4,
     CMD_REFRESH = 4'h1,
     CMD_MRS = 4'h0;

  typedef enum 				    bit [4:0] { S_INIT_WAIT,
							S_INIT_PRECHARGE, 
							S_INIT_REFRESH,
							S_INIT_REFRESH_WAIT,
							S_INIT_MODE_WAIT,
							S_INIT_MODE,
							S_IDLE,
							S_ACTIVATE,
							S_READ,
							S_READ_WAIT,
							S_READ_OUT,
							S_REFRESH,
							S_READ_OUT2,
							S_READ_OUT3,
							S_READ_OUT4,
							S_WRITE2,
							S_WRITE3,
							S_WRITE4,
							S_WRITE,
							S_WRITE_WAIT,
							S_WRITE_WAIT2,
							S_WRITE_WAIT3,
							S_ACTIVATE_WAIT
							} state_t;
  
  logic 				    select;

  assign databus_dir = (state == S_WRITE ||
			state == S_WRITE2 ||
			state == S_WRITE3 ||
			state == S_WRITE4);
  assign mem_clk_o = clk_i;
  assign bus.ack = (state == S_READ_OUT ||
		    state == S_READ_OUT2 ||
		    state == S_READ_OUT3 ||
		    state == S_READ_OUT4 ||
                    state == S_WRITE ||
		    state == S_WRITE2 ||
		    state == S_WRITE3 ||
		    state == S_WRITE4);
assign bus.stall = 1'b0;
assign bus.dat_o = (select & ~bus.we ? databus_in : 32'h0);
assign cke = ~rst_i;
assign select = bus.cyc & bus.stb;
assign databus_out = bus.dat_i;

  logic [1:0] 				    ba_next;
  logic [3:0] 				    cmd, cmd_next;
  state_t                                   state, state_next;
  logic [15:0] 				    delay, delay_next;
  logic [12:0] 				    addrbus_out_next;
  logic [3:0] 				    dqm_next;

  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  cmd <= CMD_NOP;
	  delay <= 16'd20000;
	  state <= S_INIT_WAIT;
	  ba <= 2'b00;
	  addrbus_out <= 13'h0000;
	  dqm <= 4'hf;
	end
      else
	begin
	  ba <= ba_next;
	  cmd <= cmd_next;
	  delay <= delay_next;
	  state <= state_next;
	  addrbus_out <= addrbus_out_next;
	  dqm <= dqm_next;
	end
    end

  always_comb
    begin
      cmd_next = cmd;
      state_next = state;
      delay_next = delay;
      addrbus_out_next = addrbus_out;
      ba_next = ba;
      dqm_next = dqm;
      case (state)
	S_INIT_WAIT:
	  begin
	    delay_next = delay - 16'h1;
	    if (delay == 16'd0)
	      begin
		cmd_next = CMD_PRECHARGE;
		delay_next = 16'h3;
		addrbus_out_next[10] = 1'b1; // all banks precharge
		state_next = S_INIT_PRECHARGE;
	      end
	  end
	S_INIT_PRECHARGE:
	  begin
	    delay_next = delay - 16'h1;
	    if (delay == 16'h0)
	      begin
		delay_next = 16'd63;
		state_next = S_INIT_REFRESH;
	      end
	  end
	S_INIT_REFRESH:
	  begin
	    cmd_next = CMD_REFRESH;
	    state_next = S_INIT_REFRESH_WAIT;
	  end
	S_INIT_REFRESH_WAIT:
	  begin
	    cmd_next = CMD_NOP;
	    delay_next = delay - 1'b1;
	    if (delay == 16'h0)
              state_next = S_INIT_MODE;
	    else
	      if (delay[2:0] == 3'h0)
		state_next = S_INIT_REFRESH;
	  end
	S_INIT_MODE:
	  begin
	    ba_next = 2'b00;
	    cmd_next = CMD_MRS;
	    // CAS = 2, sequential, write/read burst length = 4
	    addrbus_out_next = 13'b0000000100010;
	    delay_next = 16'h3;
	    state_next = S_INIT_MODE_WAIT;
	  end
	S_INIT_MODE_WAIT:
	  begin
	    delay_next = delay - 1'b1;
	    cmd_next = CMD_NOP;
	    if (delay == 16'h0)
	      state_next = S_IDLE;
	  end
	S_IDLE:
	  if (select)
	    begin
	      // address[24:0] [24:23] for bank, [22:10] for row, 
	      cmd_next = CMD_ACTIVATE;
	      ba_next = bus.adr[24:23];
	      addrbus_out_next = bus.adr[22:10];  // open row
	      dqm_next = ~bus.sel;
	      state_next = S_ACTIVATE;
	    end
	  else
	    begin
	      cmd_next = CMD_REFRESH;
	      addrbus_out_next[10] = 1'b1; // all banks refresh
	      delay_next = 16'h6;
	      state_next = S_REFRESH;
	    end
	S_REFRESH: 
	  begin
	    cmd_next = CMD_NOP;
	    delay_next = delay - 1'b1;
	    if (delay == 16'h0)
              state_next = S_IDLE;
	  end
	S_ACTIVATE:
	  begin
	    cmd_next = CMD_NOP;
	    state_next = S_ACTIVATE_WAIT;
	  end
	S_ACTIVATE_WAIT: 
	  begin
	    cmd_next = (bus.we ? CMD_WRITE : CMD_READ);
	    state_next = (bus.we ? S_WRITE : S_READ);
	    ba_next = bus.adr[24:23];
	    dqm_next = ~bus.sel;
	    addrbus_out_next[10] = 1'b1; // auto precharge
	    addrbus_out_next[9:0] = bus.adr[9:0]; // read/write column
	  end
	S_READ:
	  begin
	    cmd_next = CMD_NOP;
	    state_next = S_READ_WAIT;
	  end
	S_READ_WAIT:
	  state_next = S_READ_OUT;
	S_READ_OUT:
	  state_next = S_READ_OUT2;
	S_READ_OUT2:
	  state_next = S_READ_OUT3;
	S_READ_OUT3:
	  state_next = S_READ_OUT4;
	S_READ_OUT4:
	  state_next = S_IDLE;
	S_WRITE:
	  begin
	    cmd_next = CMD_NOP;
	    state_next = S_WRITE2;
	  end
	S_WRITE2:
	  state_next = S_WRITE3;
	S_WRITE3: 
	  state_next = S_WRITE4;
	S_WRITE4:
	  state_next = S_WRITE_WAIT;
	S_WRITE_WAIT: 
	  state_next = S_WRITE_WAIT2;
	S_WRITE_WAIT2:
	  state_next = S_WRITE_WAIT3;
	S_WRITE_WAIT3:
	  state_next = S_IDLE;
	default:
	  state_next = S_IDLE;
      endcase
    end
  
endmodule
