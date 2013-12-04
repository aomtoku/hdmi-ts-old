`timescale 1 ps / 1 ps

//`define FRAME_CHECK

module top (
	// SYSTEM
	input wire RSTBTN,    //The BTN NORTH
	//input wire SYS_CLK,   //100 MHz osicallator

	// TMDS OUTPUT
	input wire [3:0] RX0_TMDS,
	input wire [3:0] RX0_TMDSB,

	// TMDS INPUT
	output wire [3:0] TMDS,
	output wire [3:0] TMDSB

);

//******************************************************************//
// Create global clock and synchronous system reset.                //
//******************************************************************//
/*
wire clkfx, pclk;
wire locked;
wire reset;

wire sysclk;
wire clk50m, clk50m_bufg;

wire pwrup;

IBUFG sysclk_buf (.I(SYS_CLK), .O(sysclk));
reg clk_buf;
always @(posedge sysclk) clk_buf <= ~clk_buf;

assign clk50m = clk_buf;

BUFG clk50m_bufgbufg (.I(clk50m), .O(clk50m_bufg));


wire pclk_lckd;

SRL16E #(.INIT(16'h1)) pwrup_0 (
	.Q(pwrup),
	.A0(1'b1),
	.A1(1'b1),
	.A2(1'b1),
	.A3(1'b1),
	.CE(pclk_lckd),
	.CLK(clk50m_bufg),
	.D(1'b0)
);


wire active;
reg active_q;
reg vsync, hsync;
reg VGA_HSYNC, VGA_VSYNC;
reg de;

assign active = !bgnd_hblnk && !bgnd_vblnk;

always @ (posedge pclk) begin
	hsync <= VGA_HSYNC_INT ^ hvsync_polarity ;
	vsync <= VGA_VSYNC_INT ^ hvsync_polarity ;
	VGA_HSYNC <= hsync;
	VGA_VSYNC <= vsync;

	active_q <= active;
	de <= active_q;
end
`endif
*/
///////////////////////////////////
// Video pattern generator:
//   SMPTE HD Color Bar
///////////////////////////////////
/*
datacontroller dataproc(
	.i_clk_74M(pclk),
	.i_rst(reset),
	.i_hcnt(hcnt),
	.i_vcnt(vcnt),
	.i_format(2'b00),
	.fifo_read(fifo_read),
	.data(dout),
	.sw(~DEBUG_SW[3]),
	.o_r(red_data),
	.o_g(green_data),
	.o_b(blue_data)
);
*/

//////////////////////////////////////////////////
//
// TMDS Input Port 0 (BANK : )
//
//////////////////////////////////////////////////
wire rx0_tmdsclk;
wire rx0_pclk,rx0_pclkx2;
wire rx0_pclkx10, rx0_pllclk0;
wire rx0_pllclk1,rx0_pllclk2;
wire rx0_plllckd;
wire rx0_reset;
wire rx0_serdesstrobe;

wire rx0_psalgnerr;      // channel phase alignment error
wire [7:0] rx0_red;      // pixel data out
wire [7:0] rx0_green;    // pixel data out
wire [7:0] rx0_blue;     // pixel data out
wire rx0_de;
wire [29:0] rx0_sdata;
wire rx0_blue_vld;
wire rx0_green_vld;
wire rx0_red_vld;
wire rx0_blue_rdy;
wire rx0_green_rdy;
wire rx0_red_rdy;
wire rx0_hsync,rx0_vsync;
wire [3:0]rx0_ctl;

dvi_decoder dvi_rx0 (
	//These are input ports
	.tmdsclk_p   (RX0_TMDS[3]),
	.tmdsclk_n   (RX0_TMDSB[3]),
	.blue_p      (RX0_TMDS[0]),
	.green_p     (RX0_TMDS[1]),
	.red_p       (RX0_TMDS[2]),
	.blue_n      (RX0_TMDSB[0]),
	.green_n     (RX0_TMDSB[1]),
	.red_n       (RX0_TMDSB[2]),
	.exrst       (RSTBTN),

	//These are output ports
	.reset       (rx0_reset),
	.pclk        (rx0_pclk),
	.pclkx2      (rx0_pclkx2),
	.pclkx10     (rx0_pclkx10),
	.pllclk0     (rx0_pllclk0), // PLL x10 output
	.pllclk1     (rx0_pllclk1), // PLL x1 output
	.pllclk2     (rx0_pllclk2), // PLL x2 output
	.pll_lckd    (rx0_plllckd),
	.tmdsclk     (rx0_tmdsclk),
	.serdesstrobe(rx0_serdesstrobe),
	.hsync       (rx0_hsync),
	.vsync       (rx0_vsync),
	.de          (rx0_de),
	.ctl				 (rx0_ctl),

	.blue_vld    (rx0_blue_vld),
	.green_vld   (rx0_green_vld),
	.red_vld     (rx0_red_vld),
	.blue_rdy    (rx0_blue_rdy),
	.green_rdy   (rx0_green_rdy),
	.red_rdy     (rx0_red_rdy),

	.psalgnerr   (rx0_psalgnerr),

	.sdout       (rx0_sdata),
	.red         (rx0_red),
	.green       (rx0_green),
	.blue        (rx0_blue)
); 

wire de;
tmds_timing(
	.rx0_pclk(rx0_pclk),
  .rstbtn_n(rx0_reset), 
  .rx0_hsync(rx0_hsync),
  .rx0_vsync(rx0_vsync),
  .video_en(de),
  .index(),
  .video_hcnt(),
  .video_vcnt()
);


////////////////////////////////////////////////////////////////
// DVI Encoder
////////////////////////////////////////////////////////////////
wire [4:0] tmds_data0, tmds_data1, tmds_data2;

dvi_encoder enc0 (
	.clkin      (rx0_pclk),
	.clkx2in    (rx0_pclkx2),
	.rstin      (rx0_reset),
	.blue_din   (rx0_blue),
	.green_din  (rx0_green),
	.red_din    (rx0_red),
	.hsync      (rx0_hsync),
	.vsync      (rx0_vsync),
	.de         (de),
	.ctl				(rx0_ctl),
	.tmds_data0 (tmds_data0),
	.tmds_data1 (tmds_data1),
	.tmds_data2 (tmds_data2)
);


wire [2:0] tmdsint;

serdes_n_to_1 #(.SF(5)) oserdes0 (
	.ioclk(rx0_pclkx10),
	.serdesstrobe(rx0_serdesstrobe),
	.reset(rx0_reset),
	.gclk(rx0_pclkx2),
	.datain(tmds_data0),
	.iob_data_out(tmdsint[0])
);

serdes_n_to_1 #(.SF(5)) oserdes1 (
	.ioclk(rx0_pclkx10),
	.serdesstrobe(rx0_serdesstrobe),
	.reset(rx0_reset),
	.gclk(rx0_pclkx2),
	.datain(tmds_data1),
	.iob_data_out(tmdsint[1])
);

serdes_n_to_1 #(.SF(5)) oserdes2 (
	.ioclk(rx0_pclkx10),
	.serdesstrobe(rx0_serdesstrobe),
	.reset(rx0_reset),
	.gclk(rx0_pclkx2),
	.datain(tmds_data2),
	.iob_data_out(tmdsint[2])
);

OBUFDS TMDS0 (.I(tmdsint[0]), .O(TMDS[0]), .OB(TMDSB[0])) ;
OBUFDS TMDS1 (.I(tmdsint[1]), .O(TMDS[1]), .OB(TMDSB[1])) ;
OBUFDS TMDS2 (.I(tmdsint[2]), .O(TMDS[2]), .OB(TMDSB[2])) ;

reg [4:0] tmdsclkint = 5'b00000;
reg toggle = 1'b0;

always @ (posedge rx0_pclkx2 or posedge rx0_reset) begin
	if (rx0_reset)
		toggle <= 1'b0;
	else
		toggle <= ~toggle;
end

always @ (posedge rx0_pclkx2) begin
	if (toggle)
		tmdsclkint <= 5'b11111;
	else
		tmdsclkint <= 5'b00000;
end

wire tmdsclk;

serdes_n_to_1 #(
	.SF           (5))
clkout (
	.iob_data_out (tmdsclk),
	.ioclk        (rx0_pclkx10),
	.serdesstrobe (rx0_serdesstrobe),
	.gclk         (rx0_pclkx2),
	.reset        (rx0_reset),
	.datain       (tmdsclkint)
);

OBUFDS TMDS3 (.I(tmdsclk), .O(TMDS[3]), .OB(TMDSB[3])) ;// clock


//-----------------------------------------------------
// TMDS HSYNC VSYNC COUNTER ()
//           (1280x720 progressive 
//                     HSYNC: 45khz   VSYNC : 60Hz)
//-----------------------------------------------------
/*
wire [11:0]in_hcnt = {1'b0, video_hcnt[10:0]};
wire [11:0]in_vcnt = {1'b0, video_vcnt[10:0]};
wire [10:0]video_hcnt;
wire [10:0]video_vcnt;
wire [11:0]index;
wire video_en;

tmds_timing timing(
		.rx0_pclk(rx0_pclk),
		.rstbtn_n(RSTBTN), 
		.rx0_hsync(rx0_hsync),
		.rx0_vsync(rx0_vsync),
		.video_en(video_en),
		.index(index),
		.video_hcnt(video_hcnt),
		.video_vcnt(video_vcnt)
);
*/
endmodule

