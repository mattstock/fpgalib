module arbiter
  #(AWIDTH=15, DWIDTH=32)
  (input                     clk_i,
   input 		     rst_i,
   input [1:0] 		     cyc_i,
   input [1:0] 		     we_i,
   input [3:0] 		     sel_i[1:0],
   input [AWIDTH-1:0] 	     adr_i[1:0],
   input [DWIDTH-1:0] 	     m_dat_i[1:0],
   output logic [DWIDTH-1:0] m_dat_o[1:0],
   output logic [1:0] 	     stall_o,
   output logic [1:0] 	     ack_o,
   // the shared bus signals below
   output logic 	     we_o,
   output logic [AWIDTH-1:0] adr_o,
   output logic [DWIDTH-1:0] s_dat_o,
   input 		     ack_i,
   input [DWIDTH-1:0] 	     s_dat_i,
   input 		     stall_i,
   output logic [3:0] 	     sel_o,
   output logic 	     stb_o);

  assign stb_o = |cyc_i;
  
  logic [1:0] 		     stall_next, ack_next;
  logic [DWIDTH-1:0] 	     m_dat_next[1:0];
  logic [2:0] 		     state, state_next;

  localparam [2:0] S_IDLE = 3'h0, S_0 = 3'h1, S_1 = 3'h2,
    S_10 = 3'h3, S_01 = 3'h4;
  
  always_ff @(posedge clk_i or posedge rst_i)
    if (rst_i)
      begin
	stall_o = 2'h0;
	ack_o = 2'h0;
	m_dat_o[0] = 32'h0;
	m_dat_o[1] = 32'h0;
	state = 3'h0;
      end
    else
      begin
	stall_o = stall_next;
	ack_o = ack_next;
	m_dat_o[0] = m_dat_next[0];
	m_dat_o[1] = m_dat_next[1];
	state = state_next;
      end

  always_comb
    begin
      state_next = state;
      stall_next = stall_o;
      ack_next = ack_o;
      m_dat_next[0] = m_dat_o[0];
      m_dat_next[1] = m_dat_o[1];
      we_o = 1'h0;
      s_dat_o = 32'h0;
      adr_o = 'h0;
      
      case (state)
	S_IDLE:
	  if (cyc_i[0])
	    begin
	      state_next = S_0;
	      we_o = we_i[0];
	      sel_o = sel_i[0];
	      s_dat_o = m_dat_i[0];
	      adr_o = adr_i[0];
	    end
	  else if (cyc_i[1])
	    begin
	      state_next = S_1;
	      we_o = we_i[1];
	      sel_o = sel_i[1];
	      s_dat_o = m_dat_i[1];
	      adr_o = adr_i[1];
	    end
	S_0:
	  begin
	    stall_next = {cyc_i[1], stall_i};
	    m_dat_next[0] = s_dat_i;
	    ack_next = {1'b0, ack_i};
	    adr_o = adr_i[0];
	    we_o = we_i[0];
	    sel_o = sel_i[0];
	    s_dat_o = m_dat_i[0];
	    if (!cyc_i[0])
	      if (cyc_i[1])
		begin
		  state_next = S_1;
		  stall_next = {stall_i, cyc_i[0]};
		  we_o = we_i[1];
		  sel_o = sel_i[1];
		  s_dat_o = m_dat_i[1];
		  adr_o = adr_i[1];
		end
	      else
		state_next = S_IDLE;
	  end // case: S_0
	S_1:
	  begin
	    stall_next = {stall_i, cyc_i[0]};
	    m_dat_next[1] = s_dat_i;
	    ack_next = {ack_i, 1'b0};
	    adr_o = adr_i[1];
	    we_o = we_i[1];
	    sel_o = sel_i[1];
	    s_dat_o = m_dat_i[1];
	    if (cyc_i[0])
	      begin
		state_next = S_0;
		stall_next = {cyc_i[1], stall_i};
		we_o = we_i[0];
		sel_o = sel_i[0];
		s_dat_o = m_dat_i[0];
		adr_o = adr_i[0];
	      end
	    else if (!cyc_i[1])
	      state_next = S_IDLE;
	  end // case: S_1
	default: state_next = S_IDLE;
      endcase // case (state)
    end

endmodule
