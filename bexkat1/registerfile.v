module registerfile
  #(WIDTH=32, COUNTP=4, SPREG=4'd15)
  (input              clk_i, 
   input 	      rst_i,
   input 	      supervisor, 
   input [COUNTP-1:0] read1,
   input [COUNTP-1:0] read2,
   input [COUNTP-1:0] write_addr,
   input [WIDTH-1:0]  write_data,
   input [1:0] 	      write_en,
   input [WIDTH-1:0]  sp_data_i,
   output [WIDTH-1:0] sp_data_o,
   input [1:0] 	      sp_en,
   output [WIDTH-1:0] data1,
   output [WIDTH-1:0] data2);

  localparam COUNT=2**COUNTP;

  /* We allow multiple writes for the sole purpose of being able to
   * do stack operations - we need to adjust the stack pointer (either %15
   * or ssp) at the same time as we may need to load the result of a pop into
   * another register.  To avoid various hazards, we partition writes so that
   * the sp/%15 is a separate operation from other writes.
   */
  
  logic [WIDTH-1:0]   regfile [COUNT-1:0];
  logic [WIDTH-1:0]   regfile_next [COUNT-1:0];
  logic [WIDTH-1:0]   ssp, ssp_next;

  function [WIDTH-1:0] align_val;
    input [1:0] byte_en;
    input [WIDTH-1:0] load;

    case (byte_en)
      2'h0: align_val = load;
      2'h1: align_val = { 24'h0, load[7:0] };
      2'h2: align_val = { 16'h0, load[15:0] };
      2'h3: align_val = load;
    endcase // case (byte_en)
  endfunction

  function [WIDTH-1:0] pass_val;
    input [COUNTP-1:0] addr;

    return (addr == SPREG ? sp_data_i : write_data);
  endfunction  
  
  always_ff @(posedge clk_i or posedge rst_i)
    begin
      if (rst_i)
	begin
	  for (int i=0; i < COUNT; i = i + 1)
	    regfile[i] <= 32'h0;
	  ssp <= 32'h0;
	end
      else
	begin
	  for (int i=0; i < COUNT; i = i + 1)
	    regfile[i] <= regfile_next[i];
	  ssp <= ssp_next;
	end // else: !if(rst_i)
    end // always_ff @

  // Writes
  always_comb
    begin
      for (int i=0; i < COUNT; i = i + 1)
	regfile_next[i] = regfile[i];
      ssp_next = ssp;
      if (|write_en)
	if (supervisor && write_addr == SPREG)
	  ssp_next = align_val(sp_en, sp_data_i);
	else
	  regfile_next[write_addr] = align_val(write_en, write_data);
      if (|sp_en)
	if (supervisor)
	  ssp_next = align_val(sp_en, sp_data_i);
	else
	  regfile_next[SPREG] = align_val(sp_en, sp_data_i);
    end // always_comb

  // Read logic
  always_comb
    begin
      data1 = (supervisor && read1 == SPREG ? ssp : regfile[read1]);
      data2 = (supervisor && read2 == SPREG ? ssp : regfile[read2]);
      sp_data_o = (supervisor ? ssp : regfile[SPREG]);
      
      // Passthrough logic
      if (|write_en)
	begin
	  if (read1 == write_addr)
	    data1 = align_val(write_en, pass_val(read1));
	  if (read2 == write_addr)
	    data2 = align_val(write_en, pass_val(read2));
	  if (write_addr == SPREG)
	    sp_data_o = write_data;
	end
      if (|sp_en)
	begin
	  if (read1 == SPREG)
	    data1 = align_val(sp_en, pass_val(read1));
	  if (read2 == SPREG)
	    data2 = align_val(sp_en, pass_val(read2));
	  sp_data_o = sp_data_i;
	end
    end // always_comb
endmodule // registerfile

