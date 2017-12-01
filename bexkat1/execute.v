`timescale 1ns / 1ns
`include "bexkat1.vh"
`include "exceptions.vh"

import bexkat1Def::*;

module execute(input               clk_i,
	       input 		   rst_i,
	       input [63:0] 	   ir_i,
	       input [31:0] 	   pc_i,
	       input [31:0] 	   reg_data1_i,
	       input [31:0] 	   reg_data2,
	       output logic [31:0] result,
	       output logic [31:0] reg_data1_o,
	       input [1:0] 	   reg_write_i,
	       output logic [1:0]  reg_write_o,
	       output logic [2:0]  ccr_o,
	       output logic 	   halt_o,
	       input 		   stall_i,
	       output logic 	   stall_o,
	       output [63:0] 	   ir_o,
	       output logic 	   supervisor,
	       input [2:0] 	   interrupts,
	       output logic 	   interrupts_enabled,
	       output logic 	   exc_o,
	       output [31:0] 	   pc_o,
	       output 		   pc_set_o);

  wire [31:0] 			   ir_extaddr = ir_i[63:32];
  wire [31:0] 			   ir_extval = ir_i[63:32];
  wire [3:0] 			   ir_type  = ir_i[31:28];
  wire [3:0] 			   ir_op    = ir_i[27:24];
  wire [31:0] 			   ir_sval = {{17{ir_i[15]}}, ir_i[15:1]};
  wire [31:0] 			   ir_uval  = {17'h0, ir_i[15:1]};
  wire 				   ir_size = ir_i[0];

  wire 				   ccr_ltu = ccr_o[2];
  wire 				   ccr_lt = ccr_o[1];
  wire 				   ccr_eq = ccr_o[0];
  
  alufunc_t 			   alu_func;
  
  logic [31:0] 			   alu_in1, alu_in2, alu_out;
  logic [31:0] 			   int_out;
  logic [2:0] 			   ccr_next;
  /* verilator lint_off UNOPTFLAT */
  logic 			   alu_c, alu_n, alu_v, alu_z;
  /* verilator lint_on UNOPTFLAT */
  logic [31:0] 			   pc_next, reg_data1_next;
  logic 			   pc_set_next;
  logic [63:0] 			   ir_next;
  logic [31:0] 			   result_next;
  logic [1:0] 			   reg_write_next;
  logic 			   halt_next;
  logic [3:0] 			   delay, delay_next;
  intfunc_t                        int_func;
  logic 			   stall_start;
  logic 			   interrupts_enabled_next;
  logic [31:0] 			   vectoff, vectoff_next;
  logic 			   exc_next;
  logic 			   supervisor_next;
  
  assign stall_start = (ir_type == T_INT ||
			ir_type == T_INTU) &&
		       delay == 4'h0;
  assign stall_o = (delay != 4'h0 && delay != 4'h1) || stall_start;

  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  ir_o <= 64'h0;
	  pc_o <= 32'h0;
	  reg_data1_o <= 32'h0;
	  ccr_o <= 3'h0;
	  result <= 32'h0;
	  reg_write_o <= 2'h0;
	  halt_o <= 1'h0;
	  pc_set_o <= 1'h0;
	  delay <= 4'h0;
	  interrupts_enabled <= 1'b0;
	  vectoff <= 32'hffffffc0;
	  exc_o <= 1'h0;
	  supervisor <= 1'h1;
	end
      else
	begin
	  ir_o <= ir_next;
	  pc_o <= pc_next;
	  reg_data1_o <= reg_data1_next;
	  ccr_o <= ccr_next;
	  result <= result_next;
	  reg_write_o <= reg_write_next;
	  halt_o <= halt_next;
	  pc_set_o <= pc_set_next;
	  delay <= delay_next;
	  interrupts_enabled <= interrupts_enabled_next;
	  vectoff <= vectoff_next;
	  exc_o <= exc_next;
	  supervisor <= supervisor_next;
	end // else: !if(rst_i)
    end // always_ff @

  // CCR update
  always_comb
    if (stall_i || stall_o)
	ccr_next = ccr_o;
    else
      begin
	ccr_next = ccr_o;
	if (ir_type == T_CMP)
	  ccr_next = { alu_c, alu_n ^ alu_v, alu_z };
      end

  // forwarding logic
  always_comb
    if (stall_i || stall_o)
      begin
	ir_next = ir_o;
	reg_data1_next = reg_data1_o;
	reg_write_next = reg_write_o;
      end
    else
      begin
	ir_next = ir_i;
	reg_data1_next = reg_data1_i;
	reg_write_next = reg_write_i;
      end

  // delay logic for multi-cycle ops
  always_comb
    begin
      delay_next = delay;
      if (delay != 4'h0)
	delay_next = delay - 4'h1;
      if (stall_start)
	delay_next = 4'h4;
    end

  // Result
  always_comb
    begin
      if (stall_i || stall_o)
	  result_next = result;
      else
	if (|interrupts && interrupts_enabled)
	  result_next = vectoff + { 26'h0, interrupts, 3'h0 };
	else
	  case (ir_type)
	    T_INH:
	      if (ir_op == 4'h5)
		result_next = vectoff; // reset vector
	      else
		if (ir_op == 4'h1 && ir_size == 1'h0) // trap vector
		  result_next = vectoff + { 27'h3, ir_uval[1:0], 3'h0 };
		else
		  result_next = alu_out;
	    T_INT:
	      result_next = int_out;
	    T_INTU:
	      result_next = int_out;
	    T_LOAD:
	      if (ir_size)
		result_next = ir_extaddr;
	      else
		result_next = alu_out;
	    T_STORE:
	      if (ir_size)
		result_next = ir_extaddr;
	      else
		result_next = alu_out;
	    T_LDI:
	      if (ir_size)
		result_next = ir_extval;
	      else
		result_next = ir_uval;
	    T_MOV:
	      result_next = reg_data1_i;
	    default:
	      result_next = alu_out;
	  endcase // case (ir_type)
    end // always_comb
  
  // exception logic
  always_comb
    begin
      halt_next = halt_o;
      interrupts_enabled_next = interrupts_enabled;
      vectoff_next = vectoff;
      supervisor_next = supervisor;
      exc_next = 1'h0;

      if (!stall_i)
	if (|interrupts && interrupts_enabled)
	  begin
	    interrupts_enabled_next = 1'b0;
	    exc_next = 1'h1;
	  end
	else
	  if (ir_type == T_INH)
	    begin
	      case (ir_op)
		4'h1: // trap/setint
		  if (ir_size == 1'h1)
		    if (supervisor)
		      vectoff_next = ir_extaddr;
		    else
		      halt_next = 1'h1;
		  else
		    begin
		      exc_next = 1'h1;
		      interrupts_enabled_next = 1'b0;
		    end
		4'h2: // cli
		  interrupts_enabled_next = 1'b0;
		4'h3: // sti
		  interrupts_enabled_next = 1'b1;
		4'h4: // halt
		  halt_next = 1'h1;
		4'h5: // reset
		  if (supervisor)
		    begin
		      exc_next = 1'h1;
		      interrupts_enabled_next = 1'b0;
		    end
		  else
		    halt_next = 1'h1; // should be illegal instruction vector
		default:
		  begin end
	      endcase // case (ir_op)
	    end // if (ir_type == T_INH)
    end // always_comb
  
  // branch logic
  always_comb
    begin
      if (stall_i || stall_o)
	begin
	  pc_next = pc_o;
	  pc_set_next = pc_set_o;
	end
      else
	begin
	  pc_next = pc_i;
	  pc_set_next = 1'h0;
	  
	  case (ir_type)
	    T_BRANCH:
	      begin
		case (ir_op)
		  4'h0: 
		    begin
		      pc_next = alu_out; // bra
		      pc_set_next = 1'b1;
		    end
		  4'h1: if (ccr_eq)
		    begin
		      pc_next = alu_out;  // beq
		      pc_set_next = 1'b1;
		    end
		  4'h2: if (~ccr_eq)
		    begin
		      pc_next = alu_out; // bne
		      pc_set_next = 1'b1;
		    end
		  4'h3: if (~(ccr_ltu | ccr_eq))
		    begin
		      pc_next = alu_out; // bgtu
		      pc_set_next = 1'b1;
		    end
		  4'h4: if (~(ccr_lt | ccr_eq))
		    begin
		      pc_next = alu_out; // bgt
		      pc_set_next = 1'b1;
		    end
		  4'h5: if (~ccr_lt) 
		    begin
		      pc_next = alu_out; // bge
		      pc_set_next = 1'b1;
		    end
		  4'h6: if (ccr_lt | ccr_eq)
		    begin
		      pc_next = alu_out; // ble
		      pc_set_next = 1'b1;
		    end
		  4'h7: if (ccr_lt)
		    begin
		      pc_next = alu_out; // blt
		      pc_set_next = 1'b1;
		    end
		  4'h8: if (~ccr_ltu)
		    begin
		      pc_next = alu_out; // bgeu
		      pc_set_next = 1'b1;
		    end
		  4'h9: if (ccr_ltu)
		    begin
		      pc_next = alu_out; // bltu
		      pc_set_next = 1'b1;
		    end
		  4'ha: if (ccr_ltu | ccr_eq)
		    begin
		      pc_next = alu_out; // bleu
		      pc_set_next = 1'b1;
		    end
		  default: begin end
		endcase // case (ir_op)
	      end // case: T_BRANCH
	    T_JUMP:
	      begin
		pc_next = (ir_size ? ir_extaddr : alu_out);
		pc_set_next = 1'b1;
	      end
	    default: begin end
	  endcase // case (ir_type)
	end // else: !if(stall_o)
    end // always_comb

  always_comb
    begin
      alu_in1 = reg_data1_i;
      alu_in2 = reg_data2;
      alu_func = alufunc_t'(ir_op[2:0]);
      int_func = intfunc_t'(ir_op);
      case (ir_type)
	T_INT:
	  begin
	    int_func = intfunc_t'({ 1'b0, ir_op[2:0] });
	    if (ir_op[3]) 
	      alu_in2 = ir_sval;
	  end
	T_CMP:
	  alu_func = ALU_SUB;
	T_LOAD:
	  begin
	    alu_func = ALU_ADD;
	    if (!ir_size)
	      alu_in1 = {ir_sval[29:0], 2'b00};
	  end
	T_STORE:
	  begin
	    alu_func = ALU_ADD;
	    if (!ir_size)
	      alu_in1 = {ir_sval[29:0], 2'b00};
	  end
	T_BRANCH:
	  begin
	    alu_in1 = pc_i;
	    alu_in2 = {ir_sval[29:0], 2'b00};
	    alu_func = ALU_ADD;
	  end
	T_JUMP:
	  begin
	    alu_func = ALU_ADD;
	    if (!ir_size)
	      alu_in2 = {ir_sval[29:0], 2'b00};
	  end
	T_ALU: 
	    if (ir_op[3]) 
	      alu_in2 = ir_sval;
	default: begin end
      endcase // case (ir_type)
    end // always_comb
  
  alu_comb alu0(.in1(alu_in1),
		.in2(alu_in2),
		.func(alu_func),
		.out(alu_out),
		.c_out(alu_c),
		.z_out(alu_z),
		.n_out(alu_n),
		.v_out(alu_v));
  
  intcalc int0(.func(int_func),
	       .uin1(alu_in1),
	       .uin2(alu_in2),
	       .sin1(alu_in1),
	       .sin2(alu_in2),
	       .out(int_out));
  
endmodule // ifetch
