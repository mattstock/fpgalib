`include "../../fpgalib/wb.vh"

module dualram2clock
  #(INIT_FILE="NONE",
    AWIDTH=14)
  (input       clk0,
   input       clk1,
   input       rst_i,
   input       wren,
   if_wb.slave bus0,
   if_wb.slave bus1);

  localparam MSIZE = 2 ** (AWIDTH);
  
  logic [1:0]  delay0, delay1;
  logic [31:0] dat0_i, dat1_i, dat0_o, dat1_o;

`ifdef NO_MODPORT_EXPRESSIONS
  assign dat0_i = bus0.dat_s;
  assign bus0.dat_m = dat0_o;
  assign dat1_i = bus1.dat_s;
  assign bus1.dat_m = dat1_o;
`else
  assign dat0_i = bus0.dat_i;
  assign bus0.dat_o = dat0_o;
  assign dat1_i = bus1.dat_i;
  assign bus1.dat_o = dat1_o;
`endif  

  assign bus0.ack = delay0[1];
  assign bus0.stall = 1'b0;
  assign bus1.ack = delay1[1];
  assign bus1.stall = 1'b0;

  always_ff @(posedge clk0 or posedge rst_i)
    if (rst_i)
      begin
	delay0 <= 2'h0;
      end
    else
      begin
	if (bus0.cyc)
	  delay0 <= { delay0[0], bus0.cyc & bus0.stb };
	else
	  delay0 <= 2'h0;
      end

  always_ff @(posedge clk1 or posedge rst_i)
    if (rst_i)
      begin
	delay1 <= 2'h0;
      end
    else
      begin
	if (bus1.cyc)
	  delay1 <= { delay1[0], bus1.cyc & bus1.stb };
	else
	  delay1 <= 2'h0;
      end

  altsyncram
    #(.byte_size(8),
      .address_reg_b("CLOCK1"),
      .byteena_reg_b("CLOCK1"),
      .indata_reg_b("CLOCK1"),
      .outdata_reg_b("CLOCK1"),
      .wrcontrol_wraddress_reg_b("CLOCK1"),
      .clock_enable_input_a("BYPASS"),
      .clock_enable_input_b("BYPASS"),
      .outdata_reg_a("CLOCK0"),
      .clock_enable_output_a("BYPASS"),
      .clock_enable_output_b("BYPASS"),
      .init_file(INIT_FILE),
      .operation_mode("BIDIR_DUAL_PORT"),
      .numwords_a(MSIZE),
      .numwords_b(MSIZE),
      .widthad_a(AWIDTH),
      .widthad_b(AWIDTH),
      .width_a(32),
      .width_b(32),
      .width_byteena_a(4),
      .width_byteena_b(4))
  ram0(.clock0(clk0),
       .clock1(clk1),
       .clocken0(1'b1),
       .clocken1(1'b1),
       .clocken2(1'b1),
       .clocken3(1'b1),
       .rden_a(1'b1),
       .rden_b(1'b1),
       .aclr0(1'b0),
       .aclr1(1'b0),
       .data_a(dat0_i),
       .address_a(bus0.adr[AWIDTH+1:2]),
       .wren_a(bus0.cyc & bus0.stb & bus0.we),
       .q_a(dat0_o),
       .byteena_a(bus0.sel),
       .data_b(dat1_i),
       .address_b(bus1.adr[AWIDTH+1:2]),
       .wren_b((wren ? bus1.cyc & bus1.stb & bus1.we : 1'b0)),
       .q_b(dat1_o),
       .byteena_b(bus1.sel));

endmodule
