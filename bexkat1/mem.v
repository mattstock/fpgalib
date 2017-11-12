`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module mem(input               clk_i,
	   input 	       rst_i,
	   input [63:0]        ir_i,
	   input [31:0]        pc_i,
	   input [1:0] 	       reg_write_i,
	   input [31:0]        result_i,
	   input [31:0]        reg_data1_i,
	   output logic [31:0] result_o,
	   output logic [1:0]  reg_write_o,
	   output logic [63:0] ir_o,
	   output logic [31:0] pc_o,
	   output logic [31:0] bus_adr,
	   output logic        bus_we,
	   output logic        bus_cyc,
	   input 	       bus_ack,
	   input [31:0]        bus_in,
	   output logic [31:0] bus_out,
	   output logic [3:0]  bus_sel);

   wire [3:0] 		       ir_type  = ir_i[31:28];
   wire [3:0] 		       ir_op    = ir_i[27:24];
   wire 		       ir_size = ir_i[0];
  
   typedef enum 	       bit [1:0] { S_IDLE, 
					   S_LOAD,
					   S_STORE } state_t;
   state_t 		       state, state_next;

   logic [31:0] 	       pc_next, result_next;
   logic [1:0] 		       reg_write_next;
   logic [63:0] 	       ir_next;
   
   assign bus_cyc = (state == S_LOAD || state == S_STORE);
   assign bus_we = (state == S_STORE);
   assign bus_adr = result_i;
   assign bus_out = reg_data1_i;
   
   always_ff @(posedge clk_i or posedge rst_i)
     begin
	if (rst_i)
	  begin
	     state <= S_IDLE;
	     ir_o <= 64'h0;
	     pc_o <= 32'h0;
	     reg_write_o <= 2'h0;
	     result_o <= 32'h0;
	  end
	else
	  begin
	     state <= state_next;
	     ir_o <= ir_next;
	     pc_o <= pc_next;
	     reg_write_o <= reg_write_next;
	     result_o <= result_next;
	  end // else: !if(rst_i)
     end // always_ff @

   always_comb
     case (ir_op[1:0])
       2'h1: bus_sel = (result_i[1] ? 4'b0011 : 4'b1100);
       2'h2: case (result_i[1:0])
	       2'b00: bus_sel = 4'b1000;
	       2'b01: bus_sel = 4'b0100;
	       2'b10: bus_sel = 4'b0010;
	       2'b11: bus_sel = 4'b0001;
	     endcase // case (result_i[1:0])
       default: bus_sel = 4'hf;
     endcase // case (ir_op[1:0])
   
   always_comb
     begin
	state_next = state;
	ir_next = ir_i;
	pc_next = pc_i;
	result_next = result_i;
	reg_write_next = reg_write_i;
	
	case (state)
	  S_IDLE:
	    begin
	       if (ir_type == T_LOAD)
		 state_next = S_LOAD;
	       if (ir_type == T_STORE)
		 state_next = S_STORE;
	    end
	  S_LOAD:
	    begin
	       result_next = bus_in;
	       if (bus_ack)
		 state_next = S_IDLE;
	    end
	  S_STORE:
	    if (bus_ack)
	      state_next = S_IDLE;
	  default: state_next = S_IDLE;
	endcase // case (state)
     end
  
endmodule // ifetch
