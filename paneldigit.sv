module paneldigit(input [3:0] in,
		  output [7:0] out);

  always_comb
    case (in)
      4'h0: out = 8'b11111100;
      4'h1: out = 8'b01100000;
      4'h2: out = 8'b11011010;
      4'h3: out = 8'b11110010;
      4'h4: out = 8'b01100110;
      4'h5: out = 8'b10110110;
      4'h6: out = 8'b10111110;
      4'h7: out = 8'b11100000;
      4'h8: out = 8'b11111110;
      4'h9: out = 8'b11100110;
      4'ha: out = 8'b11101110;
      4'hb: out = 8'b00111110;
      4'hc: out = 8'b00011010;
      4'hd: out = 8'b01111010;
      4'he: out = 8'b10011110;
      4'hf: out = 8'b10001110;
    endcase // case (in)

endmodule
