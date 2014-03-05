`timescale 1ns / 1ps

`define simulation

module tb_gmiisend();


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
reg empty = 0;
reg full  = 0;
wire rd_en;
wire TXEN;
wire [7:0]TXD;
reg [47:0]tx_data;


wire [10:0]hcnt,vcnt;
wire video_en;

wire ade_tx = ~video_en && ((hcnt >= 11'd1504) && (hcnt < 11'd1510));
wire [3:0]ade_num = (vcnt >= 22 && vnct <= 741) ? 4'd0 : 4'd10;
reg [11:0]ax_dout;
reg ax_send_full;
reg ax_send_empty = 1'b0;
wire ax_send_rd_en;

gmii_tx gmiisend(
    .id(1'b1),
	/*** FIFO ***/
	.fifo_clk(fifo_clk),
	.sys_rst(sys_rst),
	.dout(tx_data), //48bit
	.empty(empty),
	.full(full),
	.rd_en(rd_en),
	.wr_en(vde),
	// AX FIFO
	.adesig(ade_tx),
	.ade_num(ade_num),
	.axdout(ax_dout),
	.ax_send_full(ax_send_full),
	.ax_send_empty(ax_send_empty),
	.ax_send_rd_en(ax_send_rd_en),

	/*** Ethernet PHY GMII ****/
	.tx_clk(gmii_tx_clk),
	.tx_en(TXEN),
	.txd(TXD)
);
/*
reg [10:0] tc_hsblnk;
reg [10:0] tc_hssync;
reg [10:0] tc_hesync;
reg [10:0] tc_heblnk;
reg [10:0] tc_vsblnk;
reg [10:0] tc_vssync;
reg [10:0] tc_vesync;
reg [10:0] tc_veblnk;


parameter HPIXELS_HDTV720P = 11'd1280; //Horizontal Live Pixels
parameter VLINES_HDTV720P  = 11'd720;  //Vertical Live ines
parameter HSYNCPW_HDTV720P = 11'd40;  //HSYNC Pulse Width
parameter VSYNCPW_HDTV720P = 11'd5;    //VSYNC Pulse Width
parameter HFNPRCH_HDTV720P = 11'd110; //Horizontal Front Portch hotoha72
parameter VFNPRCH_HDTV720P = 11'd5;    //Vertical Front Portch
parameter HBKPRCH_HDTV720P = 11'd220;  //Horizontal Front Portch
parameter VBKPRCH_HDTV720P = 11'd20;   //Vertical Front Portch


always @(*)begin
 tc_hsblnk = HPIXELS_HDTV720P - 11'd1;
 tc_hssync = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P;
 tc_hesync = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P;
 tc_heblnk = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P + HBKPRCH_HDTV720P;
 tc_vsblnk =  VLINES_HDTV720P - 11'd1;
 tc_vssync =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P;
 tc_vesync =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P;
 tc_veblnk =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P + VBKPRCH_HDTV720P;
end
wire [10:0] bgnd_hcount;
wire [10:0] bgnd_vcount;

wire VGA_HSYNC_INT, VGA_VSYNC_INT;
wire          bgnd_hsync;
wire          bgnd_hblnk;
wire          bgnd_vsync;
wire          bgnd_vblnk;
*/
reg hs,vs;
reg hs_q,vs_q;
reg [10:0]hc,vc;
always @ (posedge fifo_clk)begin
  if(sys_rst)begin
		hs <= 1'b0;
		vs <= 1'b0;
		hc <= 11'b0;
		vc <= 11'b0;
	end else begin
	  hs_q <= hs;
	  vs_q <= vs;
	  // hcounter , vcounter Generate 
		if(hc == 11'd1649)begin
			hc <= 11'd0;
			if(vc == 11'd749)
				vc <= 11'd0;
			else
				vc <= vc + 11'd1;
		end else
		  hc <= hc + 11'd1;

		//hsync, vsync Generate
		if((hc >= 110) && (hc <= 149))
			hs <= 1'b1;
		else 
			hs <= 1'b0;

		if((vc >= 0) && (vc <= 4))
			vs <= 1'b1;
		else 
			vs <= 1'b0;

	end
end


wire vde = (hcnt > 220 && hcnt < 1500) && (vcnt > 20 && vcnt < 740); 

//ADE Generator
//   *** ADE has 804 or 805 period in a Frame.
//   *** entire 750 lines ---> at least, one ADE per line
//   *** 2 ade periods every 15 lines.
// 
reg [3:0]c15;
always@(posedge fifo_clk)begin
  if(sys_rst)begin
		ade <= 1'b0;
		c15 <= 4'd0;
	end else begin
	  if(vc == 0)

		else if(c15 == 4'd14)begin
			c15 <= 4'd0;
			if( ((hcnt >= 1558) && (hcnt <= 1590)) || ((hcnt >= 1592) && (hcnt <= 1624)) )
				ade <= 1'b1;
			else
				ade <= 1'b0;
		end else begin
		  c15 <= c15 + 4'd1;
			if( (hcnt >= 1558) && (hcnt <= 1590) )
				ade <= 1'b1;
			else
				ade <= 1'b0;
		end
	end
end

tmds_timing timing_inst (
  .rx0_pclk(fifo_clk),
  .rstbtn_n(sys_rst), 
  .rx0_hsync(hs),
  .rx0_vsync(vs),
  .video_en(video_en),
  .index(),
  .video_hcnt(),
  .video_vcnt(),
  .vcounter(vcnt),
  .hcounter(hcnt)
);
/*
timing_gen timing_inst (
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
	.restart(sys_rst),
	.clk74m(pclk),
	.clk125m(RXCLK),
	.fifo_wr_en(recv_fifo_wr_en),
	.y_din(y_din)
);*/
wire active;
//assign active = !bgnd_hblnk && !bgnd_vblnk;
assign rd_en = active;

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

reg [47:0] vrom [0:2024];
reg [11:0] arom [0:2024];
reg [11:0]vcounter = 12'd0;
reg [11:0]acounter = 12'd0;

always@(posedge sys_clk)begin
  if(rd_en)begin
		tx_data 	<= vrom[vcounter];
		vcounter	<= vcounter + 12'd1;
	end
	if(ax_send_rd_en)begin
		ax_dout  <= arom[acounter];
		acounter <= acounter + 12'd1;
  end
end


initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_gmiisend);
	$readmemh("vrequest.mem",vrom);
	$readmemh("arequest.mem",arom);
	sys_rst = 1'b1;
	vcounter = 0;
	acounter = 0;
	
	waitclock;
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	
	#1000000;
	$finish;
end

endmodule
