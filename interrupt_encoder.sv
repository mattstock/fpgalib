`include "bexkat1/exceptions.vh"

module interrupt_encoder(input              clk_i,
			 input 		    rst_i,
			 input [3:0] 	    timer_in,
			 input [1:0] 	    serial0_in,
			 input 		    enabled,
			 input 		    mmu,
			 output logic [3:0] cpu_exception);

  always_comb
    casez ({ timer_in, serial0_in, mmu })
      7'b1??????: cpu_exception = EXC_TIMER3;
      7'b01?????: cpu_exception = EXC_TIMER2;
      7'b001????: cpu_exception = EXC_TIMER1;
      7'b0001???: cpu_exception = EXC_TIMER0;
      7'b00001??: cpu_exception = EXC_UART0_RX;
      7'b000001?: cpu_exception = EXC_UART0_TX;
      7'b0000001: cpu_exception = EXC_MMU;
      7'b0000000: cpu_exception = EXC_RESET;
    endcase // casex ({ timer_in, serial0_in })

endmodule // interrupt_encoder

  
