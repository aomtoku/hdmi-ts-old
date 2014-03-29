`timescale 1ns / 1ps

`define simulation

module tb_gmii2fifo();


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
wire [28:0] rx_vdin;
wire [10:0] y_din = rx_vdin[26:16];
wire [ 1:0] x_din = rx_vdin[28:27];
wire [28:0] rx_vdout;
wire rx_vempty, rx_vfull;
wire rx_fifo_wr_en;
wire TXEN;
wire [7:0]TXD;
wire [11:0]rx_axdin, ax_rx_dout;
wire ax_recv_wr_en, ax_send_rd_en;
wire rx_aempty, rx_afull;


gmii2fifo24 gmii2fifo24(
	.clk125(gmii_tx_clk),
	.sys_rst(sys_rst),
	.id(1'd0),
	.rxd(TXD),
	.rx_dv(TXEN),
	.datain(rx_vdin),
	.recv_en(rx_fifo_wr_en),
	.packet_en(),
	.aux_data_in(rx_axdin),
	.aux_wr_en(ax_recv_wr_en)
);

wire fifo_read;
afifo29 recv_video_fifo(
     .Data(rx_vdin),
     .WrClock(gmii_tx_clk),
     .RdClock(fifo_clk),
     .WrEn(rx_fifo_wr_en),
     .RdEn(fifo_read),
     .Reset(sys_rst),
     .RPReset(),
     .Q(rx_vdout),
     .Empty(rx_vempty),
     .Full(rx_vfull)
);

wire ax_rx_rd_en;
afifo12 recv_audio_fifo(
     .Data(rx_axdin),
     .WrClock(gmii_tx_clk),
     .RdClock(fifo_clk),
     .WrEn(ax_recv_wr_en),
     .RdEn(ax_rx_rd_en),
     .Reset(sys_rst),
     .RPReset(),
     .Q(ax_rx_dout),
     .Empty(rx_aempty),
     .Full(rx_afull)
);

wire VGA_HSYNC_INT, VGA_VSYNC_INT;
wire          bgnd_hsync;
wire          bgnd_hblnk;
wire          bgnd_vsync;
wire          bgnd_vblnk;
parameter HPIXELS_HDTV720P = 11'd1280; //Horizontal Live Pixels
parameter VLINES_HDTV720P  = 11'd720;  //Vertical Live ines
parameter HSYNCPW_HDTV720P = 11'd40;  //HSYNC Pulse Width
parameter VSYNCPW_HDTV720P = 11'd5;    //VSYNC Pulse Width
parameter HFNPRCH_HDTV720P = 11'd110; //Horizontal Front Portch hotoha72
parameter VFNPRCH_HDTV720P = 11'd5;    //Vertical Front Portch
parameter HBKPRCH_HDTV720P = 11'd220;  //Horizontal Front Portch
parameter VBKPRCH_HDTV720P = 11'd20;   //Vertical Front Portch

parameter [10:0]tc_hsblnk = HPIXELS_HDTV720P - 11'd1;
parameter [10:0]tc_hssync = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P;
parameter [10:0]tc_hesync = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P;
parameter [10:0]tc_heblnk = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P + HBKPRCH_HDTV720P;
parameter [10:0]tc_vsblnk =  VLINES_HDTV720P - 11'd1;
parameter [10:0]tc_vssync =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P;
parameter [10:0]tc_vesync =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P;
parameter [10:0]tc_veblnk =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P + VBKPRCH_HDTV720P;
parameter hvsync_polarity = 1'b0;

wire restart = sys_rst;
wire [10:0] bgnd_hcount;
wire [10:0] bgnd_vcount;

timing_gen timing_gen (
	.tc_hsblnk(tc_hsblnk), //input
	.tc_hssync(tc_hssync), //input
	.tc_hesync(tc_hesync), //input
	.tc_heblnk(tc_heblnk), //input
	.hcount(bgnd_hcount), //output
	.hsync(VGA_HSYNC_INT), //output
	.hblnk(bgnd_hblnk), //output
	.tc_vsblnk(tc_vsblnk), //input
	.tc_vssync(tc_vssync), //input
	.tc_vesync(tc_vesync), //input
	.tc_veblnk(tc_veblnk), //input
	.vcount(bgnd_vcount), //output
	.vsync(VGA_VSYNC_INT), //output
	.vblnk(bgnd_vblnk), //output
	.restart(restart),
	.clk74m(fifo_clk),
	.clk125m(gmii_tx_clk),
	.fifo_wr_en(rx_fifo_wr_en),
	.y_din(y_din)
);

wire [11:0]rx_hcnt = {1'd0,bgnd_hcount};
wire [11:0]rx_vcnt = {1'd0,bgnd_vcount};

datacontroller dataproc(
	.i_clk_74M(fifo_clk),
	.i_rst(sys_rst),
	.i_hcnt(rx_hcnt),
	.i_vcnt(rx_vcnt),
	.i_format(2'b00),
	.fifo_read(fifo_read),
	.data(rx_vdout),
	.sw(1'b1),
	.o_r(),
	.o_g(),
	.o_b()
);

//assign ax_recv_rd_en = ({init,initq} == 2'b10) || ade;
//assign ax_recv_rd_en = (bgnd_vblnk) ? : (hcnt >= 1559 & hcnt <= 1590) ? 1'b1 : 1'b0;
wire ad = (rx_hcnt >= 1559 & rx_hcnt <= 1590) ? 1'b1 : 1'b0;  //Debug mode ADE. forcing read enable
reg rx_vde;
//
// ax_recv_rd_en Generator
//
reg init;
reg [3:0]b_left;
reg fl;
reg [5:0]acnt;
reg axp;
reg ck;
reg audio;
reg ax_recv_rd_en;
assign ax_rx_rd_en =  ax_recv_rd_en;

always@(posedge fifo_clk)begin
	if(sys_rst)begin
		fl            <= 1'b0;
		init          <= 1'b0;
		ax_recv_rd_en <= 1'b0;
		b_left        <= 4'd0;
	  acnt          <= 6'd0;
		axp           <= 1'b0;
		ck            <= 1'b0;
		audio         <= 1'b0;
	end else begin
	  b_left <= ax_rx_dout[11:8];
    // Checking Audio onoff //
	  if(~rx_aempty)
	    ck <= 1'b1; 
	  if(rx_vcnt == 12'd0)begin
		if(ck)
		  audio <= 1'b1;
		else
		  audio <= 1'b0;
		ck <= 1'b0;
	  end

	  if(rx_vde)
		init <= 1'b1;
	  if(~rx_vde & ~rx_aempty & init)
		fl <= 1'b1;
  	  else begin
		fl <= 1'b0;
		axp <= 1'b0;
	  end

		// Start logic 
		if(fl & rx_hcnt == 12'd1530)begin
		  acnt          <= 6'd0;
		  ax_recv_rd_en <= 1'b1;
		  axp           <= 1'b1;
		end
		
		if(axp)begin
		  if(acnt == 6'd35)begin
			  acnt <= 6'd0; 
			  //if(b_left <= axdout[11:8])
			  if(b_left > 0)
			    ax_recv_rd_en <= 1'b1; // 0
			  else
			    ax_recv_rd_en <= 1'b0; // 1
		  end else if(acnt == 6'd31)begin
		    ax_recv_rd_en <= 1'b0; 
			  acnt <= acnt + 6'd1;
		  end else begin
			  acnt <= acnt + 6'd1;
		  end
		end
	end
end

/////////////////////////////////////////
// V/H SYNC and DE generator
/////////////////////////////////////////

wire active;
reg active_q;
reg vsync, hsync;
reg VGA_HSYNC, VGA_VSYNC;

assign active = !bgnd_hblnk && !bgnd_vblnk;

always @ (posedge fifo_clk) begin
	hsync <= VGA_HSYNC_INT ^ hvsync_polarity ;
	vsync <= VGA_VSYNC_INT ^ hvsync_polarity ;
	VGA_HSYNC <= hsync;
	VGA_VSYNC <= vsync;

	active_q <= active;
	rx_vde <= active_q;
end


wire vsyn,hsyn;
reg [23:0]tmds_data;
wire rd_en;
wire [47:0]tx_data;

wire [10:0]hcnt,vcnt;
wire video_en;

// Generating a Number of audio enable period
reg [3:0] ade_c;
reg [3:0] ade_num;
reg [4:0] cnt_32;
reg       vde_b;

always @ (posedge fifo_clk)begin
  vde_b <= vde;
  if(sys_rst || hcnt == 11'd1)begin
	  ade_c   <= 4'd0;
	  cnt_32  <= 5'd0; 
	  ade_num <= ade_c;
	end else begin
	  if(ade)begin
		  if(cnt_32 == 5'd31)begin
			cnt_32 <= 5'd0;
			ade_c  <= ade_c + 4'd1;
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


wire [11:0] adin,ax_tx_dout;
wire aempty,afull;
wire ade;

reg ainit;
always@(posedge fifo_clk)
  if(sys_rst)
		ainit <= 1'b0;
	else if(video_en)
		ainit <= 1'b1;

wire a_wr_en = ainit & ade;

afifo12 send_audio_fifo(
     .Data(adin),
     .WrClock(fifo_clk),
     .RdClock(gmii_tx_clk),
     .WrEn(a_wr_en),
     .RdEn(ax_send_rd_en),
     .Reset(sys_rst),
     .RPReset(),
     .Q(ax_tx_dout),
     .Empty(aempty),
     .Full(afull)
);

wire vperi = (vcnt >= 21) && (vcnt <= 741);
wire fil_wr_en =  video_en & (hcnt >= 12'd220 & hcnt < 12'd1420);
wire [23:0] out = {12'd0,ax_tx_dout};
wire ade_tx = ~video_en && ((hcnt >= 11'd1504) && (hcnt < 11'd1510));

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
	.vperi(vperi),
	// AX FIFO
	
	.adesig(ade_tx),
	.ade_num(ade_num),
	.axdout(out),
	.ax_send_full(afull),
	.ax_send_empty(aempty),
	.ax_send_rd_en(ax_send_rd_en),

	/*** Ethernet PHY GMII ****/
	.tx_clk(gmii_tx_clk),
	.tx_en(TXEN),
	.txd(TXD),
	.sw(1'b1)
);

wire vde = (hcnt > 220 && hcnt < 1500) && (vcnt > 20 && vcnt < 740); 

tmds_timing timing_inst (
  .rx0_pclk(fifo_clk),
  .rstbtn_n(sys_rst), 
  .rx0_hsync(hsyn),
  .rx0_vsync(vsyn),
  .video_en(video_en),
  .index(),
  .video_hcnt(),
  .video_vcnt(),
  .vcounter(vcnt),
  .hcounter(hcnt)
);

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
assign ade  = aa[0];
assign adin = adata;

always@(posedge fifo_clk)begin
  {vv,hh,aa,tmds_data,adata}     <= vrom[vcounter];
	vcounter	<= vcounter + 22'd1;
end

initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_gmii2fifo);
	$readmemh("request.mem",vrom);
	//$readmemh("arequest.mem",arom);
	sys_rst = 1'b1;
	vcounter = 0;
	acounter = 0;
	
	waitclock;
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	
	#40000000;
	$finish;
end

endmodule
