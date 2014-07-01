`timescale 1ns / 1ps

`define simulation
`include "setup.v"

module tb_ether();


//
// System Clock 125MHz
//
reg sys_clk;
initial sys_clk = 1'b0;
always #4 sys_clk = ~sys_clk;

reg gmii_tx_clk;
initial gmii_tx_clk = 1'b0;
always #4 gmii_tx_clk = ~gmii_tx_clk;

reg fifo_clk;
initial fifo_clk = 1'b0;
always #6.734 fifo_clk = ~fifo_clk;


//
// Test Bench
//
reg sys_rst;
wire vsyn,hsyn;
reg [23:0]tmds_data;
wire rd_en;
wire TXEN;
wire [7:0]TXD;
wire [47:0]tx_data;


wire [10:0]hcnt,vcnt;
wire hact,vact;
wire video_en;

// Generating a Number of audio enable period
reg [3:0] rxade_c;
reg [3:0] ade_num;
reg [4:0] cnt_32;
reg       vde_b;

reg [15:0] pos;
always @ (posedge fifo_clk)begin
  if(sys_rst)begin
	   pos <= 16'd0;
	end else begin
	  if(vde)
			pos <= 16'd0;
		else
			pos <= pos + 16'd1;
	end
end

reg  ax_ts_rd_en;
reg  ainit;

wire ax_send_wr_en;
wire ade_tx  = ~vact & (~ax_send_wr_en & rx0_hsync);
wire vde     = (hcnt > 220 && hcnt < 1500) && (vcnt > 20 && vcnt < 740); 
wire a_wr_en = ainit & txade;
wire txx     = ainit & ~video_en & (hcnt == 11'd1447); // The count timing ADE period
wire vadx    = ainit & ({vde,vde_b} == 2'b10); // The count timing ADE periods

always @ (posedge fifo_clk)begin
  ax_ts_rd_en <= ade_tx;
  vde_b <= vde;
  if(sys_rst)begin
	  cnt_32  <= 5'd0; 
	  rxade_c   <= 4'd0;
	  ade_num <= 4'd0;
	end else begin
	  if(a_wr_en & cnt_32 == 5'd0)
			rxade_c <= rxade_c + 4'd1;
	  if(({ade_tx,ax_ts_rd_en} == 2'b10) | vadx)begin
	    rxade_c  <= 4'd0;
	    ade_num <= rxade_c;
	  end
	  if(a_wr_en)begin
	    if(cnt_32 == 5'd31)begin
	      cnt_32 <= 5'd0;
	    end else begin
	      cnt_32 <= cnt_32 + 5'd1;
	    end
		end
	end
end




wire [47:0]vdin;
assign vdin = {1'b0,vcnt,1'b0,hcnt,tmds_data};
wire vempty,vfull;
wire send_fifo_wr_en = video_en && (hcnt >= 12'd220 && hcnt < 12'd1420);

afifo48 send_video_fifo(
     .Data(vdin),
     .WrClock(fifo_clk),
     .RdClock(gmii_tx_clk),
     .WrEn(send_fifo_wr_en),
     .RdEn(rd_en),
     .Reset(sys_rst),
     .RPReset(),
     .Q(tx_data),
     .Empty(vempty),
     .Full(vfull)
);


wire [11:0] adin;
wire tx_aempty,tx_afull;
wire ade;

always@(posedge fifo_clk)
  if(sys_rst)
		ainit <= 1'b0;
	else if(video_en)
		ainit <= 1'b1;
`define AUXTEST

`ifdef AUXTEST
reg [15:0] posbuf;
reg [3:0] ax0, ax1, ax2;
reg adebuf,auxinit;
always @ (posedge fifo_clk)begin
  if(sys_rst)begin
    adebuf <= 1'b0;
	posbuf <= 16'd0;
	ax0    <= 4'd0;
	ax1    <= 4'd0;
	ax2    <= 4'd0;
  end else begin
    adebuf <= txade;
	posbuf <= pos;
	ax0 <= adin[3:0];
	ax1 <= adin[7:4];
	ax2 <= adin[11:8];
  end 
  if(sys_rst)
	  auxinit <= 1'b0;
  if(video_en)
	  auxinit <= 1'b1;
  if({txade,adebuf}==2'b10)
	  auxinit <= 1'b0;
  if(~vact)
	  auxinit <= 1'b0;
end

wire axrst = ({txade,adebuf}==2'b10) & auxinit;


wire [24:0] ax_din = {posbuf,ax2,ax1,ax0[2]};
wire [24:0] ax_dout;
assign   ax_send_wr_en = (ainit & adebuf) ;

`else

wire [24:0] ax_din = {pos, rx0_aux2, rx0_aux1, rx0_aux0[2]};
wire [24:0] ax_dout;
assign   ax_send_wr_en = (ainit & ade) ;

`endif

wire ax_send_rd_en;

afifo25 send_audio_fifo(
     .Data(ax_din),
     .WrClock(fifo_clk),
     .RdClock(gmii_tx_clk),
     .WrEn(ax_send_wr_en),
     .RdEn(ax_send_rd_en),
     .Reset(sys_rst |  axrst),
     .RPReset(),
     .Q(ax_dout),
     .Empty(tx_aempty),
     .Full(tx_afull)
);

wire fil_wr_en =  video_en & (hcnt > 12'd220 & hcnt <= 12'd1420);
wire [24:0] out = ax_dout;

gmii_tx gmiisend(
    .id(1'b1),
	/*** FIFO ***/
	.fifo_clk(fifo_clk),
	.sys_rst(sys_rst),
	.dout(tx_data), //48bit
	.empty(vempty),
	.full(full),
	.rd_en(rd_en),
	.wr_en(fil_wr_en),
	// AX FIFO
	.adesig(ade_tx),
	.ade_num(ade_num),
	.axdout(out),
	.ax_send_empty(tx_aempty),
	.ax_send_rd_en(ax_send_rd_en),
	/*** Ethernet PHY GMII ****/
	.tx_clk(gmii_tx_clk),
	.tx_en(TXEN),
	.txd(TXD),
	.sw(1'b1)
);

tmds_timing timing_inst (
  .rx0_pclk(fifo_clk),
  .rstbtn_n(sys_rst), 
  .rx0_hsync(hsyn),
  .rx0_vsync(vsyn),
  .video_en(video_en),
  .index(),
  .video_hcnt(),
  .video_vcnt(),
  .vactive(vact),
  .hactive(hact),
  .vcounter(vcnt),
  .hcounter(hcnt)
);

//--------------------------------------------
//
// generate Audio Enable period
//

wire txade;
reg [4:0] adecnt;
reg [11:0]aclkc;
reg vde_h,ade_q;
reg init, initq,initqq;
wire [24:0]axdout;


// Generate AUDIO FIFO data
wire [24:0]axdin_s,axdout_s;
wire ax_s_empty, ax_s_full;
wire ax_s_wr_en, ax_s_rd_en;
reg [11:0]ade_buf, ade_hcnt;
reg [23:0]ade_out;
reg ade_gg;
reg start;
reg st,stc;

reg       vblnk;
reg [ 5:0]acnt;
reg [ 2:0]astate;
reg [10:0]clk_ade;

parameter FIRST = 3'd0;
parameter READY = 3'd1;
parameter IDLE  = 3'd2;
parameter ADE   = 3'd3;
parameter ADE_L = 3'd4;

wire [15:0] ctim = axdout[24:9];
wire fifo_read;

reg [15:0] txpos;
always @ (posedge fifo_clk)begin
  if(sys_rst)
	  txpos <= 16'd0;
  else begin
	  if(rxvde)
		  txpos <= 16'd0;
      else
		  txpos <= txpos + 16'd1;
  end
end

reg        adep;
reg [15:0] start_pos;
reg [8:0]  auxd;
reg        xinit;

reg firstvde, vdevde;
always @ (posedge fifo_clk)begin 
  if(sys_rst)begin
    vdevde <= 1'b0;
	firstvde <= 1'b0;
  end else begin
    vdevde <= rxvde;
    if({rxvde,vdevde}==2'b01)
      firstvde <= 1'b1;
    if(txpos == 16'd2000)
	  firstvde <= 1'b0;
  end
end 

wire vde1st = (~firstvde & vde);

always@(posedge fifo_clk)begin
	if(sys_rst)begin
		ax_recv_rd_en <=  1'b0;
		astate        <=  3'd0; 
		clk_ade       <= 11'd0;
	    acnt          <=  6'd0;
		vblnk         <=  1'b0;
		adep          <=  1'b0;
		start_pos     <= 16'd0;
		auxd          <=  9'd0;
		xinit         <=  1'b0;
	end else begin
	  if(~vrx_empty & fifo_read)
		  xinit <= 1'b1;
      /* aux recv RST logic */
      if(vde1st && (start_pos > 16'd400))
	    ax_recv_rd_en <= 1'b1;
      else 
        ax_recv_rd_en <= 1'b0;

	  if(vrx_empty)
		  astate <= FIRST;

	  case(astate)
	      FIRST : if(rxvde & xinit) astate <= READY;
          READY : begin  //Initial 
		            if(txpos == 16'd0 && ~rxvde && ~rx_aempty)
						ax_recv_rd_en <= 1'b1;
					if(txpos == 16'd1)begin
						ax_recv_rd_en <= 1'b0;
						start_pos     <= axdout[24:9];
						auxd          <= axdout[8:0];
						astate        <= IDLE;
                    end
                  end
          IDLE  : begin
			         if(txpos+1 == start_pos)begin
                        ax_recv_rd_en <= 1'b1;
                        astate        <= ADE;
                        acnt <= 6'd0;
						adep <= 1'b1;
                     end else
                        ax_recv_rd_en <= 1'b0;
                  end
          ADE   : begin
					 auxd <= axdout[8:0];
                     acnt <= acnt + 6'd1;
					 adep <= 1'b1;
                     ax_recv_rd_en <= 1'b1;
                     if(acnt == 6'd30)
                        astate <= ADE_L;
                  end
          ADE_L : begin
                     if(txpos+1 == axdout[24:9])begin
						auxd    <= axdout[8:0];
                        astate  <= ADE;
                        acnt    <= 6'd0;
						adep    <= 1'b0;
						ax_recv_rd_en <= 1'b1;
                     end else begin
                        astate  <= IDLE;
						adep <= 1'b0;
						start_pos <= axdout[24:9];
                        ax_recv_rd_en <= 1'b0;
                     end
                  end
		endcase
		
	end
end

reg [10:0] tc_hsblnk;
reg [10:0] tc_hssync;
reg [10:0] tc_hesync;
reg [10:0] tc_heblnk;
reg [10:0] tc_vsblnk;
reg [10:0] tc_vssync;
reg [10:0] tc_vesync;
reg [10:0] tc_veblnk;


//---------------------------------------------------
// Test Bench
//---------------------------------------------------

wire        recv_fifo_wr_en;
wire [24:0] axdin;
wire        ax_recv_wr_en;
wire [10:0] tx_hcnt,tx_vcnt;
wire [10:0] y_din = fifo_din[26:16];
wire        tx_b_hsync,tx_b_vsync; 
wire        tx_vblnk,tx_hblnk;

timing_gen txtiming(
  .tc_hsblnk(tc_hsblnk),
  .tc_hssync(tc_hssync),
  .tc_hesync(tc_hesync),
  .tc_heblnk(tc_heblnk),

  .hcount(tx_hcnt),
  .hsync(tx_b_hsync),
  .hblnk(tx_hblnk),

  .tc_vsblnk(tc_vsblnk),
  .tc_vssync(tc_vssync),
  .tc_vesync(tc_vesync),
  .tc_veblnk(tc_veblnk),

  .vcount(tx_vcnt),
  .vsync(tx_b_vsync),
  .vblnk(tx_vblnk),

  .restart(sys_rst),
  .clk74m(fifo_clk),
  .clk125m(sys_clk),

  .fifo_wr_en(recv_fifo_wr_en),
  .rst(),
  .y_din(y_din)
);

wire active;
reg active_q;
reg vsync, hsync;
reg VGA_HSYNC, VGA_VSYNC;
reg rxvde;
reg hvsync_polarity = 0;

assign active = !tx_hblnk && !tx_vblnk;

always @ (posedge fifo_clk) begin
	hsync <= tx_b_hsync ^ hvsync_polarity ;
	vsync <= tx_b_vsync ^ hvsync_polarity ;
	VGA_HSYNC <= hsync;
	VGA_VSYNC <= vsync;

	active_q <= active;
	rxvde <= active_q;
end

wire [11:0] txx_hcnt = {1'b0,tx_hcnt};
wire [11:0] txx_vcnt = {1'b0,tx_vcnt};

datacontroller dataproc(
	.i_clk_74M(fifo_clk),
	.i_rst(sys_rst),
	.i_hcnt(txx_hcnt),
	.i_vcnt(txx_vcnt),
	.i_format(2'b00),
	.fifo_read(fifo_read),
	.data(),
	.sw(/*~DEBUG_SW[3]*/),
	.o_r(/*red_data*/),
	.o_g(/*green_data*/),
	.o_b(/*blue_data*/)
);
wire [28:0]fifo_din,fifo_dout;
wire vrx_empty,vrx_full;

afifo29 recv_video_fifo(
     .Data(fifo_din),
     .WrClock(sys_clk),
     .RdClock(fifo_clk),
     .WrEn(send_fifo_wr_en),
     .RdEn(fifo_read),
     .Reset(sys_rst),
     .RPReset(),
     .Q(fifo_dout),
     .Empty(vrx_empty),
     .Full(vrx_full)
);


gmii2fifo24 gmii2fifo24(
	.clk125(sys_clk),
	.sys_rst(sys_rst),
	.id(1'b0),
	.rxd(TXD),
	.rx_dv(TXEN),
	.datain(fifo_din),
	.recv_en(recv_fifo_wr_en),
	.packet_en(),
	.aux_data_in(axdin),
	.aux_wr_en(ax_recv_wr_en)
);
wire rx_aempty,rx_afull;
reg ax_recv_rd_en;

afifo25 afifo24_recv (
    .Data(axdin),
    .WrClock(sys_clk),
    .RdClock(fifo_clk),
    .WrEn(ax_recv_wr_en),
    .RdEn(ax_recv_rd_en),
    .Reset(sys_rst),
    .RPReset(sys_rst),
    .Q(axdout),
    .Empty(rx_aempty),
    .Full(rx_afull)
);

reg [3:0]b_left,bb_left;
reg fl;
reg flg;

//
// a clock
//

task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask
//
// Scinario
//

reg [11:0] adata;
reg [47:0] vrom [0:2475000];
reg [11:0] arom [0:2024];
reg [21:0]vcounter = 22'd0;
reg [11:0]acounter = 12'd0;
reg [3:0]vv,hh,aa;
assign vsyn = vv[0];
assign hsyn = hh[0];
assign txade  = aa[0];
assign adin = adata;

always@(posedge fifo_clk)begin
  {vv,hh,aa,tmds_data,adata}     <= vrom[vcounter];
	vcounter	<= vcounter + 22'd1;
end

initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_ether);
	$readmemh("request.mem",vrom);
	sys_rst = 1'b1;
	tc_hsblnk = `HPIXELS_HDTV720P - 11'd1;
	tc_hssync = `HPIXELS_HDTV720P - 11'd1 + `HFNPRCH_HDTV720P;
	tc_hesync = `HPIXELS_HDTV720P - 11'd1 + `HFNPRCH_HDTV720P + `HSYNCPW_HDTV720P;
	tc_heblnk = `HPIXELS_HDTV720P - 11'd1 + `HFNPRCH_HDTV720P + `HSYNCPW_HDTV720P + `HBKPRCH_HDTV720P;
	tc_vsblnk =  `VLINES_HDTV720P - 11'd1;
	tc_vssync =  `VLINES_HDTV720P - 11'd1 + `VFNPRCH_HDTV720P;
	tc_vesync =  `VLINES_HDTV720P - 11'd1 + `VFNPRCH_HDTV720P + `VSYNCPW_HDTV720P;
	tc_veblnk =  `VLINES_HDTV720P - 11'd1 + `VFNPRCH_HDTV720P + `VSYNCPW_HDTV720P + `VBKPRCH_HDTV720P;
	vcounter = 0;
	acounter = 0;
	
	waitclock;
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	
	#41000000;
	$finish;
end

endmodule
