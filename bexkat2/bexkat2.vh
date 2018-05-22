/* a single location for all of the control signals that need to be synced
 * within the CPU, and a list of all of the state memonics.
 */

`ifndef _BEXKAT2_VH
 `define _BEXKAT2_VH

// verilator lint_off DECLFILENAME
package bexkat1Def;
//  verilator lint_on DECLFILENAME

  const bit [3:0] REG_SP = 4'hf;
  
  // Opcode types (in sync with the ISA in binutils)
  typedef enum 	  bit [3:0] { T_INH, T_PUSH, T_POP, T_CMP, T_MOV,
			      T_FP, T_ALU, T_INT, T_LDI,
			      T_LOAD, T_STORE, T_BRANCH, T_JUMP,
			      T_INTU, T_FPU} op_t;
  
  // MDR input select
  typedef enum 	  bit [3:0] { MDR_MDR, MDR_IBUS, MDR_DBUS, MDR_B, MDR_A,
			      MDR_PC, MDR_INT, MDR_ALU, MDR_CCR,
			      MDR_STATUS} mdr_in_t;
  
  // register input select
  typedef enum 	  bit [2:0] { REG_ALU, REG_MDR, REG_UVAL, REG_B } reg_in_t;
  
  // ALU in2 select
  typedef enum 	  bit [1:0] { ALU_B, ALU_SVAL, ALU_4, ALU_1 } alu_in_t;
  
  // CCR select
  typedef enum 	  bit [1:0] { CCR_CCR, CCR_ALU, CCR_FPU, CCR_MDR } ccr_t;
  
  // MAR select
  typedef enum 	  bit [2:0] { MAR_MAR, MAR_DBUS, MAR_IBUS, 
			      MAR_ALU, MAR_A } mar_t;
  
  // STATUS select
  typedef enum 	  bit [1:0] { STATUS_STATUS, STATUS_B,
			      STATUS_POP, STATUS_SUPER } status_t;
  
  // ADDR select
  typedef enum 	  bit { ADDR_PC, ADDR_MAR } addr_t;
  
  // PC select
  typedef enum 	  bit [2:0] { PC_PC, PC_NEXT, PC_MAR, PC_REL,
			      PC_ALU, PC_EXC } pc_t;
  
  typedef enum 	  bit [1:0] { REG_WRITE_NONE, REG_WRITE_8,
			      REG_WRITE_16, REG_WRITE_DW } reg_write_t;
  
  // INT functions
  typedef enum 	  bit [3:0] { INT_MUL, INT_DIV, INT_MOD, INT_MULU,
			      INT_DIVU, INT_MODU, INT_MULX, INT_MULUX,
			      INT_EXT, INT_EXTB, INT_COM, INT_NEG } intfunc_t;
  
  // FPU functions
  typedef enum 	  bit [2:0] { FPU_CVTIS, FPU_CVTSI, FPU_SQRT, FPU_NEG,
			      FPU_ADD, FPU_SUB, FPU_MUL, FPU_DIV } fpufunc_t;
  
  // INT2 select
  typedef enum 	  bit { INT2_B, INT2_SVAL } int2_t;
  
  // ALU functions
  typedef enum 	  bit [2:0] { ALU_AND, ALU_OR, ALU_ADD, ALU_SUB, ALU_LSHIFT,
			      ALU_RSHIFTA, ALU_RSHIFTL, ALU_XOR } alufunc_t;

// states for control
  typedef enum bit[6:0] { S_RESET, S_EXC, S_EXC2, S_EXC3,
			  S_EXC4, S_EXC5, S_EXC6, S_EXC7,
			  S_EXC8, S_EXC9, S_EXC10, S_EXC11, S_EXC12,
			  S_EXC13, S_EXC14, S_FETCH2, S_ARG2,
			  S_FETCH, S_LOADD2, S_EVAL, S_TERM,
			  S_ARG, S_INH, S_RELADDR, S_PUSH,
			  S_PUSH2, S_PUSH3, S_PUSH4, S_PUSH5,
			  S_POP, S_POP2, S_POP3, S_POP4, S_RTS,
			  S_RTS2, S_RTS3, S_CMP, S_CMP2, S_CMPS,
			  S_CMPS2, S_CMPS3, S_MOV, S_INTU,
			  S_MDR2RA, S_ALU, S_ALU2, S_ALU3, S_ALU4,
			  S_INT, S_INT2, S_INT3, S_BRANCH,
			  S_LDIU, S_JUMP, S_JUMP2, S_JUMP3,
			  S_LOAD, S_LOAD2, S_LOAD3, S_LOADD,
			  S_STORE, S_STORE2, S_STORE3, S_STORE4,
			  S_STORED, S_STORED2, S_HALT, S_RTI,
			  S_RTI2, S_RTI3, S_RTI4, S_RTI5,
			  S_PUSH6, S_POP5, S_RTI6, S_RTS4, S_LOADD3,
			  S_STORE5 } state_t;
  
endpackage // bexkat1_pkg
  
`endif
