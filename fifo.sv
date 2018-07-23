module fifo
  #(AWIDTH=4,
    DWIDTH=32)
  (input                    clk_i,
   input 		    rst_i,
   input 		    push,
   input 		    pop,
   input [DWIDTH-1:0] 	    in,
   output logic [DWIDTH-1:0] out,
   output logic 	    full,
   output logic 	    empty);

  localparam DEPTH = 2**AWIDTH;
  
  logic [DWIDTH-1:0] 	    values[DEPTH-1:0], values_next[DEPTH-1:0];

  logic [AWIDTH-1:0] 	    ridx, ridx_next, widx, widx_next;
  logic [AWIDTH-1:0] 	    cidx, cidx_next;
  
  assign full = (cidx == (DEPTH-1));
  assign empty = (cidx == 0);
  assign out = values[ridx];
  
  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	widx <= 0;
	ridx <= 0;
	cidx <= 0;
	for (int i=0; i < DEPTH; i=i+1)
	  values[i] = 0;
      end
    else
      begin
	widx <= widx_next;
	ridx <= ridx_next;
	cidx <= cidx_next;
	for (int i=0; i < DEPTH; i=i+1)
	  values[i] = values_next[i];
      end // else: !if(rst_i)

  always_comb
    begin
      ridx_next = (pop && !empty ? ridx + 4'h1 : ridx);
      widx_next = (push && !full ? widx + 4'h1 : widx);
      cidx_next = cidx;
      if (pop && !empty && !(push && !full))
	cidx_next = cidx - 4'h1;
      if (push && !full && !(pop && !empty))
	cidx_next = cidx + 4'h1;
    end

  always_comb
    begin
      for (int i=0; i < DEPTH; i=i+1)
	values_next[i] = values[i];
      if (push && !full)
	values_next[widx] = in;
    end
	
endmodule // fifo

