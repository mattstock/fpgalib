/* a single location for all of the control signals that need to be synced
 * within the CPU, and a list of all of the state memonics.
 */
`ifndef _BEXKAT1_VH
`define _BEXKAT1_VH
package bexkat1Def;

// Uncomment to enable FPU support
// `define BEXKAT1_FPU 1

   // Opcode types (in sync with the ISA in binutils)
   typedef enum bit [3:0] { T_INH, T_PUSH, T_POP, T_CMP, T_MOV,
			    T_FP, T_ALU, T_INT, T_LDI,
			    T_LOAD, T_STORE, T_BRANCH, T_JUMP,
			    T_INTU, T_FPU} op_t;

   // MDR input select
   typedef enum bit [3:0] { MDR_MDR, MDR_BUS, MDR_B, MDR_A, MDR_PC, 
			    MDR_INT, MDR_FPU, MDR_ALU, MDR_CCR,
			    MDR_STATUS} mdr_t;
   
   // register input select
   typedef enum bit [2:0] { REG_ALU, REG_MDR, REG_UVAL, REG_B } reg_t;
   
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

   bit [3:0] REG_SP =  4'hf;

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
			    ALU_RSHIFTA, ALU_RSHIFTL, ALU_XOR } alu_t;

   // states for control
   typedef enum bit [6:0] {
			   S_RESET = 7'h0,
			   S_EXC = 7'h1,
			   S_EXC2 = 7'h2,
			   S_EXC3 = 7'h3,
			   S_EXC4 = 7'h4,
			   S_EXC5 = 7'h5,
			   S_EXC6 = 7'h6,
			   S_EXC7 = 7'h7,
			   S_FETCH = 7'h8,
			   S_LOADD2 = 7'h9,
			   S_EVAL = 7'ha,
			   S_TERM = 7'hb,
			   S_ARG = 7'hc,
			   // 'hd free
			   S_INH = 7'he,
			   S_RELADDR = 7'hf,
			   // 'h10 free
			   S_PUSH = 7'h11,
			   S_PUSH2 = 7'h12,
			   S_PUSH3 = 7'h13,
			   S_PUSH4 = 7'h14,
			   S_PUSH5 = 7'h15,
			   S_POP = 7'h16,
			   S_POP2 = 7'h17,
			   S_POP3 = 7'h18,
			   S_POP4 = 7'h19,
			   S_RTS3 = 7'h1a,
			   S_RTS  = 7'h1b,
			   S_RTS2 = 7'h1c,
			   // 'h1d free
			   S_CMP  = 7'h1e,
			   S_CMP2 = 7'h1f,
			   S_CMPS = 7'h20,
			   S_CMPS2 = 7'h21,
			   S_CMPS3 = 7'h22,
			   S_MOV = 7'h23,
			   // 'h24,
			   S_INTU = 7'h25,
			   // 'h26,
			   S_FPU = 7'h27,
			   S_FP = 7'h28,
			   S_FP2 = 7'h29,
			   S_MDR2RA = 7'h2a,
			   S_ALU = 7'h2b,
			   S_ALU2 = 7'h2c,
			   S_ALU3 = 7'h2d,
			   S_INT = 7'h2e,
			   S_INT2 = 7'h2f,
			   S_INT3 = 7'h30,
			   S_BRANCH = 7'h31,
			   S_LDIU = 7'h32,
			   S_JUMP = 7'h33,
			   S_JUMP2 = 7'h34,
			   S_JUMP3 = 7'h35,
			   S_LOAD = 7'h36,
			   S_LOAD2 = 7'h37,
			   S_LOAD3 = 7'h38,
			   S_LOADD = 7'h39,
			   S_STORE = 7'h3a,
			   S_STORE2 = 7'h3b,
			   S_STORE3 = 7'h3c,
			   S_STORED = 7'h3d,
			   S_STORED2 = 7'h3e,
			   S_STORE4 = 7'h3f,
			   S_HALT = 7'h40,
			   S_ALU4 = 7'h41,
			   S_EXC8 = 7'h42,
			   S_EXC9 = 7'h43,
			   S_EXC10 = 7'h44,
			   S_EXC11 = 7'h45,
			   S_RTI = 7'h46,
			   S_RTI2 = 7'h47,
			   S_RTI3 = 7'h48,
			   S_RTI4 = 7'h49,
			   S_RTI5 = 7'h4a
			   } state_t;

endpackage // bexkat1_pkg
   
`endif
