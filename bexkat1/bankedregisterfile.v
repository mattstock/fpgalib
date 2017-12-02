module bankedregisterfile
  #(WIDTH=32, WINP=4)
  (input              clk_i, 
   input 	      rst_i,
   input [WINP-1:0] read1,
   input [WINP-1:0] read2,
   input [3:0]  bank,
   input [WINP-1:0] write_addr,
   input [WIDTH-1:0]  write_data,
   input [1:0] 	      write_en,
   output [WIDTH-1:0] data1,
   output [WIDTH-1:0] data2);

  /* 
   * WIDTH is the width of the registers themselves.
   */
  // localparam COUNT=2**(WINP+1); // good for 5 banks
  localparam COUNT=2**(WINP+2); // good for 13 banks
  localparam BANKS=13;
  
  
  logic [WIDTH-1:0]   regfile [COUNT-1:0];
  logic [WIDTH-1:0]   regfile_next [COUNT-1:0];
  logic [WINP+1:0]    ridx1, ridx2, widx;

  /* If the high bit on the addresses is high, we need to index into the
   * banks.  If it's low, we are assessing one of the 2^(WINP-2) global
   * registers. 
   */
  assign ridx1 = ( read1[WINP-1] ?
		   { bank[3:1], read1[WINP-2:0] } + { 3'h1, bank[0], 2'h0 } :
		   { 2'b0, read1 });
  assign ridx2 = ( read2[WINP-1] ?
		   { bank[3:1], read2[WINP-2:0] } + { 3'h1, bank[0], 2'h0 } :
		   { 2'b0, read2 });
  assign widx = ( write_addr[WINP-1] ?
		   { bank[3:1], write_addr[WINP-2:0] } + { 3'h1, bank[0], 2'h0 } :
		   { 2'b0, write_addr });
  
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  for (int i=0; i < COUNT; i = i + 1)
	    regfile[i] <= 'h00000000;
	end
      else
	begin
	  for (int i=0; i < COUNT; i = i + 1)
	    regfile[i] <= regfile_next[i];
	end // else: !if(rst_i)
    end // always_ff @

  always_comb
    begin
      for (int i=0; i < COUNT; i = i + 1)
	regfile_next[i] = regfile[i];
      data1 = regfile[ridx1];
      data2 = regfile[ridx2];
      case (write_en)
	2'b00: begin end
	2'b01:
	  begin
	    if (ridx1 == widx)
	      data1 = { 24'h0, write_data[7:0] };
	    if (ridx2 == widx)
	      data2 = { 24'h0, write_data[7:0] };
	    regfile_next[widx] = { 24'h000000, write_data[7:0] };
	  end
	2'b10:
	  begin
	    if (ridx1 == widx)
	      data1 = { 16'h0, write_data[15:0] };
	    if (ridx2 == widx)
	      data2 = { 16'h0, write_data[15:0] };
	    regfile_next[widx] = { 16'h0000, write_data[15:0] };
	  end
	2'b11:
	  begin
	    if (ridx1 == widx)
	      data1 = write_data;
	    if (ridx2 == widx)
	      data2 = write_data;
	    regfile_next[widx] = write_data;
	  end
      endcase // case (write_en)
    end // always_comb
endmodule // registerfile

