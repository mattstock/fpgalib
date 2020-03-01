module vga_controller25(input  clock,
			input  rst_i,
			output hs,
			output vs,
			output h_active,
			output v_active);

  // VESA 640x480 @ 60Hz, pixel clock is 25MHz
  localparam [15:0] H_SYNC_ACT	 =	16'd640;
  localparam [15:0] H_SYNC_FRONT =	16'd20; 
  localparam [15:0] H_SYNC_INT	 =	16'd96;
  localparam [15:0] H_SYNC_BACK	 =	16'd44;
  localparam [15:0] H_SYNC_TOTAL =	H_SYNC_ACT+H_SYNC_FRONT+H_SYNC_INT+H_SYNC_BACK;
  localparam [15:0] V_SYNC_ACT	 =	16'd480;
  localparam [15:0] V_SYNC_FRONT =	16'd14;
  localparam [15:0] V_SYNC_INT	 =	16'd1;
  localparam [15:0] V_SYNC_BACK	 =	16'd30;
  localparam [15:0] V_SYNC_TOTAL =	V_SYNC_ACT+V_SYNC_FRONT+V_SYNC_INT+V_SYNC_BACK;

  logic [15:0] 			    h_count, h_count_next;
  logic [15:0] 			    v_count, v_count_next;

  assign v_active = v_count < V_SYNC_ACT;
  assign h_active = h_count < H_SYNC_ACT;

  assign vs = (v_count >= V_SYNC_ACT+V_SYNC_FRONT) && 
	      (v_count < V_SYNC_ACT+V_SYNC_FRONT+V_SYNC_INT);
  assign hs = (h_count >= H_SYNC_ACT+H_SYNC_FRONT) &&
	      (h_count < H_SYNC_ACT+H_SYNC_FRONT+H_SYNC_INT);

  always_ff @(posedge clock or posedge rst_i)
    begin
      if (rst_i)
	begin
	  h_count <= 16'h0;
	  v_count <= 16'h0;
	end
      else
	begin
	  h_count <= h_count_next;
	  v_count <= v_count_next;
	end
    end
  
  always_comb
    begin
      h_count_next = h_count;
      v_count_next = v_count;
      
      if (h_count < H_SYNC_TOTAL)
	h_count_next = h_count + 1'b1;
      else
	begin
	  h_count_next = 16'h0;
	  if (v_count < V_SYNC_TOTAL)
	    v_count_next = v_count + 1'b1;
	  else
	    v_count_next = 16'h0;
	end
    end

endmodule
