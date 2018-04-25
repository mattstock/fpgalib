`include "bexkat1/exceptions.vh"

module interrupt_encoder(input        clk_i,
			 input 	      rst_i,
			 input [3:0]  timer_in,
			 input [1:0]  serial0_in,
			 input 	      enabled,
			 output [3:0] cpu_exception);

  always_comb
    begin
      cpu_exception = 4'h0;
      if (enabled)
	casex ({ timer_in, serial0_in })
	  6'b1xxxxx: cpu_exception = EXC_TIMER3;
	  6'b01xxxx: cpu_exception = EXC_TIMER2;
	  6'b001xxx: cpu_exception = EXC_TIMER1;
	  6'b0001xx: cpu_exception = EXC_TIMER0;
	  6'b00001x: cpu_exception = EXC_UART0_RX;
	  6'b000001: cpu_exception = EXC_UART0_TX;
	  6'b000000: cpu_exception = EXC_RESET;
	endcase // casex ({ timer_in, serial0_in })
    end // always_comb
  
endmodule // interrupt_encoder

  
