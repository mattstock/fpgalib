`include "../wb.vh"

/* Three parts:
 * 1.  A FIFO queues the pipelined requests from the bus.
 * 2.  State machine initializes the SDRAM and handles refresh when the
 *     bus is idle.
 * 3.  Between refresh cycles, checks to see if there's anything in the FIFO
 *     and pipelines the requests into the memory bus until empty.  After
 *     the CAS delay, each result is ACKed to the WB bus.
 */

module sdram16_controller
  #(AWIDTH=26,
    DWIDTH=16)
  (input 	       clk_i,
   output 	       mem_clk_o,
   input 	       rst_i,
   if_wb.slave         bus,
   output 	       we_n,
   output 	       cs_n,
   output 	       cke,
   output 	       cas_n,
   output 	       ras_n,
   output [1:0]        dqm,
   output [1:0]        ba,
   output 	       databus_dir,
   output [12:0]       addrbus_out,
   input [DWIDTH-1:0]  databus_in,
   output [DWIDTH-1:0] databus_out);
  
  /*
   * For the input FIFO, we need to add all of the relevant transaction
   * elements.  This would be the relevant address bits, the byte mask,
   * write indicator, and the data word in the case of a write.  Here
   * we compute them all so we have the total FIFO width.
   */
  localparam FIFO_AWIDTH = AWIDTH - 'd2;
  localparam FIFO_DWIDTH = FIFO_AWIDTH + 'd1 + 'd4 + 'd32;
  
  logic 	       fifo_full, fifo_empty, fifo_read, fifo_write;
  logic [FIFO_DWIDTH-1:0] fifo_in, fifo_out;
  logic 		  fifo_we;
  logic [31:0] 		  fifo_dat;
  logic [3:0] 		  fifo_sel;
  logic [FIFO_AWIDTH-1:0] fifo_adr;
  
  // Front signals
  assign bus.stall = fifo_full;
  assign fifo_in = {bus.adr[AWIDTH-1:2], bus.we, bus.sel, bus.dat_i};
  assign fifo_write = ~fifo_full & bus.cyc & bus.stb;
  // Back signals
  assign fifo_read = (state == S_IDLE && !fifo_empty);
  assign { fifo_adr, fifo_we, fifo_sel, fifo_dat } = fifo_out;
  assign bus.dat_o = (state == S_READ_OUT2 ? { databus_in, halfword } : 32'h0);
  assign bus.ack = (state == S_READ_OUT2 || state == S_WRITE_WAIT);
  
  localparam [3:0]
    CMD_DESL = 4'hf,
    CMD_NOP = 4'h7,
    CMD_BST = 4'h6,
    CMD_READ = 4'h3,
    CMD_WRITE = 4'h2,
    CMD_ACTIVATE = 4'h5,
    CMD_PRECHARGE = 4'h4,
    CMD_REFRESH = 4'h1,
    CMD_MRS = 4'h0;
  
  typedef enum 		  bit [4:0] { S_INIT_WAIT,
				      S_INIT_PRECHARGE, 
				      S_INIT_REFRESH,
				      S_INIT_REFRESH_WAIT,
				      S_INIT_MODE_WAIT,
				      S_INIT_MODE,
				      S_IDLE,
				      S_ACTIVATE,
				      S_ACTIVATE_WAIT,
				      S_REFRESH,
				      S_READ,
				      S_READ2,
				      S_READ_OUT,
				      S_READ_OUT2,
				      S_READ_WAIT,
				      S_WRITE,
				      S_WRITE2,
				      S_WRITE_WAIT,
				      S_WRITE_WAIT2
				      } state_t;
  
  logic 		  select;
  logic 		  wordsel;
  logic [3:0] 		  cmd, cmd_next;
  state_t                 state, state_next;
  logic [15:0] 		  delay, delay_next;
  logic [15:0] 		  halfword, halfword_next;
  
  assign {cs_n, cas_n, ras_n, we_n} = cmd;
  
  assign databus_dir = (state == S_WRITE || state == S_WRITE2);
  assign mem_clk_o = clk_i;
  assign cke = ~rst_i;
  
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  cmd <= CMD_NOP;
	  delay <= 16'd20000;
	  state <= S_INIT_WAIT;
	  halfword <= 16'h0000;
	end
      else
	begin
	  cmd <= cmd_next;
	  delay <= delay_next;
	  state <= state_next;
	  halfword <= halfword_next;
	end
    end

  always_comb
    begin
      cmd_next = cmd;
      state_next = state;
      delay_next = delay;
      addrbus_out = 13'h0;
      databus_out = 16'hdead; // change to 0 later
      ba = 2'h0;
      dqm = 2'h3;
      halfword_next = halfword;
      
      case (state)
	S_INIT_WAIT:
	  begin
	    delay_next = delay - 16'h1;
	    if (delay == 16'd0)
	      begin
		cmd_next = CMD_PRECHARGE;
		delay_next = 16'h3;
		state_next = S_INIT_PRECHARGE;
	      end
	  end
	S_INIT_PRECHARGE:
	  begin
	    addrbus_out[10] = 1'b1; // all banks precharge
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
	    cmd_next = CMD_MRS;
	    delay_next = 16'h3;
	    state_next = S_INIT_MODE_WAIT;
	  end
	S_INIT_MODE_WAIT:
	  begin
	    ba = 2'h0;
	    delay_next = delay - 1'b1;
	    // CAS = 2, sequential, write/read burst length = 2
	    addrbus_out = 13'b0000000100001;
	    cmd_next = CMD_NOP;
	    if (delay == 16'h0)
	      state_next = S_IDLE;
	  end
	S_IDLE:
	  if (~fifo_empty)
	    begin
	      cmd_next = CMD_ACTIVATE;
	      state_next = S_ACTIVATE;
	    end
	  else
	    begin
	      cmd_next = CMD_REFRESH;
	      delay_next = 16'h6;
	      state_next = S_REFRESH;
	    end
	S_REFRESH: 
	  begin
	    addrbus_out[10] = 1'b1; // all banks refresh
	    cmd_next = CMD_NOP;
	    delay_next = delay - 1'b1;
	    if (delay == 16'h0)
              state_next = S_IDLE;
	  end
	S_ACTIVATE:
	  begin
	    // address[23:0] [23:22] for bank, [21:9] for row, [8:0] col
	    ba = fifo_adr[23:22];
	    addrbus_out = fifo_adr[21:9]; // open row
	    cmd_next = CMD_NOP;
	    state_next = S_ACTIVATE_WAIT;
	  end
	S_ACTIVATE_WAIT: 
	  begin
	    if (fifo_we)
	      begin
		cmd_next = CMD_WRITE;
		state_next = S_WRITE;
	      end
	    else
	      begin
		cmd_next = CMD_READ;
		state_next = S_READ;
	      end
	  end
	S_READ:
	  begin
	    ba = fifo_adr[23:22];
	    addrbus_out[10] = 1'b1; // auto precharge
	    // Column is shifted out one, since we're doing a burst of
	    // two 16 bit words but the master bus is looking for a 32 bit
	    // word.
	    addrbus_out[9:0] = { fifo_adr[8:0], 1'h0 }; // read/write column
	    dqm = ~fifo_sel[1:0];
	    cmd_next = CMD_NOP;
	    state_next = S_READ2;
	  end
	S_READ2: // CAS 2, so one wait state
	  begin
	    dqm = ~fifo_sel[3:2];
	    state_next = S_READ_OUT;
	  end
	S_READ_OUT:
	  begin
	    halfword_next = databus_in;
	    state_next = S_READ_OUT2;
	  end
	S_READ_OUT2:
	  begin
	    state_next = (fifo_empty ? S_READ_WAIT : S_IDLE);
	  end
	S_READ_WAIT:
	  begin
	    state_next = S_IDLE;
	  end
	S_WRITE:
	  begin
	    ba = fifo_adr[23:22];
	    addrbus_out[10] = 1'b1; // auto precharge
	    // Column is shifted out one, since we're doing a burst of
	    // two 16 bit words but the master bus is looking for a 32 bit
	    // word.
	    addrbus_out[9:0] = { fifo_adr[8:0], 1'h0 }; // read/write column
	    databus_out = fifo_dat[15:0];
	    dqm = ~fifo_sel[1:0];
	    cmd_next = CMD_NOP;
	    state_next = S_WRITE2;
	  end
	S_WRITE2:
	  begin
	    databus_out = fifo_dat[31:16];
	    dqm = ~fifo_sel[3:2];
	    state_next = S_WRITE_WAIT;
	  end
	S_WRITE_WAIT:
	  begin
	    state_next = (fifo_empty ? S_WRITE_WAIT2 : S_IDLE);
	  end
	S_WRITE_WAIT2:
	  begin
	    state_next = S_IDLE;
	  end
	default:
	  state_next = S_IDLE;
      endcase
    end

  fifo #(.DWIDTH(FIFO_DWIDTH)) infifo1(.clk_i(clk_i),
				       .rst_i(rst_i),
				       .push(fifo_write),
				       .pop(fifo_read),
				       .in(fifo_in),
				       .out(fifo_out),
				       .full(fifo_full),
				       .empty(fifo_empty));

endmodule
