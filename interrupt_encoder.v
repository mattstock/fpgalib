`include "bexkat1/exceptions.vh"

module interrupt_encoder(input        clk_i,
			 input 	      rst_i,
			 input [3:0]  timer_in,
			 input [1:0]  serial0_in,
			 input 	      enabled,
			 output [3:0] cpu_exception);

  always_comb
    casez ({ timer_in, serial0_in })
      6'b1?????: cpu_exception = EXC_TIMER3;
      6'b01????: cpu_exception = EXC_TIMER2;
      6'b001???: cpu_exception = EXC_TIMER1;
      6'b0001??: cpu_exception = EXC_TIMER0;
      6'b00001?: cpu_exception = EXC_UART0_RX;
      6'b000001: cpu_exception = EXC_UART0_TX;
      6'b000000: cpu_exception = EXC_RESET;
    endcase // casex ({ timer_in, serial0_in })

endmodule // interrupt_encoder

  
