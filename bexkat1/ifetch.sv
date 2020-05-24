`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "../wb.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module ifetch
  #(REQ_MAX=1,
    START_ADDR=32'h70000000)
  (input               clk_i,
   input 	       rst_i,
   output logic [63:0] ir,
   output logic [31:0] pc,
   if_wb.master        bus,
   input 	       pc_set,
   input 	       halt,
   input 	       stall_i,
   input [31:0]        pc_in);
  
  logic [63:0] 	       ir_next, ir_real;
  logic [31:0] 	       pc_next, low_next, low;
  logic [31:0] 	       bus_adr_next, val;
  logic 	       full, empty;
  logic [3:0] 	       cidx;
  logic [3:0] 	       req_count, req_count_next;
  logic [3:0] 	       ack_count, ack_count_next;

  typedef enum bit [1:0] { S_RESET, S_FETCH, S_FETCH2 } state_t;
  typedef enum bit [1:0] { SB_IDLE, SB_FETCH, SB_END, SB_HALT } bus_state_t;
  
  state_t 	       state, state_next;
  bus_state_t          bus_state, bus_state_next;

  logic [31:0]         dat_i, dat_o;
  
`ifdef NO_MODPORT_EXPRESSIONS
  assign dat_i = bus.dat_s;
  assign bus.dat_m = dat_o;
`else
  assign dat_i = bus.dat_i;
  assign bus.dat_o = dat_o;
`endif

  assign bus.cyc = (bus_state != SB_IDLE);
  assign bus.stb = (bus_state == SB_FETCH);
  assign bus.sel = 4'hf;
  assign bus.we = 1'b0;
  assign dat_o = 32'h0;
  
  fifo #(.AWIDTH(4), .DWIDTH(32)) ffifo(.clk_i(clk_i), .rst_i(rst_i|pc_set),
					.push(bus.ack&bus.cyc), .in(dat_i),
					.pop(!(bus.stall|stall_i)), .out(val),
					.full(full),
					.cidx(cidx), .empty(empty));

  always_ff @(posedge clk_i)
    if (rst_i)
      begin
	pc <= START_ADDR;
	req_count <= 4'h0;
	ack_count <= 4'h0;
	ir <= 64'h0;
	low <= 32'h0;
	bus.adr <= START_ADDR;
	state <= S_RESET;
	bus_state <= SB_IDLE;
      end
    else
      begin
	pc <= pc_next;
	req_count <= req_count_next;
	ack_count <= ack_count_next;
	ir <= ir_next;
	low <= low_next;
	bus.adr <= bus_adr_next;
	state <= state_next;
	bus_state <= bus_state_next;
      end

  // bus side
  always_comb
    begin
      req_count_next = req_count;
      ack_count_next = ack_count;
      bus_state_next = bus_state;
      bus_adr_next = bus.adr;
      
      case (bus_state)
	SB_IDLE:
	  begin
	    ack_count_next = 4'h0;
	    req_count_next = 4'h0;
	    if (cidx[3] == 1'b0)
	      begin
		bus_state_next = SB_FETCH;
	      end
	    if (pc_set)
	      begin
		bus_adr_next = pc_in;
		bus_state_next = SB_IDLE;
	      end
	  end
	SB_FETCH:
	  begin
	    if (bus.ack)
	      ack_count_next = ack_count + 4'h1;
	    if (!bus.stall)
	      begin
		bus_adr_next = bus.adr + 32'h4;
		req_count_next = req_count + 4'h1;
		if (req_count == (REQ_MAX-4'h1))
		  bus_state_next = SB_END;
	      end
	    if (pc_set)
	      begin
		bus_adr_next = pc_in;
		bus_state_next = SB_IDLE;
	      end
	  end
	SB_END:
	  begin
	    if (bus.ack)
	      ack_count_next = ack_count + 4'h1;
	    if (req_count == ack_count)
	      bus_state_next = SB_IDLE;
	    if (pc_set)
	      begin
		bus_adr_next = pc_in;
		bus_state_next = SB_IDLE;
	      end
	    if (halt)
	      bus_state_next = SB_HALT;
	  end // case: SB_END
	SB_HALT:
	  bus_state_next = SB_HALT;
      endcase // case (bus_state)
    end // always_comb

  // cpu side
  always_comb
    begin
      ir_next = ir;
      pc_next = pc;
      low_next = low;
      state_next = state;
       
      case (state)
	S_RESET:
	  if (pc_set)
	    begin
	      low_next = 32'h0;
	      ir_next = 64'h0;
	      pc_next = pc_in;
	    end
	  else
	    state_next = S_FETCH;
	S_FETCH:
	  begin
	    if (pc_set)
	      begin
		low_next = 32'h0;
		ir_next = 64'h0;
		pc_next = pc_in;
		state_next = S_RESET;
	      end
	    if (!stall_i)
	      if (empty || pc_set)
		ir_next = 64'h0;
	      else
		begin
       		  if (val[0])
		    begin
		      ir_next = 64'h0;
		      low_next = val;
		      state_next = S_FETCH2;
		    end
		  else
		    begin
		      ir_next = { 32'h0, val };
		      pc_next = pc + 32'h4;
		      state_next = S_FETCH;
		    end
		end // else: !if(empty || pc_set)
	  end
	S_FETCH2:
	  begin
	    if (pc_set)
	      begin
		low_next = 32'h0;
		ir_next = 64'h0;
		pc_next = pc_in;
		state_next = S_RESET;
	      end
	    if (!stall_i)
	      if (empty || pc_set)
		ir_next = 64'h0;
	      else
		begin
		  ir_next = { val, low };
		  pc_next = pc + 32'h8;
		  state_next = S_FETCH;
		end
	  end // case: S_FETCH2
	default:
	  state_next = S_RESET;
      endcase // case (state)
    end // always_comb
  
endmodule // ifetch
