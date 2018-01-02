`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module mem(input               clk_i,
	   input 	       rst_i,
	   input [31:0]        reg_data1_i,
	   input [31:0]        reg_data2_i,
	   input 	       stall_i,
	   output logic        stall_o,
	   input [31:0]        result_i,
	   output logic [31:0] result_o,
	   input [1:0] 	       sp_write_i,
	   output logic [1:0]  sp_write_o,
	   input [31:0]        sp_data_i,
	   input [31:0]        pc_i,
	   output logic [31:0] pc_o,
	   input 	       pc_set_i,
	   output logic        pc_set_o,
	   input [63:0]        ir_i,
	   input 	       exc_i,
	   if_wb.master        bus);

  logic [31:0] 		       dat_i, dat_o;
  
`ifdef NO_MODPORT_EXPRESSIONS
  assign dat_i = bus.dat_s;
  assign bus.dat_m = dat_o;
`else
  assign dat_i = bus.dat_i;
  assign bus.dat_o = dat_o;
`endif

  wire [3:0] 		       ir_type  = ir_i[31:28];
  wire [3:0] 		       ir_op    = ir_i[27:24];
  wire 			       ir_size = ir_i[0];
  
  logic [31:0] 		       result_next;
  logic [31:0] 		       pc_next;
  logic 		       pc_set_next;
  logic [1:0] 		       sp_write_next;

  logic 		       bus_cyc_next;
  logic [31:0] 		       bus_dat_next;
  logic [3:0] 		       bus_sel_next;
  logic [31:0] 		       bus_adr_next;
  logic 		       bus_we_next;
  logic 		       bus_stb_next;
  logic 		       full, empty;
  logic [31:0] 		       val;
  
  assign stall_o = bus.cyc;

  typedef enum 		       bit [2:0] { S_IDLE, S_EXC, S_LOAD, S_STORE, 
					   S_PUSH, S_POP, S_JSR, S_RTS 
					   } state_t;
  state_t state, state_next;

  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  result_o <= 32'h0;
	  pc_o <= 32'h0;
	  pc_set_o <= 1'h0;
	  sp_write_o <= 2'h0;
	  state <= S_IDLE;
	  bus.cyc <= 1'h0;
	  dat_o <= 32'h0;
	  bus.sel <= 4'h0;
	  bus.adr <= 32'h0;
	  bus.we <= 1'b0;
	  bus.stb <= 1'b0;
	end
      else
	begin
	  result_o <= result_next;
	  pc_o <= pc_next;
	  pc_set_o <= pc_set_next;
	  sp_write_o <= sp_write_next;
	  state <= state_next;
	  bus.cyc <= bus_cyc_next;
	  bus.stb <= bus_stb_next;
	  dat_o <= bus_dat_next;
	  bus.sel <= bus_sel_next;
	  bus.adr <= bus_adr_next;
	  bus.we <= bus_we_next;
	end // else: !if(rst_i)
    end // always_ff @

  function [3:0] databus_sel;
    input [1:0] opcode;
    input [1:0] addr;

    databus_sel = 4'hf;
    case (opcode)
      2'h0: databus_sel = 4'hf;
      2'h1: databus_sel = (addr[1] ? 4'b0011 : 4'b1100);
      2'h2: case (addr)
	      2'b00: databus_sel = 4'b1000;
	      2'b01: databus_sel = 4'b0100;
	      2'b10: databus_sel = 4'b0010;
	      2'b11: databus_sel = 4'b0001;
	    endcase // case (result_i[1:0])
      2'h3: databus_sel = 4'hf;
    endcase // case (ir_op[1:0])
  endfunction

  // bus stuff that's opcode dependent
  always_comb
    begin
      state_next = state;
      bus_cyc_next = bus.cyc;
      bus_adr_next = bus.adr;
      bus_dat_next = dat_o;
      bus_sel_next = bus.sel; 
      bus_stb_next = bus.stb;
      bus_we_next = bus.we;
      if (stall_i || stall_o)
	begin
	  pc_next = pc_o;
	  pc_set_next = pc_set_o;
	  sp_write_next = sp_write_o;
	  result_next = result_o;
	end
      else
	begin
	  pc_next = pc_i;
	  pc_set_next = pc_set_i;
	  sp_write_next = sp_write_i;
	  result_next = result_i;
	end
      case (state)
	S_IDLE:
	  if (exc_i)
	    begin
	      state_next = S_EXC;
	      pc_next = result_i;
	      bus_cyc_next = 1'b1;
	      bus_stb_next = 1'b1;
	      bus_we_next = 1'b1;
	      bus_sel_next = 4'hf;
	      bus_adr_next = sp_data_i;
	      bus_dat_next = pc_i - (ir_size ? 32'h8 : 32'h4);
	    end
	  else
	    case (ir_type)
	      T_INH:
		if (ir_op == 4'h5 || (ir_op == 4'h1 && ~ir_size))
		  begin
		    state_next = S_EXC;
		    pc_next = result_i;
		    bus_cyc_next = 1'b1;
		    bus_stb_next = 1'b1;
		    bus_we_next = 1'b1;
		    bus_sel_next = 4'hf;
		    bus_adr_next = sp_data_i;
		    bus_dat_next = pc_i;
		  end
	      T_LOAD:
		begin
		  state_next = S_LOAD;
		  bus_cyc_next = 1'b1;
		  bus_stb_next = 1'b1;
		  bus_adr_next = result_i;
		  bus_dat_next = reg_data1_i;
		  bus_sel_next = databus_sel(ir_op[1:0], result_i[1:0]);
		  bus_we_next = 1'b0;
		end
	      T_STORE:
		begin
		  state_next = S_STORE;
		  bus_cyc_next = 1'b1;
		  bus_stb_next = 1'b1;
		  bus_adr_next = result_i;
		  bus_dat_next = reg_data1_i;
		  bus_sel_next = databus_sel(ir_op[1:0], result_i[1:0]);
		  bus_we_next = 1'b1;
		end
	      T_PUSH:
		begin
		  if (ir_op == 4'h0)
		    state_next = S_PUSH;
		  else
		    begin
		      state_next = S_JSR;
		      pc_next = result_i;
		    end
		  bus_cyc_next = 1'b1;
		  bus_stb_next = 1'b1;
		  bus_we_next = 1'b1;
		  bus_sel_next = 4'hf;
		  bus_adr_next = sp_data_i; // use decremented value
		  bus_dat_next = (ir_op == 4'h0 ? reg_data2_i : pc_i);
		end
	      T_POP:
		begin
		  state_next = (ir_op == 4'h0 ? S_POP : S_RTS);
		  bus_cyc_next = 1'b1;
		  bus_stb_next = 1'b1;
		  bus_sel_next = 4'hf;
		  bus_adr_next = reg_data1_i; // use pre-increment value
		  bus_dat_next = reg_data1_i;
		  bus_we_next = 1'b0;
		end
	      default:
		begin
		end
	      endcase // case (ir_type)
	S_EXC:
	  begin
	    bus_stb_next = 1'b0;
	    if (bus.ack)
	      begin
		pc_set_next = 1'h1;
		sp_write_next = 2'h3;
		state_next = S_IDLE;
		bus_cyc_next = 1'b0;
	      end
	  end
	S_PUSH:
	  begin
	    bus_stb_next = 1'b0;
	    if (bus.ack)
	      begin
		bus_cyc_next = 1'b0;
		state_next = S_IDLE;
	      end
	  end
	S_JSR:
	  begin
	    bus_stb_next = 1'b0;
	    if (bus.ack)
	      begin
		state_next = S_IDLE;
		bus_cyc_next = 1'b0;
		pc_set_next = 1'h1;
	      end
	  end
	S_POP:
	  begin
	    bus_stb_next = 1'b0;
	    if (bus.ack)
	      begin
		state_next = S_IDLE;
		bus_cyc_next = 1'b0;
		result_next = dat_i;
	      end
	  end
	S_RTS:
	  begin
	    bus_stb_next = 1'b0;
	    if (bus.ack)
	      begin
		state_next = S_IDLE;
		bus_cyc_next = 1'b0;
		pc_next = dat_i;
		pc_set_next = 1'h1;
	      end
	  end
	S_LOAD:
	  begin
	    bus_stb_next = 1'b0;
	    if (bus.ack)
	      begin
		state_next = S_IDLE;
		bus_cyc_next = 1'b0;
		result_next = dat_i;
	      end
	  end
	S_STORE:
	  begin
	    bus_stb_next = 1'b0;
	    if (bus.ack)
	      begin
		bus_cyc_next = 1'b0;
		state_next = S_IDLE;
	      end
	  end
	default:
	  state_next = S_IDLE;
      endcase // case (state)
    end
  
endmodule // ifetch
