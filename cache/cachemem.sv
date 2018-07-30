module cachemem
  #(AWIDTH=10,
    DWIDTH=32)
  (input               clk_i,
   input 	       we,
   input [AWIDTH-1:0]  address,
   input [DWIDTH-1:0]  in,
   output [DWIDTH-1:0] out);

  localparam CACHESIZE = 2**AWIDTH;
  localparam EXT = 32-AWIDTH;
  
  assign out = mem[address];
  
  logic [DWIDTH-1:0]   mem[CACHESIZE-1:0], mem_next[CACHESIZE-1:0];

  always_ff @(posedge clk_i)
    for (int i=0; i < CACHESIZE; i = i + 1)
      mem[i] <= mem_next[i];

  always_comb
    begin
      for (int i=0; i < CACHESIZE; i = i + 1)
	mem_next[i] = (we && (i == { {EXT{1'b0}}, address}) ? in : mem[i]);
    end
  
endmodule // cachemem
