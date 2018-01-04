module fan_ctrl(input 	  	    clk,
		input 		    reset, 
		input 		    avs_write,
		input [1:0] 	    avs_byteenable,
		output logic [15:0] avs_readdata,
		input [15:0] 	    avs_writedata,
		output logic 	    coe_fan_pwm);
  
  logic [15:0] 			    tick;
  logic [15:0] 			    speed, speed_next;

  always avs_readdata = speed;

  always_comb
    begin
      speed_next = speed;
      if (avs_write)
	speed_next = avs_writedata;
    end
  
  always_ff @(posedge clk or posedge reset)
    begin
      if (reset)
	begin
	  speed <= 16'h0400;
	  tick <= 16'h0;
	  coe_fan_pwm <= 1'b1;
	end
      else
	begin
	  speed <= speed_next;
	  if (tick == speed) 
	    begin
	      tick <= 16'h0;
	      coe_fan_pwm <= ~coe_fan_pwm;
	    end
	  else
	    begin
	      tick <= tick + 1'h1;
	      coe_fan_pwm <= coe_fan_pwm;
	    end
	end
    end
  
endmodule
