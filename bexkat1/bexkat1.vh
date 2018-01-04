/* a single location for all of the control signals that need to be synced
 * within the CPU, and a list of all of the state memonics.
 */
`ifndef _BEXKAT1_VH
`define _BEXKAT1_VH

// verilator lint_off DECLFILENAME
package bexkat1Def;
//  verilator lint_on DECLFILENAME

// Uncomment to enable FPU support
// `define BEXKAT1_FPU 1

   const bit [3:0] REG_SP = 4'hf;

   // Opcode types (in sync with the ISA in binutils)
   typedef enum bit [3:0] { T_INH, T_PUSH, T_POP, T_CMP, T_MOV,
			    T_FP, T_ALU, T_INT, T_LDI,
			    T_LOAD, T_STORE, T_BRANCH, T_JUMP,
			    T_INTU, T_FPU} op_t;

   // MDR input select
   typedef enum bit [3:0] { MDR_MDR, MDR_BUS, MDR_B, MDR_A, MDR_PC, 
			    MDR_INT, MDR_FPU, MDR_ALU, MDR_CCR,
			    MDR_STATUS} mdr_in_t;
   
   // register input select
   typedef enum bit [2:0] { REG_ALU, REG_MDR, REG_UVAL, REG_B } reg_in_t;
   
   // ALU in2 select
   typedef enum bit [1:0] { ALU_B, ALU_SVAL, ALU_4, ALU_1 } alu_in_t;

   // CCR select
   typedef enum bit [1:0] { CCR_CCR, CCR_ALU, CCR_FPU, CCR_MDR } ccr_t;

   // MAR select
   typedef enum bit [1:0] { MAR_MAR, MAR_BUS, MAR_ALU, MAR_A } mar_t;

   // STATUS select
   typedef enum bit [1:0] { STATUS_STATUS, STATUS_B,
			    STATUS_POP, STATUS_SUPER } status_t;

   // ADDR select
   typedef enum bit { ADDR_PC, ADDR_MAR } addr_t;

   // PC select
   typedef enum bit [2:0] { PC_PC, PC_NEXT, PC_MAR, PC_REL,
			    PC_ALU, PC_EXC } pc_t;

   typedef enum bit [1:0] { REG_WRITE_NONE, REG_WRITE_8,
			    REG_WRITE_16, REG_WRITE_DW } reg_write_t;

   // INT functions
   typedef enum bit [3:0] { INT_MUL, INT_DIV, INT_MOD, INT_MULU,
			    INT_DIVU, INT_MODU, INT_MULX, INT_MULUX,
			    INT_EXT, INT_EXTB, INT_COM, INT_NEG } intfunc_t;

   // FPU functions
   typedef enum bit [2:0] { FPU_CVTIS, FPU_CVTSI, FPU_SQRT, FPU_NEG,
			FPU_ADD, FPU_SUB, FPU_MUL, FPU_DIV } fpufunc_t;

   // INT2 select
   typedef enum bit { INT2_B, INT2_SVAL } int2_t;

   // ALU functions
   typedef enum bit [2:0] { ALU_AND, ALU_OR, ALU_ADD, ALU_SUB, ALU_LSHIFT,
			    ALU_RSHIFTA, ALU_RSHIFTL, ALU_XOR } alufunc_t;

endpackage // bexkat1_pkg
   
`endif
