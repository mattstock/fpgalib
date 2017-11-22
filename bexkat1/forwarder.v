`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module forwarder(input              clk_i,
		 input 		    rst_i,
		 input [63:0] 	    if_ir,
		 input [63:0] 	    id_ir,
		 input [1:0] 	    id_reg_write,
		 input [63:0] 	    exe_ir,
		 input [1:0] 	    exe_reg_write,
		 input [63:0] 	    mem_ir,
		 input [1:0] 	    mem_reg_write,
		 output logic 	    stall,
		 output logic [1:0] hazard1,
		 output logic [1:0] hazard2);

  wire [3:0] 			    if_type = if_ir[31:28];
  wire [3:0] 			    if_ra = if_ir[23:20];
  wire [3:0] 			    if_rb = if_ir[19:16];
  wire [3:0] 			    if_rc = if_ir[15:12];
  wire [3:0] 			    id_type = id_ir[31:28];
  wire [3:0] 			    id_ra = id_ir[23:20];
  wire [3:0] 			    id_rb = id_ir[19:16];
  wire [3:0] 			    id_rc = id_ir[15:12];
  wire [3:0] 			    exe_type = exe_ir[31:28];
  wire [3:0] 			    exe_ra = exe_ir[23:20];
  wire [3:0] 			    exe_rb = exe_ir[19:16];
  wire [3:0] 			    exe_rc = exe_ir[15:12];
  wire [3:0] 			    mem_type = mem_ir[31:28];
  wire [3:0] 			    mem_ra = mem_ir[23:20];
  wire [3:0] 			    mem_rb = mem_ir[19:16];
  wire [3:0] 			    mem_rc = mem_ir[15:12];

  assign stall = (id_type == T_LOAD && 
		  (id_ra == if_rb || id_ra == if_rc));
  
  always_comb
    begin
      hazard1 = 2'h0;
      if (|mem_reg_write &&
	  mem_ra == id_rb)
	hazard1 = 2'h1;
      else
	if (|exe_reg_write &&
	    exe_ra == id_rb)
	  hazard1 = 2'h2;

      hazard2 = 2'h0;
      if (|mem_reg_write &&
	  mem_ra == id_rc)
	hazard2 = 2'h1;
      else
	if (|exe_reg_write &&
	    exe_ra == id_rc)
	  hazard2 = 2'h2;
    end
  
endmodule // forwarder
