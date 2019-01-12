module dualrom
  #(AWIDTH=16,
    DWIDTH=32,
    INITNAME="rom.mif")
  (
   input 	       clk_i,
   input 	       rst_i,
   input [AWIDTH-1:0]  bus0_adr,
   output [DWIDTH-1:0] bus0_data,
   input [AWIDTH-1:0]  bus1_adr,
   output [DWIDTH-1:0] bus1_data);
  
  localparam MSIZE = 2 ** (AWIDTH);
  
  altsyncram
    #(.init_file(INITNAME),
      .clock_enable_input_a("BYPASS"),
      .clock_enable_output_a("BYPASS"),
      .clock_enable_input_b("BYPASS"),
      .clock_enable_output_b("BYPASS"),
      .operation_mode("BIDIR_DUAL_PORT"),
      .outdata_reg_a("UNREGISTERED"),
      .outdata_reg_b("UNREGISTERED"),
      .numwords_a(MSIZE),
      .numwords_b(MSIZE),
      .widthad_a(AWIDTH),
      .widthad_b(AWIDTH),
      .width_a(DWIDTH),
      .width_b(DWIDTH),
      .width_byteena_a(1),
      .width_byteena_b(1)) ram0(.clock0(clk_i),
				.clock1(clk_i),
				.clocken0(1'b1),
				.clocken1(1'b1),
				.clocken2(1'b1),
				.clocken3(1'b1),
				.rden_a(1'b1),
				.rden_b(1'b1),
				.aclr0(1'b0),
				.aclr1(1'b0),
				.data_a({DWIDTH{1'b0}}),
				.address_a(bus0_adr),
				.wren_a(1'b0),
				.q_a(bus0_data),
				.byteena_a(1'b1),
				.data_b({DWIDTH{1'b0}}),
				.address_b(bus1_adr),
				.wren_b(1'b0),
				.q_b(bus1_data),
				.byteena_b(1'b1));
  
endmodule
