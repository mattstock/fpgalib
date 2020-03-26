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
	      input [1:0] 	 id_sp_write,
	      input [1:0] 	 exe_sp_write,
	      input [1:0] 	 mem_sp_write,
	      output logic 	 stall,
	      output logic [2:0] hazard1,
	      output logic [2:0] hazard2,
	      output logic [1:0] sp_hazard);

  wire [3:0] 			 if_rb = if_ir[19:16];
  wire [3:0] 			 if_rc = if_ir[15:12];
  wire [3:0] 			 id_type = id_ir[31:28];
  wire [3:0] 			 id_op = id_ir[27:24];
  wire [3:0] 			 id_ra = id_ir[23:20];
  wire [3:0] 			 id_rb = id_ir[19:16];
  wire [3:0] 			 id_rc = id_ir[15:12];
  wire 				 id_size = id_ir[0];
  wire [3:0] 			 mem_ra = mem_ir[23:20];
  wire [3:0] 			 exe_ra = exe_ir[23:20];
  
  assign stall = (id_type == T_LOAD && if_ir != 64'h0 &&
		  (id_ra == if_rb || id_ra == if_rc));

  function [2:0] hazard;
    input [3:0] 		 regaddr;
    
    hazard = 3'h0;
    if (id_ir != 64'h0)
      if (|exe_sp_write && regaddr == 4'd15)
	hazard = 3'h4;
      else
	if (|exe_reg_write && regaddr == exe_ra)
	  hazard = 3'h2;
	else
	  if (|mem_sp_write && regaddr == 4'd15)
	    hazard = 3'h3;
	  else 
	    if (|mem_reg_write && regaddr == mem_ra)
	      hazard = 3'h1;
  endfunction

  function [1:0] sphazard;
    sphazard = 2'h0;
    if (id_ir != 64'h0)
      if (|exe_sp_write)
	sphazard = 2'h1;
      else
	if (|mem_sp_write)
	  sphazard = 2'h2;
  endfunction
  
  always_comb
    begin
      sp_hazard = sphazard();
      case (id_type)
	T_POP:
	  begin
	    hazard1 = hazard(4'd15);
	    hazard2 = 3'h0;
	  end
	T_PUSH:
	  begin
	    hazard1 = hazard(4'd15);
	    hazard2 = hazard(id_ra);
	  end
	T_CMP:
	  begin
	    hazard1 = hazard(id_ra);
	    hazard2 = hazard(id_rb);
	  end
	T_MOV:
	  begin
	    hazard1 = hazard(id_rb);
	    hazard2 = 3'h0;
	  end
	T_INTU:
	  begin
	    hazard1 = hazard(id_rb);
	    hazard2 = 3'h0;
	  end
	T_ALU:
	  begin
	    hazard1 = hazard(id_rb);
	    hazard2 = (id_op[3] ? 3'h0 : hazard(id_rc));
	  end
	T_INT:
	  begin
	    hazard1 = hazard(id_rb);
	    hazard2 = (id_op[3] ? 3'h0 : hazard(id_rc));
	  end
	T_STORE:
	  begin
	    hazard1 = hazard(id_ra);
	    hazard2 = (id_size ? 3'h0 : hazard(id_rb));
	  end
	T_LOAD:
	  begin
	    hazard1 = 3'h0;
	    hazard2 = (id_size ? 3'h0 : hazard(id_rb));
	  end
	T_JUMP:
	  begin
	    hazard1 = 3'h0;
	    hazard2 = (id_size ? 3'h0 : hazard(id_rb));
	  end
	default:
	  begin
	    hazard1 = 3'h0;
	    hazard2 = 3'h0;
	  end
      endcase // case (id_type)
    end
  
endmodule // forwarder
