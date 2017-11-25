`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module hazard(input              clk_i,
	      input 		 rst_i,
	      input [63:0] 	 if_ir,
	      input [63:0] 	 id_ir,
	      input [1:0] 	 id_reg_write,
	      input [63:0] 	 exe_ir,
	      input [1:0] 	 exe_reg_write,
	      input [63:0] 	 mem_ir,
	      input [1:0] 	 mem_reg_write,
	      input [3:0] 	 wb_reg_write_addr,
	      input [1:0] 	 wb_reg_write,
	      output logic 	 stall,
	      output logic [1:0] hazard1,
	      output logic [1:0] hazard2);

  wire [3:0] 			 if_type = if_ir[31:28];
  wire [3:0] 			 if_ra = if_ir[23:20];
  wire [3:0] 			 if_rb = if_ir[19:16];
  wire [3:0] 			 if_rc = if_ir[15:12];
  wire [3:0] 			 id_type = id_ir[31:28];
  wire [3:0] 			 id_op = id_ir[27:24];
  wire [3:0] 			 id_ra = id_ir[23:20];
  wire [3:0] 			 id_rb = id_ir[19:16];
  wire [3:0] 			 id_rc = id_ir[15:12];
  wire 				 id_size = id_ir[0];
  wire [3:0] 			 exe_type = exe_ir[31:28];
  wire [3:0] 			 exe_ra = exe_ir[23:20];
  wire [3:0] 			 exe_rb = exe_ir[19:16];
  wire [3:0] 			 exe_rc = exe_ir[15:12];
  wire [3:0] 			 mem_type = mem_ir[31:28];
  wire [3:0] 			 mem_ra = mem_ir[23:20];
  wire [3:0] 			 mem_rb = mem_ir[19:16];
  wire [3:0] 			 mem_rc = mem_ir[15:12];
  
  assign stall = (id_type == T_LOAD && if_ir != 64'h0 &&
		  (id_ra == if_rb || id_ra == if_rc));

  function [1:0] hazard;
    input [3:0] 		 regaddr;

    hazard = 2'h0;
    if (|wb_reg_write &&
	id_ir != 64'h0 &&
	wb_reg_write_addr == regaddr)
      hazard = 2'h3;
    else
      if (|mem_reg_write &&
	  id_ir != 64'h0 &&
	  mem_ra == regaddr)
	hazard = 2'h1;
      else
	if (|exe_reg_write &&
	    id_ir != 64'h0 &&
	    exe_ra == regaddr)
	  hazard = 2'h2;
  endfunction

  always_comb
    begin
      case (id_type)
	T_CMP:
	  begin
	    hazard1 = hazard(id_rb);
	    hazard2 = 2'h0;
	  end
	T_MOV:
	  begin
	    hazard1 = hazard(id_rb);
	    hazard2 = 2'h0;
	  end
	T_ALU:
	  begin
	    hazard1 = hazard(id_rb);
	    hazard2 = (id_op[3] ? 2'h0 : hazard(id_rc));
	  end
	T_STORE:
	  begin
	    hazard1 = hazard(id_ra);
	    hazard2 = 2'h0;
	  end
	T_LOAD:
	  begin
	    hazard1 = (id_size ? 2'h0 : hazard(id_rb));
	    hazard2 = 2'h0;
	  end
	default:
	  begin
	    hazard1 = 2'h0;
	    hazard2 = 2'h0;
	  end
      endcase // case (id_type)
    end
  
endmodule // forwarder
