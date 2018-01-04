`ifndef _WB_VH
`define _WB_VH

interface if_wb;
  parameter AWIDTH = 32; 
  parameter DWIDTH = 32;
   
  logic [AWIDTH-1:0] adr;
  logic [DWIDTH-1:0] dat_m;
  logic [DWIDTH-1:0] dat_s;
  logic 	     cyc;
  logic 	     stall;
  logic 	     we;
  logic 	     ack;
  logic [3:0] 	     sel;
  logic 	     stb;

  modport master
    (input  ack,
     output adr,
     output cyc,
     input  stall,
     output stb,
     output sel,
     output we,
`ifdef NO_MODPORT_EXPRESSIONS
     input  dat_s,
     output dat_m
`else
     input  .dat_i(dat_s),
     output .dat_o(dat_m)
`endif
     );

  modport slave
    (output  ack,
     input  adr,
     input  cyc,
     output stall,
     input  stb,
     input  sel,
     input  we,
`ifdef NO_MODPORT_EXPRESSIONS
     input  dat_m,
     output dat_s
`else
     output .dat_o(dat_s),
     input  .dat_i(dat_m)
`endif
     );
  
endinterface

`endif

