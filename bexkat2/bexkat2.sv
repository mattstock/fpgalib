`timescale 1ns / 1ns
`include "bexkat2.vh"
`include "../wb.vh"

import bexkat1Def::*;

module bexkat2(input 	     clk_i,
	       input 	     rst_i,
	       if_wb.master  ins_bus,
	       if_wb.master  dat_bus,
	       output 	     halt,
	       input [2:0]   inter,
	       output 	     int_en,
	       output [3:0]  exception,
               output 	     supervisor);
  
  // Control signals
  logic [1:0] 		     reg_write;
  logic [2:0] 		     alu_func, fpu_func;
  logic 		     addrsel, ir_write;
  logic 		     vectoff_write, a_write, b_write;
  logic [3:0] 		     reg_read_addr1, reg_read_addr2, reg_write_addr;
  logic [1:0] 		     marsel, ccrsel, spsel;
  logic [1:0] 		     sspsel, alu2sel, statussel;
  logic [2:0] 		     pcsel, regsel;
  logic [3:0] 		     mdrsel, int_func;
  logic 		     int2sel, fpccr_write, superintr;
  
  // Data paths
  logic [31:0] 		     alu_out, reg_data_out1, reg_data_out2;
  logic [31:0] 		     ir_next, vectoff_next;
  logic [31:0] 		     dataout, a_next, b_next, int_out;
  logic [2:0] 		     ccr_next;
  logic 		     alu_carry, alu_negative, alu_overflow, alu_zero; 
  logic [31:0] 		     exceptionval;
  logic [31:0] 		     ir_sval, ir_uval;
  
  // Special registers
  logic [31:0] 		     mdr, mdr_next, mar, a, b;
  logic [31:0] 		     pc, ir, busin_be, vectoff;
  logic [32:0] 		     pc_next, mar_next;
  logic [31:0] 		     reg_data_in, alu_in2, int_in1, int_in2, intval;
  logic [2:0] 		     ccr;
  logic [3:0] 		     status, status_next;

  // Data switching logic


  
  assign dat_o = (we_o ? dataout : 32'h0);
  assign adr_o = (addrsel == ADDR_MAR ? mar : pc);

  assign ir_sval = { {17{ir[15]}}, ir[15:1] };
  assign ir_uval = { 17'h0000, ir[15:1] };
  assign exceptionval = vectoff + { exception, 2'b00 };
  // allows us to force supervisor mode w/o changing the bit
  assign supervisor = (superintr ? 1'b1 : status[3]);

  
  always_ff @(posedge clk_i or posedge rst_i)
      if (rst_i)
	begin
	  pc <= 'h0;
	  ir <= 0;
	  mdr <= 0;
	  mar <= 0;
	  ccr <= 3'h0;
	  vectoff <= 'hffffffc0;
	  status <= 4'b1000; // start in supervisor mode
	  a <= 'h0;
	  b <= 'h0;
	end
      else
	begin
	  pc <= pc_next[31:0];
	  ir <= ir_next;
	  mdr <= mdr_next;
	  mar <= mar_next[31:0];
	  ccr <= ccr_next;
	  vectoff <= vectoff_next;
	  status <= status_next;
	  a <= a_next;
	  b <= b_next;
	end
  
  always_comb
    begin
      ir_next = (ir_write ? dat_i : ir);
      vectoff_next = (vectoff_write ? mdr : vectoff);
      
      case (pcsel)
	PC_PC:   pc_next = pc;
	PC_NEXT: pc_next = pc + 'h4;
	PC_MAR:  pc_next = { 1'b0, mar };
	PC_REL:  pc_next = { 1'b0, pc } + { ir_sval[29:0], 2'b00 };
	PC_ALU:  pc_next = { 1'b0, alu_out }; // reg offset
	PC_EXC:  pc_next = { 1'b0, exceptionval };
	default: pc_next = pc;
      endcase // case (pcsel)
      case (marsel)
	MAR_MAR: mar_next = mar;
	MAR_BUS: mar_next = dat_i;
	MAR_ALU: mar_next = alu_out;
	MAR_A:   mar_next = a;
      endcase // case (marsel)
      case (statussel)
	STATUS_STATUS: status_next = status;
	STATUS_SUPER: status_next = { 1'b1, status[2:0] };
	STATUS_B: status_next = b[3:0];
	STATUS_POP: status_next = mdr[11:8];
      endcase // case (statussel)
      case (sel_o)
	4'b1111: begin
	  dataout = mdr;
	  busin_be = dat_i;
	end
	4'b0011: begin
	  dataout = mdr;
	  busin_be = { 16'h0000, dat_i[15:0] };
	end 
	4'b1100: begin
	  dataout = { mdr[15:0], 16'h0000 };
	  busin_be = { 16'h0000, dat_i[31:16] };
	end
	4'b0001: begin
	  dataout = mdr;
	  busin_be = { 24'h000000, dat_i[7:0] };
	end
	4'b0010: begin
	  dataout = { 16'h0000, mdr[7:0], 8'h00 };
	  busin_be = { 24'h000000, dat_i[15:8] };
	end
	4'b0100: begin
	  dataout = { 8'h00, mdr[7:0], 16'h0000 };
	  busin_be = { 24'h000000, dat_i[23:16] };
	end
	4'b1000: begin
	  dataout = { mdr[7:0], 24'h000000 };
	  busin_be = { 24'h000000, dat_i[31:24] };
	end
	default: begin // really these are invalid
	  dataout = mdr;
	  busin_be = dat_i;
	end
      endcase // case (sel_o)
      case (mdrsel)
	MDR_MDR: mdr_next = mdr;
	MDR_BUS: mdr_next = busin_be; // byte aligned
	MDR_B:   mdr_next = b;
	MDR_A:   mdr_next = a;
	MDR_PC:  mdr_next = pc;
	MDR_INT: mdr_next = int_out;
	MDR_ALU: mdr_next = alu_out;
	MDR_CCR: mdr_next = { 20'h0, status, 5'h0, ccr};
	MDR_STATUS: mdr_next = { 28'h0, status };
	default: mdr_next = mdr;
      endcase // case (mdrsel)
      case (regsel)
	REG_ALU:  reg_data_in = alu_out;
	REG_MDR:  reg_data_in = mdr;
	REG_UVAL: reg_data_in = ir_uval; // no sign ext
	REG_B:    reg_data_in = b;
	default:  reg_data_in = 'h0;
      endcase // case (regsel)
      case (alu2sel)
	ALU_B:    alu_in2 = b;
	ALU_SVAL: alu_in2 = ir_sval;
	ALU_4:    alu_in2 = 4;
	ALU_1:    alu_in2 = 1;
      endcase // case (alu2sel)
      int_in2 = (int2sel == INT2_SVAL ? ir_sval : b);
      a_next = (a_write ? reg_data_out1 : a);
      b_next = (b_write ? reg_data_out2 : b);
      case (ccrsel)
	CCR_CCR: ccr_next = ccr;
	CCR_ALU: ccr_next = { alu_carry, alu_negative ^ alu_overflow, alu_zero };
	CCR_MDR: ccr_next = mdr[2:0];
	default: ccr_next = ccr;
      endcase
    end // always_comb
  
  control con0(.clk_i(clk_i), .rst_i(rst_i),
	       .ir(ir),
	       .ir_write(ir_write),
	       .ccr(ccr),
	       .ccrsel(ccrsel),
	       .alu_func(alu_func),
	       .a_write(a_write),
	       .b_write(b_write),
	       .alu2sel(alu2sel),
	       .regsel(regsel),
	       .reg_read_addr1(reg_read_addr1),
	       .reg_read_addr2(reg_read_addr2),
	       .reg_write_addr(reg_write_addr),
	       .reg_write(reg_write),
	       .mdrsel(mdrsel),
	       .marsel(marsel),
	       .pcsel(pcsel),
	       .int2sel(int2sel),
	       .int_func(int_func),
	       .supervisor(supervisor),
	       .addrsel(addrsel),
	       .byteenable(sel_o),
	       .statussel(statussel),
	       .bus_cyc(cyc_o),
	       .bus_write(we_o),
	       .bus_ack(ack_i),
	       .bus_align(adr_o[1:0]),
	       .vectoff_write(vectoff_write),
	       .halt(halt),
	       .exception(exception),
	       .superintr(superintr),
	       .interrupt(inter),
	       .int_en(int_en));
  
  alu alu0(.in1(a),
	   .in2(alu_in2),
	   .func(alu_func),
	   .out(alu_out),
	   .c_out(alu_carry),
	   .n_out(alu_negative),
	   .v_out(alu_overflow),
	   .z_out(alu_zero));
  intcalc int0(.func(int_func),
	       .sin1(a),
	       .sin2(int_in2),
	       .uin1(a),
	       .uin2(int_in2),
	       .out(int_out));
  registerfile intreg(.clk_i(clk_i), .rst_i(rst_i),
		      .supervisor(supervisor),
		      .read1(reg_read_addr1),
		      .read2(reg_read_addr2),
		      .write_addr(reg_write_addr),
		      .write_data(reg_data_in),
		      .write_en(reg_write),
		      .data1(reg_data_out1),
		      .data2(reg_data_out2));
  
endmodule
