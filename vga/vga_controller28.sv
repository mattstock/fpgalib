module vga_controller28(output        hs,
		      output 	    vs,
		      input 	    rst_i,
		      input 	    clock,
		      output 	    active,
		      output [15:0] x,
		      output [15:0] y,
		      output [18:0] pixel);

  // VESA 720x400 @ 70Hz, pixel clock is 28MHz
  localparam [15:0] H_SYNC_INT	 =	16'd108;
  localparam [15:0] H_SYNC_BACK	 =	16'd51;
  localparam [15:0] H_SYNC_ACT	 =	16'd726;
  localparam [15:0] H_SYNC_FRONT =	16'd15;
  localparam [15:0] H_SYNC_TOTAL =	H_SYNC_ACT+H_SYNC_FRONT+H_SYNC_INT+H_SYNC_BACK;
  localparam [15:0] V_SYNC_INT	 =	16'd2;
  localparam [15:0] V_SYNC_BACK	 =	16'd32;
  localparam [15:0] V_SYNC_ACT	 =	16'd404;
  localparam [15:0] V_SYNC_FRONT =	16'd11;
  localparam [15:0] V_SYNC_TOTAL =	V_SYNC_ACT+V_SYNC_FRONT+V_SYNC_INT+V_SYNC_BACK;
  parameter	X_START		 =	H_SYNC_INT+H_SYNC_BACK;
  parameter	Y_START		 =	V_SYNC_INT+V_SYNC_BACK;
  
  logic [15:0] 			    h_count, h_count_next;
  logic [15:0] 			    v_count, v_count_next;
  logic [15:0] 			    xpos, xpos_next;
  logic [15:0] 			    ypos, ypos_next;
  logic [18:0] 			    pixelval, pixelval_next;

  logic 			    v_active, h_active;

  assign x = xpos;
  assign y = ypos;
  assign pixel = pixelval;
  assign v_active = v_count > Y_START && v_count < Y_START+V_SYNC_ACT;
  assign h_active = h_count > X_START && h_count < X_START+H_SYNC_ACT;
  assign active = v_active && h_active;

  assign vs = (v_count >= V_SYNC_INT);
  assign hs = (h_count >= H_SYNC_INT);

  always_ff @(posedge clock or posedge rst_i)
    begin
      if (rst_i)
	begin
	  pixelval <= 19'h0;
	  h_count <= 16'h0;
	  v_count <= 16'h0;
	  xpos <= 16'h0;
	  ypos <= 16'h0;
	end
      else
	begin
	  pixelval <= pixelval_next;
	  h_count <= h_count_next;
	  v_count <= v_count_next;
	  xpos <= xpos_next;
	  ypos <= ypos_next;
	end
    end
  
  always_comb
    begin
      pixelval_next = pixelval;
      h_count_next = h_count;
      v_count_next = v_count;
      xpos_next = xpos;
      ypos_next = ypos;
      
      if (h_count < H_SYNC_TOTAL)
	begin
	  h_count_next = h_count + 1'b1;
	  if (active)
	    begin
	      xpos_next = xpos + 1'b1;
	      pixelval_next = pixelval + 1'b1;
	    end
	  else
	    xpos_next = 16'h0;
	end
      else
	begin
	  h_count_next = 16'h0;
	  if (v_count < V_SYNC_TOTAL)
	    begin
	      v_count_next = v_count + 1'b1;
	      if (v_active)
		begin
		  ypos_next = ypos + 1'b1;
		  pixelval_next = pixelval + 1'b1;
		end
	      else
		begin
		  ypos_next = 16'h0;
		  pixelval_next = 19'h0;
		end
	    end
	  else
	    v_count_next = 16'h0;
	end
    end

endmodule
