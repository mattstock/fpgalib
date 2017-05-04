/* a single location for all of the control signals that need to be synced
 * within the CPU, and a list of all of the state memonics.
 */

`ifndef _BEXKAT2_VH
 `define _BEXKAT2_VH

// Opcode types (in sync with the ISA in binutils)
typedef enum { T_INH, T_PUSH, T_POP, T_CMP, T_MOV, T_FP, T_ALU, 
  T_INT, T_LDI, T_LOAD, T_STORE, T_BRANCH, T_JUMP, T_INTU, T_FPU} OpcodeType;

// MDR input select
typedef enum bit [3:0] { MDR_MDR, MDR_BUS, MDR_B, MDR_A,
  MDR_PC, MDR_INT, MDR_FPU, MDR_ALU, MDR_CCR, MDR_STATUS } MDRSelect;

// register input select
typedef enum bit [2:0] { REG_ALU, REG_MDR, REG_UVAL, REG_B } RegSelect;

// ALU in2 select
typedef enum bit [1:0] { ALU_B, ALU_SVAL, ALU_4, ALU_1 } ALUSelect;

// CCR select
typedef enum bit [1:0] { CCR_CCR, CCR_ALU, CCR_FPU, CCR_MDR } CCRSelect;

// MAR select
localparam MAR_MAR = 2'h0, MAR_BUS = 2'h1, MAR_ALU = 2'h2, MAR_A = 2'h3;

// STATUS select
localparam STATUS_STATUS = 2'h0, STATUS_B = 2'h1, STATUS_POP = 2'h2, STATUS_SUPER = 2'h3;

// ADDR select
localparam ADDR_PC = 1'h0, ADDR_MAR = 1'h1;

// PC select
localparam PC_PC = 3'h0, PC_NEXT = 3'h1, PC_MAR = 3'h2, PC_REL = 3'h3,
  PC_ALU = 3'h4, PC_EXC = 3'h5;

localparam REG_WRITE_NONE = 2'h0, REG_WRITE_8 = 2'h1, REG_WRITE_16 = 2'h2, REG_WRITE_DW = 2'h3;

localparam REG_SP = 4'hf;

// INT functions
localparam INT_MUL=4'h0, INT_DIV=4'h1, INT_MOD=4'h2, INT_MULU=4'h3,
  INT_DIVU=4'h4, INT_MODU=4'h5, INT_MULX = 4'h6, INT_MULUX = 4'h7,
  INT_EXT=4'h8, INT_EXTB=4'h9, INT_COM=4'ha, INT_NEG=4'hb;

// FPU functions
localparam FPU_CVTIS = 3'h0, FPU_CVTSI = 3'h1, FPU_SQRT = 3'h2, FPU_NEG = 3'h3,
  FPU_ADD = 3'h4, FPU_SUB = 3'h5, FPU_MUL = 3'h6, FPU_DIV = 3'h7;

// INT2 select
localparam INT2_B = 1'b0, INT2_SVAL = 1'b1;

// ALU functions
localparam ALU_AND =     3'h0;
localparam ALU_OR =      3'h1;
localparam ALU_ADD =     3'h2;
localparam ALU_SUB =     3'h3;
localparam ALU_LSHIFT =  3'h4;
localparam ALU_RSHIFTA = 3'h5;
localparam ALU_RSHIFTL = 3'h6;
localparam ALU_XOR =     3'h7;

// states for control
typedef enum {
  S_RESET,
  S_EXC,
  S_EXC2,
  S_EXC3,
  S_EXC4,
  S_EXC5,
  S_EXC6,
  S_EXC7,
  S_EXC8,
  S_EXC9,
  S_EXC10,
  S_EXC11,
  S_FETCH,
  S_EVAL,
  S_TERM,
  S_ARG,
  S_INH,
  S_RELADDR,
  S_PUSH,
  S_PUSH2,
  S_PUSH3,
  S_PUSH4,
  S_PUSH5,
  S_POP,
  S_POP2,
  S_POP3,
  S_POP4,
  S_RTS,
  S_RTS2,
  S_RTS3,
  S_CMP,
  S_CMP2,
  S_CMPS,
  S_CMPS2,
  S_CMPS3,
  S_MOV,
  S_INTU,
  S_FPU,
  S_FP,
  S_FP2,
  S_MDR2RA,
  S_ALU,
  S_ALU2,
  S_ALU3,
  S_ALU4,
  S_INT,
  S_INT2,
  S_INT3,
  S_BRANCH,
  S_LDIU,
  S_JUMP,
  S_JUMP2,
  S_JUMP3,
  S_LOAD,
  S_LOAD2,
  S_LOAD3,
  S_LOADD,
  S_LOADD2,
  S_STORE,
  S_STORE2,
  S_STORE3,
  S_STORE4,
  S_STORED,
  S_STORED2,
  S_HALT,
  S_RTI,
  S_RTI2,
  S_RTI3,
  S_RTI4,
  S_RTI5 } ControlStates;

`endif
