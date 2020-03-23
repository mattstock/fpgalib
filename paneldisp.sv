`include "wb.vh"

module paneldisp
  #(CLKFREQ = 50000000)
  (
   input 	clk_i,
   input 	rst_i,
   if_wb.slave  cpu_ins,
   if_wb.slave  cpu_dat,
   if_wb.master sys_ins,
   if_wb.master sys_dat,
   input 	seg_miso,
   output 	seg_mosi,
   output 	seg_sclk,
   output [2:0] seg_ss);

  logic [31:0] 	cpu_insdat_i, cpu_insdat_o;
  logic [31:0] 	cpu_datdat_i, cpu_datdat_o;
  logic [31:0] 	sys_insdat_i, sys_insdat_o;
  logic [31:0] 	sys_datdat_i, sys_datdat_o;
  
`ifdef NO_MODPORT_EXPRESSIONS
  assign sys_insdat_i = sys_ins.dat_s;
  assign sys_ins.dat_m = sys_insdat_o;
  assign sys_datdat_i = sys_dat.dat_s;
  assign sys_dat.dat_m = sys_datdat_o;

  assign cpu_insdat_i = cpu_ins.dat_m;
  assign cpu_ins.dat_s = cpu_insdat_o;
  assign cpu_datdat_i = cpu_dat.dat_m;
  assign cpu_dat.dat_s = cpu_datdat_o;
`else
  assign sys_insdat_i = sys_ins.dat_i;
  assign sys_ins.dat_o = sys_insdat_o;
  assign sys_datdat_i = sys_dat.dat_i;
  assign sys_dat.dat_o = sys_datdat_o;

  assign cpu_insdat_i = cpu_ins.dat_i;
  assign cpu_ins.dat_o = cpu_insdat_o;
  assign cpu_datdat_i = cpu_dat.dat_i;
  assign cpu_dat.dat_o = cpu_datdat_o;
`endif
  
  always_comb
    begin
      sys_ins.cyc = cpu_ins.cyc;
      sys_ins.stb = cpu_ins.stb;
      sys_ins.sel = cpu_ins.sel;
      sys_ins.we = cpu_ins.we;
      sys_ins.adr = cpu_ins.adr;
      sys_insdat_o = cpu_insdat_i;
      cpu_ins.ack = sys_ins.ack;
      cpu_ins.stall = sys_ins.stall;
      cpu_insdat_o = sys_insdat_i;
      
      sys_dat.cyc = cpu_dat.cyc;
      sys_dat.stb = cpu_dat.stb;
      sys_dat.sel = cpu_dat.sel;
      sys_dat.we = cpu_dat.we;
      sys_dat.adr = cpu_dat.adr;
      sys_datdat_o = cpu_datdat_i;
      cpu_dat.ack = sys_dat.ack;
      cpu_dat.stall = sys_dat.stall;
      cpu_datdat_o = sys_datdat_i;
    end // always_comb

  /* So what we want to do is to sample the bus every second or so,
   * and display the results on to the 7 segment displays based on our
   * state.
   * 
   * SPI format for the devices is 00 01 dd vv v0
   * */
  
  typedef enum bit [3:0] { S_IDLE, S_CMD, S_CMD_WAIT, S_ADR, S_ADR_WAIT,
			   S_DH, S_DH_WAIT, S_DL, S_DL_WAIT } state_t;
  
  logic [7:0] spi_in, spi_out, spi_out_next;
  logic       spi_start, spi_done;
  state_t     state, state_next;
  logic [31:0] ticks;
  logic [2:0]  adr, adr_next;
  logic [7:0]  panel_out;
  logic [3:0]  panel_in;
  logic [2:0]  disp, disp_next;
  logic [31:0] regval, regval_next, special;
  
  always_ff @(posedge clk_i)
    begin
      if (rst_i)
	begin
	  state <= S_IDLE;
	  spi_out <= 8'h00;
	  adr <= 3'h0;
	  ticks <= 32'h0;
	  disp <= 2'h0;
	  regval <= 32'h0;
	end
      else
	begin
	  state <= state_next;
	  spi_out <= spi_out_next;
	  adr <= adr_next;
	  disp <= disp_next;
	  regval <= regval_next;
	  ticks <= (ticks == CLKFREQ/10 ? 32'h0 : ticks + 32'h1);
	end
    end

  always_comb
    case (disp[2:1])
      2'h0: seg_ss = 3'b110;
      2'h1: seg_ss = 3'b101;
      2'h2: seg_ss = 3'b011;
      2'h3: seg_ss = 3'b111;
    endcase // case (disp[2:1])
    
  always_comb
    case (adr)
      4'h0: panel_in = regval[31:28];
      4'h1: panel_in = regval[27:24];
      4'h2: panel_in = regval[23:20];
      4'h3: panel_in = regval[19:16];
      4'h4: panel_in = regval[15:12];
      4'h5: panel_in = regval[11:8];
      4'h6: panel_in = regval[7:4];
      4'h7: panel_in = regval[3:0];
    endcase

  assign special = { cpu_ins.cyc,
		     cpu_ins.stb,
		     cpu_ins.ack,
		     cpu_ins.stall,
		     cpu_dat.cyc,
		     cpu_dat.stb,
		     cpu_dat.ack,
		     cpu_dat.stall,
		     cpu_dat.sel, // 4
		     3'h0, cpu_dat.we,
		     16'h0 };
      
  always_comb
    begin
      state_next = state;
      spi_out_next = spi_out;
      adr_next = adr;
      disp_next = disp;
      regval_next = regval;
      
      spi_start = 1'h0;

      case (state)
	S_IDLE:
	  begin
	    if (ticks == 32'h0)
	      begin
		state_next = S_CMD;
		regval_next = cpu_ins.adr;
		spi_out_next = 8'h01; // write
	      end
	  end
	S_CMD:
	  begin
	    spi_start = 1'h1;
	    state_next = S_CMD_WAIT;
	  end
	S_CMD_WAIT:
	  begin
	    if (spi_done)
	      begin
		spi_out_next = { disp[0], adr };
		state_next = S_ADR;
	      end
	  end
	S_ADR:
	  begin
	    spi_start = 1'h1;
	    state_next = S_ADR_WAIT;
	  end
	S_ADR_WAIT:
	  begin
	    if (spi_done)
	      begin
		spi_out_next = panel_out;
		state_next = S_DH;
	      end
	  end
	S_DH:
	  begin
	    spi_start = 1'h1;
	    state_next = S_DH_WAIT;
	  end
	S_DH_WAIT:
	  begin
	    if (spi_done)
	      begin
		spi_out_next = 8'h00; // skip tick and colon
		state_next = S_DL;
	      end
	  end
	S_DL:
	  begin
	    spi_start = 1'h1;
	    state_next = S_DL_WAIT;
	  end
	S_DL_WAIT:
	  begin
	    if (spi_done)
	      begin
		adr_next = adr + 3'h1;
		spi_out_next = 8'h01; // pre another write
		state_next = S_CMD;
		if (adr == 3'h7)
		  begin
		    if (disp == 3'h5)
		      begin
			disp_next = 3'h0;
			state_next = S_IDLE;
		      end
		    else
		      begin
			disp_next = disp + 3'h1;
			case (disp) // this is forward-looking
			  4'h0: regval_next = sys_insdat_i;
			  4'h1: regval_next = cpu_dat.adr;
			  4'h2: regval_next = cpu_datdat_i;
			  4'h3: regval_next = cpu_datdat_o;
			  default: regval_next = special;
			endcase // case (disp)
			state_next = S_CMD;
		      end
		  end
	      end
	  end
      endcase // case (state)
    end

  paneldigit pd0(.in(panel_in),
		 .out(panel_out));
  
  spi_xcvr #(.CLKFREQ(CLKFREQ)) xcvr0(.clk_i(clk_i),
				      .rst_i(rst_i),
				      .start(spi_start),
				      .conf(8'h0),
				      .rx(spi_in),
				      .tx(spi_out),
				      .done(spi_done),
				      .miso(seg_miso),
				      .mosi(seg_mosi),
				      .sclk(seg_sclk));

  
  
endmodule // paneldisp
