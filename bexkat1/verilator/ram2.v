module ram2
  #(AWIDTH=15,
    INITNAME="../ram0.hex")
  (input	       clk_i,
   input 	       rst_i,
   input 	       cyc0_i,
   input 	       stb0_i,
   input [3:0] 	       sel0_i,
   input 	       we0_i,
   input [AWIDTH-1:0]  adr0_i,
   input [31:0]        dat0_i,
   output 	       ack0_o,
   output logic [31:0] dat0_o,
   input 	       cyc1_i,
   input 	       stb1_i,
   input [AWIDTH-1:0]  adr1_i,
   output 	       ack1_o,
   output logic [31:0] dat1_o);
  
  localparam MSIZE = 2 ** (AWIDTH+2);
  
  logic [7:0] 	       mem[0:MSIZE-1], mem_next[0:MSIZE-1];
  logic [AWIDTH+1:0]   idx0, idx1;
  
  always idx0 = { adr0_i, 2'b0 };
  always idx1 = { adr1_i, 2'b0 };
  always dat0_o = { mem[idx0], mem[idx0+1], mem[idx0+2], mem[idx0+3] };
  always dat1_o = { mem[idx1], mem[idx1+1], mem[idx1+2], mem[idx1+3] };
  always ack0_o = (cyc0_i & stb0_i);
  always ack1_o = (cyc1_i & stb1_i);
  
  initial
    begin
      $readmemh(INITNAME, mem);
    end
  
  always_ff @(posedge clk_i or posedge rst_i)
    begin
	mem <= mem_next;
    end
  
  always_comb
    begin
      mem_next = mem;
      if (cyc0_i & stb0_i & we0_i)
	begin
	  if (sel0_i[0])
	    mem_next[idx0] = dat0_i[7:0];
	  if (sel0_i[1])
	    mem_next[idx0+1] = dat0_i[15:8];
	  if (sel0_i[2])
	    mem_next[idx0+2] = dat0_i[23:16];
	  if (sel0_i[3])
	    mem_next[idx0+3] = dat0_i[31:24];
	end // if (cyc0_i & stb0_i & we0_i)
    end // always_comb
  
endmodule // ram2

   
