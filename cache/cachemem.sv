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

  `ifdef VERILATOR
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
  `else
  
  altsyncram
    #(.outdata_reg_a("CLOCK0"),
      .clock_enable_input_a("BYPASS"),
      .clock_enable_output_a("BYPASS"),
      .operation_mode("SINGLE_PORT"),
      .numwords_a(CACHESIZE),
      .widthad_a(AWIDTH),
      .width_a(DWIDTH),
      .width_byteena_a(1))
  ram0(.clock0(clk_i),
       .clock1(1'b1),
       .clocken0(1'b1),
       .clocken1(1'b1),
       .clocken2(1'b1),
       .clocken3(1'b1),
       .rden_a(1'b1),
       .rden_b(1'b1),
       .aclr0(1'b0),
       .aclr1(1'b0),
       .data_a(in),
       .address_a(address),
       .wren_a(we),
       .q_a(out),
       .byteena_a(1'b1),
       .data_b(1'b1),
       .address_b(1'b1),
       .wren_b(1'b0),
       .q_b(),
       .byteena_b(1'b1));

  `endif
  
endmodule // cachemem
