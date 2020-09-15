`timescale 1ns / 1ns

module hexdisp
  (input [4:0]            in,
   output logic [7:0] out);

  assign out = { ~in[4], decode };

  logic [6:0] 	      decode;
  
  always_comb
    case (in[3:0])
      4'h1: decode = 'b1111001;
      4'h2: decode = 'b0100100;
      4'h3: decode = 'b0110000;
      4'h4: decode = 'b0011001;
      4'h5: decode = 'b0010010;
      4'h6: decode = 'b0000010;
      4'h7: decode = 'b1111000;
      4'h8: decode = 'b0000000;
      4'h9: decode = 'b0010000;
      4'ha: decode = 'b0001000;
      4'hb: decode = 'b0000011;
      4'hc: decode = 'b1000110;
      4'hd: decode = 'b0100001;
      4'he: decode = 'b0000110;
      4'hf: decode = 'b0001110;
      4'h0: decode = 'b1000000;  
    endcase // case (in)
  
endmodule
