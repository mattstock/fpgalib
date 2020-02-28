module dualfifo
  #(AWIDTH=4,
    DWIDTH=32)
  (input                     rclk_i,
   input 		     wclk_i,
   input 		     wrst_i,
   input 		     rrst_i, 
   input 		     write,
   input 		     read,
   input [DWIDTH-1:0] 	     in,
   output logic [DWIDTH-1:0] out,
   output logic 	     wfull,
   output logic 	     rempty);

  localparam DEPTH = 2**AWIDTH;
  
  logic [DWIDTH-1:0] 	    values[DEPTH-1:0];
  logic [AWIDTH-1:0] 	    ridx, widx;
  logic [AWIDTH:0] 	    wgray, wbin, wq2_rgray, wq1_rgray,
			    rgray, rbin, rq2_wgray, rq1_wgray,
			    wgray_next, wbin_next,
			    rgray_next, rbin_next;
  logic 		    wfull_next, rempty_next;

  // Write half
  assign wbin_next = wbin + { {(AWIDTH){1'b0}}, (write && !wfull) };
  assign wgray_next = (wbin_next >> 1) ^ wbin_next;
  assign widx = wbin[AWIDTH-1:0];
  assign wfull_next = (wgray_next == { ~wq2_rgray[AWIDTH:AWIDTH-1],
				       wq2_rgray[AWIDTH-2:0] });
  
  always_ff @(posedge wclk_i or posedge wrst_i)
    if (wrst_i)
      begin
	{ wq2_rgray, wq1_rgray } <= 2'h0;
	{ wbin, wgray } <= 2'h0;
	wfull <= 1'h0;
      end
    else
      begin
	{ wq2_rgray, wq1_rgray } <= { wq1_rgray, rgray };
	{ wbin, wgray } <= { wbin_next, wgray_next };
	wfull <= wfull_next;
	if (write && !wfull)
	  begin
	    values[widx] <= in;
	  end
      end

  // Read section
  assign rbin_next = rbin + { {(AWIDTH){1'b0}}, (read && !rempty) };
  assign rgray_next = (rbin_next >> 1) ^ rbin_next;
  assign ridx = rbin[AWIDTH-1:0];
  assign rempty_next = (rgray_next == rq2_wgray);
  assign out = values[ridx];
  
  always_ff @(posedge rclk_i or posedge rrst_i)
    if (rrst_i)
      begin
	{ rq2_wgray, rq1_wgray } <= 2'h0;
	{ rbin, rgray } <= 2'h0;
	rempty <= 1'h1;
      end
    else
      begin
	{ rq2_wgray, rq1_wgray } <= { rq1_wgray, wgray };
	{ rbin, rgray } <= { rbin_next, rgray_next };
	rempty <= rempty_next;
      end
	
endmodule

