`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module idecode(input               clk_i,
	       input 		   rst_i,
	       input [63:0] 	   ir_i,
	       input [31:0] 	   pc_i,
	       input 		   stall_i,
	       input 		   supervisor_i,
	       input [3:0] 	   bank_i,
	       output logic [3:0]  bank_o,
	       input [1:0] 	   reg_write_i,
	       input [3:0] 	   reg_write_addr,
	       input [31:0] 	   reg_data_in,
	       output logic [1:0]  reg_write_o,
	       output [63:0] 	   ir_o,
	       output logic [31:0] pc_o,
	       output logic [31:0] reg_data_out1,
	       output logic [31:0] reg_data_out2);
   
  wire [3:0] 			   ir_type = ir_i[31:28];
  wire [3:0] 			   ir_op = ir_i[27:24];
  wire [3:0] 			   ir_ra = ir_i[23:20];
  wire [3:0] 			   ir_rb = ir_i[19:16];
  wire [3:0] 			   ir_rc = ir_i[15:12];
  
  logic [3:0] 			   reg_read1;
  logic [3:0] 			   reg_read2;
  logic [31:0] 			   pc_next;
  logic [63:0] 			   ir_next;
  logic [31:0] 			   reg_data_out1_next;
  logic [31:0] 			   reg_data_out2_next;
  logic [31:0] 			   regfile_out1;
  logic [31:0] 			   regfile_out2;
  logic [1:0] 			   reg_write_next;
  logic [3:0] 			   bank_next;
  
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  pc_o <= 32'h0;
	  ir_o <= 64'h0;
	  reg_data_out1 <= 32'h0;
	  reg_data_out2 <= 32'h0;
	  reg_write_o <= 2'h0;
	  bank_o <= 4'h0;
	end
      else
	begin
	  pc_o <= pc_next;
	  ir_o <= ir_next;
	  reg_data_out1 <= reg_data_out1_next;
	  reg_data_out2 <= reg_data_out2_next;
	  reg_write_o <= reg_write_next;
	  bank_o <= bank_next;
	end // else: !if(rst_i)
    end // always_ff @

  always_comb
    case (ir_type)
      T_INTU:
	begin
	  reg_read1 = ir_rb;
	  reg_read2 = ir_rb;
	end
      T_CMP:
	begin
	  reg_read1 = ir_ra;
	  reg_read2 = ir_rb;
	end
      T_STORE:
	begin
	  reg_read1 = ir_ra;
	  reg_read2 = ir_rb;
	end
      T_LOAD:
	begin
	  reg_read1 = ir_ra;
	  reg_read2 = ir_rb;
	end
      default:
	begin
	  reg_read1 = ir_rb;
	  reg_read2 = ir_rc;
	end
    endcase // case (ir_type)
  
  always_comb
    begin
      if (stall_i)
	begin
	  ir_next = ir_o;
	  pc_next = pc_o;
	  reg_data_out1_next = reg_data_out1;
	  reg_data_out2_next = reg_data_out2;
	  reg_write_next = reg_write_o;
	  bank_next = bank_o;
	end
      else
	begin
	  ir_next = ir_i;
	  pc_next = pc_i;
	  bank_next = bank_i;
	  reg_data_out1_next = regfile_out1;
	  reg_data_out2_next = regfile_out2;
	  case (ir_type)
	    T_INTU: reg_write_next = 2'h3;
	    T_INT: reg_write_next = 2'h3;
	    T_LDI: reg_write_next = 2'h3;
	    T_LOAD: reg_write_next = 2'h3;
	    T_MOV: 
	      case (ir_op)
		4'h0: reg_write_next = 2'h3;
		default: reg_write_next = ir_op[1:0];
	      endcase // case (ir_op)
	    T_ALU: reg_write_next = 2'h3;
	    default: reg_write_next = 2'h0;
	  endcase // case (ir_type)
	end // else: !if(stall_i)
    end // always_comb
  
  registerfile reg0(.clk_i(clk_i), .rst_i(rst_i),
		    .read1(reg_read1),
		    .read2(reg_read2),
		    .supervisor(1'b0),
		    .write_addr(reg_write_addr),
		    .write_data(reg_data_in),
		    .write_en(reg_write_i),
		    .data1(regfile_out1),
		    .data2(regfile_out2));
  
endmodule // idecode
