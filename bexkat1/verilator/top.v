module top(input clk_i,
	   input 	 rst_i,
	   output [31:0] msg_out,
	   input [31:0]  msg_in,
	   output 	 halt,
	   output 	 int_en,
	   output [3:0]  exception,
	   output 	 supervisor);

 
  wire 			cyc, ram0_ack, rom0_ack, rom1_ack, io0_ack, we;
  wire [3:0] 		sel;
  wire [31:0] 		adr, cpu_out, ram0_out, rom0_out, rom1_out,
			io0_out, datout;
  wire [2:0] 		inter; 		
  wire 			ram0_stb, rom0_stb, rom1_stb, io0_stb, ack;
  
  always_comb
    begin
      ram0_stb = 1'b0;
      rom0_stb = 1'b0;
      rom1_stb = 1'b0;
      io0_stb = 1'b0;
      ack = rom0_ack;
      datout = ram0_out;
      case (adr[31:28])
	4'hf: begin
	  rom1_stb = 1'b1;
	  ack = rom1_ack;
	  datout = rom1_out;
	end
	4'h7: begin
	  rom0_stb = 1'b1;
	  ack = rom0_ack;
	  datout = rom0_out;
	end
	4'h2: begin
	  io0_stb = 1'b1;
	  ack = io0_ack;
	  datout = io0_out;
	end
	4'h0: begin
	  ram0_stb = 1'b1;
	  ack = ram0_ack;
	  datout = ram0_out;
	end
	default: ram0_stb = 1'b0;
      endcase // case (adr[31:28])
    end // always_comb
  
  bexkat1 cpu0(.clk_i(clk_i), .rst_i(rst_i), .cyc_o(cyc), .sel_o(sel),
	       .ack_i(ack), .adr_o(adr), .we_o(we), .halt(halt),
	       .inter(inter), .int_en(int_en), .exception(exception),
	       .supervisor(supervisor), .dat_i(datout), .dat_o(cpu_out));
	       
  ram ram0(.clk_i(clk_i), .rst_i(rst_i), .cyc_i(cyc), .stb_i(ram0_stb),
	   .sel_i(sel), .we_i(we), .adr_i(adr[16:2]), .dat_i(cpu_out),
	   .dat_o(ram0_out), .ack_o(ram0_ack));
  rom0 rom0(.clk_i(clk_i), .rst_i(rst_i), .cyc_i(cyc), .stb_i(rom0_stb),
	    .sel_i(sel), .adr_i(adr[16:2]), .dat_o(rom0_out), .ack_o(rom0_ack));
  rom1 rom1(.clk_i(clk_i), .rst_i(rst_i), .cyc_i(cyc), .stb_i(rom1_stb),
	    .sel_i(sel), .adr_i(adr[4:2]), .dat_o(rom1_out), .ack_o(rom1_ack));

  io io0(.clk_i(clk_i), .rst_i(rst_i), .cyc_i(cyc), .stb_i(io0_stb),
	 .sel_i(sel), .we_i(we), .adr_i(adr[4:2]), .dat_i(cpu_out),
	 .dat_o(io0_out), .ack_o(io0_ack), .msg_in(msg_in), .msg_out(msg_out));
  
endmodule // top
