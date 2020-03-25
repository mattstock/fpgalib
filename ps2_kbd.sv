`include "wb.vh"

module ps2_kbd
  (input       clk_i,
   input       rst_i,
   if_wb.slave bus,
   input       ps2_clock,
   input       ps2_data);

  typedef enum bit[3:0] { S_IDLE,
			  S_BUSY,
			  S_READ,
			  S_DONE
			  } state_t;

  logic [31:0] dat_o;

`ifdef NO_MODPORT_EXPRESSIONS
//  assign dat_i = bus.dat_m;
  assign bus.dat_s = dat_o;
`else
//  assign dat_i = bus.dat_i;
  assign bus.dat_o = dat_o;
`endif
  
  state_t      bstate, bstate_next;
  state_t      tstate, tstate_next;
  logic [31:0] result, result_next;
  logic        fifo_pop, fifo_push, fifo_empty, fifo_full;
  logic [9:0]  fifo_out;
  logic [10:0] eventbuf, eventbuf_next;
  logic [3:0]  count, count_next;
  logic [9:0]  fifo_in, fifo_in_next;
  logic [2:0]  clkreg, clkreg_next;
  logic [2:0]  datareg, datareg_next;
  logic [7:0]  event_data;
  logic        event_ready, ps2_clock_falling, ps2_clock_rising;
  
  assign dat_o = result;
  assign bus.stall = 1'h0;
  assign bus.ack = (bstate == S_DONE);

  assign fifo_pop = (bstate == S_READ);
  assign fifo_push = (tstate == S_DONE);
  assign event_data = eventbuf[8:1]; // STOP, PARITY, 8 x DATA, START
  assign ps2_clock_falling = (clkreg[2:1] == 2'b10);
  assign ps2_clock_rising = (clkreg[2:1] == 2'b01);
  assign event_ready = (count == 4'h0) && ps2_clock_rising;

  always_ff @(posedge clk_i)
    begin
      if (rst_i)
	begin
	  bstate <= S_IDLE;
	  result <= 32'h0;
	end
      else
	begin
	  bstate <= bstate_next;
	  result <= result_next;
	end
    end

  always_comb
    begin
      bstate_next = bstate;
      result_next = result;

      case (bstate)
	S_IDLE:
	  begin
	    if (bus.cyc && bus.stb)
	      bstate_next = S_BUSY;
	  end
	S_BUSY:
	  begin
	    case (bus.adr[2])
	      1'h0:
		begin
		  if (fifo_empty || bus.we)
		    begin
		      result_next = 32'h0;
		      bstate_next = S_DONE;
		    end
		  else
		    begin
		      bstate_next = S_READ;
		    end
		end
	      1'h1:
		begin
		  result_next = { 30'h0, fifo_full, fifo_empty };
		  bstate_next = S_DONE;
		end
	    endcase // case (adr_i[2])
	  end // case: S_BUSY
	S_READ:
	  begin
	    result_next = { 22'h0, fifo_out };
	    bstate_next = S_DONE;
	  end
	S_DONE:
	  begin
	    bstate_next = S_IDLE;
	  end
	endcase
    end
  
  // Bottom half
  always_ff @(posedge clk_i)
    begin
      if (rst_i)
	begin
	  eventbuf <= 11'h0;
	  count <= 4'h0;
	  clkreg <= 3'h0;
	  datareg <= 3'h0;
	  fifo_in <= 10'h0;
	  tstate <= S_IDLE;
	end
      else
	begin
	  eventbuf <= eventbuf_next;
	  count <= count_next;
	  clkreg <= {clkreg[1:0], ps2_clock};
	  datareg <= {datareg[1:0], ps2_data};
	  fifo_in <= fifo_in_next;
	  tstate <= tstate_next;
	end
    end

  always_comb
    begin
      eventbuf_next = eventbuf;
      count_next = count;
      fifo_in_next = fifo_in;
      tstate_next = tstate;
      if (ps2_clock_falling)
	begin
	  if (count == 4'ha)
	    count_next = 4'h0;
	  else
	    count_next = count + 1'b1;
	  eventbuf_next = { datareg[1], eventbuf[10:1] };
	end
      
      case (tstate)
	S_IDLE:
	  begin
	    if (event_ready)
	      begin
		tstate_next = S_BUSY;
		fifo_in_next[7:0] = event_data;
	      end
	  end
	S_BUSY:
	  begin
	    case (fifo_in[7:0])
              8'hf0:
		begin
		  fifo_in_next[9] = 1'b1;
		  tstate_next = S_IDLE;
		end
              8'he0:
		begin
		  fifo_in_next[8] = 1'b1;
		  tstate_next = S_IDLE;
		end
              default:
		begin
		  fifo_in_next[7:0] = event_data;
		  tstate_next = S_DONE;
		end
	    endcase
	  end
	S_DONE:
	  begin
	    fifo_in_next[9:8] = 2'b00;
	    tstate_next = S_IDLE;
	  end
      endcase
    end
  
  fifo #(.DWIDTH(10)) ps2_fifo0(.clk_i(clk_i),
				.rst_i(rst_i),
				.full(fifo_full),
				.empty(fifo_empty),
				.out(fifo_out),
				.pop(fifo_pop),
				.push(fifo_push),
				.in(fifo_in));
  
endmodule
