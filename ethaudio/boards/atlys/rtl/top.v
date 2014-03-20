`timescale 1 ps / 1 ps

`define FRAME_CHECK

module top (
	// SYSTEM
	input  wire       RSTBTN,    //The BTN NORTH
	input  wire       SYS_CLK,   //100 MHz osicallator
	// TMDS OUTPUT
	input  wire [3:0] RX0_TMDS,
	input  wire [3:0] RX0_TMDSB,
	// TMDS INPUT
	output wire [3:0] TMDS,
	output wire [3:0] TMDSB,
	// Ethernet PHY
	output wire       RESET,
	output wire       GTXCLK,
	output wire       TXEN,
	output wire       TXER,
	output wire [7:0] TXD,
	input  wire       RXCLK,
	input  wire       RXDV,
	input  wire [7:0] RXD,

	input  wire [3:0] SW,
	input  wire [3:0] DEBUG_SW,

	output reg  [7:0] LED,
	output wire [5:0] JA
);

//******************************************************************//
// Create global clock and synchronous system reset.                //
//******************************************************************//
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

//`ifdef SIMULATION
//  assign pwrup = 1'b0;
//`else
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
//`endif


//////////////////////////////////////
//
//  Generate Clock 125MHz for GMII
//
/////////////////////////////////////

wire clk_125M, clk_125M_90;
assign GTXCLK = clk_125M;

clk_wiz_v3_6 clk125_gen(// Clock in ports
	.CLK_IN1(sysclk),
	// Clock out ports
	.CLK_OUT1(clk_125M),
	.CLK_OUT2(),

	// Status and control signals
	.RESET(RSTBTN),
	.LOCKED()
);

//-----------------------------------------------------------
//  PHY RESET
//-----------------------------------------------------------
reg [20:0] coldsys_rst = 21'd0;
wire coldsys_rst10ms = (coldsys_rst == 21'h100000);
always @(posedge sysclk) coldsys_rst <= !coldsys_rst10ms ? coldsys_rst + 21'h1 : 21'h100000;
assign RESET = coldsys_rst10ms;
assign TXER = 1'b0;

//-----------------------------------------------------------
// Receive process
//
//-----------------------------------------------------------

wire [28:0] fifo_din;
wire [10:0] y_din = fifo_din[26:16];
wire [ 1:0] x_din = fifo_din[28:27];
wire [28:0] dout;

wire datavalid;
wire recv_fifo_wr_en;

wire ax_recv_wr_en;
reg ax_recv_rd_en;
wire ax_recv_full, ax_recv_empty;
wire [23:0] axdin;

gmii2fifo24 gmii2fifo24(
	.clk125(RXCLK),
	.sys_rst(RSTBTN),
	.id(DEBUG_SW[0]),
	.rxd(RXD),
	.rx_dv(RXDV),
	.datain(fifo_din),
	.recv_en(recv_fifo_wr_en),
	.packet_en(),
	.aux_data_in(axdin),
	.aux_wr_en(ax_recv_wr_en)
);


//------------------------------------------------------------
// FIFO
//------------------------------------------------------------
wire recv_full, recv_empty, fifo_read;
fifo29_32768 asfifo_recv (
	.rst(reset),
	.wr_clk(RXCLK), // GMII RX clock 125MHz
	.rd_clk(pclk),  // TMDS clock 74.25MHz 
	.din(fifo_din), // data input
	.wr_en(recv_fifo_wr_en),
	.rd_en(fifo_read),
	.dout(dout),    // data output
	.full(recv_full),
	.empty(recv_empty)
);

wire [23:0] axdout;
reg init;
wire ax_rx_rd_en = init & ax_recv_rd_en;
afifo24_recv afifo24_recv(
  .rst(reset| RSTBTN),
	.wr_clk(RXCLK),
	.rd_clk(pclk),
	.din(axdin),
	.wr_en(ax_recv_wr_en),
	.rd_en(ax_rx_rd_en),
	.dout(axdout),
	.full(ax_recv_full),
	.empty(ax_recv_empty)
);
//////////////////////////////////////
/// Switching screen formats
//////////////////////////////////////
wire busy;
wire  [3:0] sws_sync; //synchronous output

synchro #(.INITIALIZE("LOGIC0"))
synchro_sws_3 (.async(SW[3]),.sync(sws_sync[3]),.clk(clk50m_bufg));

synchro #(.INITIALIZE("LOGIC0"))
synchro_sws_2 (.async(SW[2]),.sync(sws_sync[2]),.clk(clk50m_bufg));

synchro #(.INITIALIZE("LOGIC0"))
synchro_sws_1 (.async(SW[1]),.sync(sws_sync[1]),.clk(clk50m_bufg));

synchro #(.INITIALIZE("LOGIC0"))
synchro_sws_0 (.async(SW[0]),.sync(sws_sync[0]),.clk(clk50m_bufg));

reg [3:0] sws_sync_q;
always @ (posedge clk50m_bufg) sws_sync_q <= sws_sync;

wire sw0_rdy, sw1_rdy, sw2_rdy, sw3_rdy;

debnce debsw0 (
	.sync(sws_sync_q[0]),
	.debnced(sw0_rdy),
	.clk(clk50m_bufg)
);

debnce debsw1 (
	.sync(sws_sync_q[1]),
	.debnced(sw1_rdy),
	.clk(clk50m_bufg)
);

debnce debsw2 (
	.sync(sws_sync_q[2]),
	.debnced(sw2_rdy),
	.clk(clk50m_bufg)
);

debnce debsw3 (
	.sync(sws_sync_q[3]),
	.debnced(sw3_rdy),
	.clk(clk50m_bufg)
);

reg switch = 1'b0;
always @ (posedge clk50m_bufg) begin
	switch <= pwrup | sw0_rdy | sw1_rdy | sw2_rdy | sw3_rdy;
end

wire gopclk;
SRL16E SRL16E_0 (
	.Q(gopclk),
	.A0(1'b1),
	.A1(1'b1),
	.A2(1'b1),
	.A3(1'b1),
	.CE(1'b1),
	.CLK(clk50m_bufg),
	.D(switch)
);

// The following defparam declaration 
defparam SRL16E_0.INIT = 16'h0;

parameter SW_VGA       = 4'b0000;
parameter SW_SVGA      = 4'b0001;
parameter SW_XGA       = 4'b0011;
parameter SW_HDTV720P  = 4'b0010;
parameter SW_SXGA      = 4'b1000;
parameter SW_CAMERA    = 4'b1001;

reg [7:0] pclk_M, pclk_D;
always @ (posedge clk50m_bufg) begin
	if(switch) begin
		case(sws_sync_q)
			SW_VGA: begin //25 MHz pixel clock
				pclk_M <= 8'd2 - 8'd1;
				pclk_D <= 8'd4 - 8'd1;
			end

			SW_SVGA: begin //40 MHz pixel clock
				pclk_M <= 8'd4 - 8'd1;
				pclk_D <= 8'd5 - 8'd1;
			end

			SW_XGA: begin //65 MHz pixel clock
				pclk_M <= 8'd13 - 8'd1;
				pclk_D <= 8'd10 - 8'd1;
			end

			SW_SXGA: begin //108 MHz pixel clock
				pclk_M <= 8'd54 - 8'd1;
				pclk_D <= 8'd25 - 8'd1;
			end
		  
			SW_CAMERA: begin //108 MHz pixel clock
				pclk_M <= 8'd135 - 8'd1;
				pclk_D <= 8'd91 - 8'd1;
			end
		  
			default: begin //74.25 MHz pixel clock
				pclk_M <= 8'd248 - 8'd1;
				pclk_D <= 8'd167 - 8'd1;
			end
		endcase
	end
end

//
// DCM_CLKGEN SPI controller
//
wire progdone, progen, progdata;
dcmspi dcmspi_0 (
	.RST(switch),          //Synchronous Reset
	.PROGCLK(clk50m_bufg), //SPI clock
	.PROGDONE(progdone),   //DCM is ready to take next command
	.DFSLCKD(pclk_lckd),
	.M(pclk_M),            //DCM M value
	.D(pclk_D),            //DCM D value
	.GO(gopclk),           //Go programme the M and D value into DCM(1 cycle pulse)
	.BUSY(busy),
	.PROGEN(progen),       //SlaveSelect,
	.PROGDATA(progdata)    //CommandData
);

//
// DCM_CLKGEN to generate a pixel clock with a variable frequency
//

DCM_CLKGEN #(
	.CLKFX_DIVIDE (21),
	.CLKFX_MULTIPLY (31),
	.CLKIN_PERIOD(20.000)
)
PCLK_GEN_INST (
	.CLKFX(clkfx),
	.CLKFX180(),
	.CLKFXDV(),
	.LOCKED(pclk_lckd),
	.PROGDONE(progdone),
	.STATUS(),
	.CLKIN(clk50m),
	.FREEZEDCM(1'b0),
	.PROGCLK(clk50m_bufg),
	.PROGDATA(progdata),
	.PROGEN(progen),
	.RST(1'b0)
);


wire pllclk0, pllclk1, pllclk2;
wire pclkx2, pclkx10, pll_lckd;
wire clkfbout;

//
// Pixel Rate clock buffer
//
BUFG pclkbufg (.I(pllclk1), .O(pclk));

//////////////////////////////////////////////////////////////////
// 2x pclk is going to be used to drive OSERDES2
// on the GCLK side
//////////////////////////////////////////////////////////////////
BUFG pclkx2bufg (.I(pllclk2), .O(pclkx2));

//////////////////////////////////////////////////////////////////
// 10x pclk is used to drive IOCLK network so a bit rate reference
// can be used by OSERDES2
//////////////////////////////////////////////////////////////////
PLL_BASE # (
	.CLKIN_PERIOD(13),
	.CLKFBOUT_MULT(10), //set VCO to 10x of CLKIN
	.CLKOUT0_DIVIDE(1),
	.CLKOUT1_DIVIDE(10),
	.CLKOUT2_DIVIDE(5),
	.COMPENSATION("INTERNAL")
) PLL_OSERDES (
	.CLKFBOUT(clkfbout),
	.CLKOUT0(pllclk0),
	.CLKOUT1(pllclk1),
	.CLKOUT2(pllclk2),
	.CLKOUT3(),
	.CLKOUT4(),
	.CLKOUT5(),
	.LOCKED(pll_lckd),
	.CLKFBIN(clkfbout),
	.CLKIN(clkfx),
	.RST(~pclk_lckd)
);

wire serdesstrobe;
wire bufpll_lock;
BUFPLL #(.DIVIDE(5)) ioclk_buf (.PLLIN(pllclk0), .GCLK(pclkx2), .LOCKED(pll_lckd),
	.IOCLK(pclkx10), .SERDESSTROBE(serdesstrobe), .LOCK(bufpll_lock));

synchro #(.INITIALIZE("LOGIC1"))
synchro_reset (.async(!pll_lckd),.sync(reset),.clk(pclk));

///////////////////////////////////////////////////////////////////////////
// Video Timing Parameters
///////////////////////////////////////////////////////////////////////////
//1280x1024@60HZ
parameter HPIXELS_SXGA = 11'd1280; //Horizontal Live Pixels
parameter VLINES_SXGA  = 11'd1024;  //Vertical Live ines
parameter HSYNCPW_SXGA = 11'd112;  //HSYNC Pulse Width
parameter VSYNCPW_SXGA = 11'd3;    //VSYNC Pulse Width
parameter HFNPRCH_SXGA = 11'd48;   //Horizontal Front Portch
parameter VFNPRCH_SXGA = 11'd1;    //Vertical Front Portch
parameter HBKPRCH_SXGA = 11'd248;  //Horizontal Front Portch
parameter VBKPRCH_SXGA = 11'd38;   //Vertical Front Portch

//1280x720@60HZ

parameter HPIXELS_HDTV720P = 11'd1280; //Horizontal Live Pixels
parameter VLINES_HDTV720P  = 11'd720;  //Vertical Live ines
parameter HSYNCPW_HDTV720P = 11'd40;  //HSYNC Pulse Width
parameter VSYNCPW_HDTV720P = 11'd5;    //VSYNC Pulse Width
parameter HFNPRCH_HDTV720P = 11'd110; //Horizontal Front Portch hotoha72
parameter VFNPRCH_HDTV720P = 11'd5;    //Vertical Front Portch
parameter HBKPRCH_HDTV720P = 11'd220;  //Horizontal Front Portch
parameter VBKPRCH_HDTV720P = 11'd20;   //Vertical Front Portch


//1024x768@60HZ
parameter HPIXELS_XGA = 11'd1024; //Horizontal Live Pixels
parameter VLINES_XGA  = 11'd768;  //Vertical Live ines
parameter HSYNCPW_XGA = 11'd136;  //HSYNC Pulse Width
parameter VSYNCPW_XGA = 11'd6;    //VSYNC Pulse Width
parameter HFNPRCH_XGA = 11'd24;   //Horizontal Front Portch
parameter VFNPRCH_XGA = 11'd3;    //Vertical Front Portch
parameter HBKPRCH_XGA = 11'd160;  //Horizontal Front Portch
parameter VBKPRCH_XGA = 11'd29;   //Vertical Front Portch

//CAMERA 
parameter HPIXELS_CAMERA = 11'd1280; //Horizontal Live Pixels
parameter VLINES_CAMERA  = 11'd720;  //Vertical Live ines
parameter HSYNCPW_CAMERA = 11'd39;  //HSYNC Pulse Width
parameter VSYNCPW_CAMERA = 11'd4;    //VSYNC Pulse Width
parameter HFNPRCH_CAMERA = 11'd110;   //Horizontal Front Portch hotoha72
parameter VFNPRCH_CAMERA = 11'd4;    //Vertical Front Portch
parameter HBKPRCH_CAMERA = 11'd220;  //Horizontal Front Portch
parameter VBKPRCH_CAMERA = 11'd22;   // default size is 25//Vertical Front Portch 

//800x600@60HZ
parameter HPIXELS_SVGA = 11'd800; //Horizontal Live Pixels
parameter VLINES_SVGA  = 11'd600; //Vertical Live ines
parameter HSYNCPW_SVGA = 11'd128; //HSYNC Pulse Width
parameter VSYNCPW_SVGA = 11'd4;   //VSYNC Pulse Width
parameter HFNPRCH_SVGA = 11'd40;  //Horizontal Front Portch
parameter VFNPRCH_SVGA = 11'd1;   //Vertical Front Portch
parameter HBKPRCH_SVGA = 11'd88;  //Horizontal Front Portch
parameter VBKPRCH_SVGA = 11'd23;  //Vertical Front Portch

//640x480@60HZ
parameter HPIXELS_VGA = 11'd640; //Horizontal Live Pixels
parameter VLINES_VGA  = 11'd480; //Vertical Live ines
parameter HSYNCPW_VGA = 11'd96;  //HSYNC Pulse Width
parameter VSYNCPW_VGA = 11'd2;   //VSYNC Pulse Width
parameter HFNPRCH_VGA = 11'd16;  //Horizontal Front Portch
parameter VFNPRCH_VGA = 11'd11;  //Vertical Front Portch
parameter HBKPRCH_VGA = 11'd48;  //Horizontal Front Portch
parameter VBKPRCH_VGA = 11'd31;  //Vertical Front Portch

reg [10:0] tc_hsblnk;
reg [10:0] tc_hssync;
reg [10:0] tc_hesync;
reg [10:0] tc_heblnk;
reg [10:0] tc_vsblnk;
reg [10:0] tc_vssync;
reg [10:0] tc_vesync;
reg [10:0] tc_veblnk;

wire  [3:0] sws_clk;      //clk synchronous output

synchro #(.INITIALIZE("LOGIC0"))
clk_sws_3 (.async(SW[3]),.sync(sws_clk[3]),.clk(pclk));

synchro #(.INITIALIZE("LOGIC0"))
clk_sws_2 (.async(SW[2]),.sync(sws_clk[2]),.clk(pclk));

synchro #(.INITIALIZE("LOGIC0"))
clk_sws_1 (.async(SW[1]),.sync(sws_clk[1]),.clk(pclk));

synchro #(.INITIALIZE("LOGIC0"))
clk_sws_0 (.async(SW[0]),.sync(sws_clk[0]),.clk(pclk));

reg  [3:0] sws_clk_sync; //clk synchronous output
always @(posedge pclk) begin
	sws_clk_sync <= sws_clk;
end

reg hvsync_polarity; //1-Negative, 0-Positive
always @(*) begin
	case (sws_clk_sync)
		SW_VGA: begin
			hvsync_polarity = 1'b1;

			tc_hsblnk = HPIXELS_VGA - 11'd1;
			tc_hssync = HPIXELS_VGA - 11'd1 + HFNPRCH_VGA;
			tc_hesync = HPIXELS_VGA - 11'd1 + HFNPRCH_VGA + HSYNCPW_VGA;
			tc_heblnk = HPIXELS_VGA - 11'd1 + HFNPRCH_VGA + HSYNCPW_VGA + HBKPRCH_VGA;
			tc_vsblnk =  VLINES_VGA - 11'd1;
			tc_vssync =  VLINES_VGA - 11'd1 + VFNPRCH_VGA;
			tc_vesync =  VLINES_VGA - 11'd1 + VFNPRCH_VGA + VSYNCPW_VGA;
			tc_veblnk =  VLINES_VGA - 11'd1 + VFNPRCH_VGA + VSYNCPW_VGA + VBKPRCH_VGA;
		end

		SW_SVGA: begin
			hvsync_polarity = 1'b0;

			tc_hsblnk = HPIXELS_SVGA - 11'd1;
			tc_hssync = HPIXELS_SVGA - 11'd1 + HFNPRCH_SVGA;
			tc_hesync = HPIXELS_SVGA - 11'd1 + HFNPRCH_SVGA + HSYNCPW_SVGA;
			tc_heblnk = HPIXELS_SVGA - 11'd1 + HFNPRCH_SVGA + HSYNCPW_SVGA + HBKPRCH_SVGA;
			tc_vsblnk =  VLINES_SVGA - 11'd1;
			tc_vssync =  VLINES_SVGA - 11'd1 + VFNPRCH_SVGA;
			tc_vesync =  VLINES_SVGA - 11'd1 + VFNPRCH_SVGA + VSYNCPW_SVGA;
			tc_veblnk =  VLINES_SVGA - 11'd1 + VFNPRCH_SVGA + VSYNCPW_SVGA + VBKPRCH_SVGA;
		end

		SW_XGA: begin
			hvsync_polarity = 1'b1;

			tc_hsblnk = HPIXELS_XGA - 11'd1;
			tc_hssync = HPIXELS_XGA - 11'd1 + HFNPRCH_XGA;
			tc_hesync = HPIXELS_XGA - 11'd1 + HFNPRCH_XGA + HSYNCPW_XGA;
			tc_heblnk = HPIXELS_XGA - 11'd1 + HFNPRCH_XGA + HSYNCPW_XGA + HBKPRCH_XGA;
			tc_vsblnk =  VLINES_XGA - 11'd1;
			tc_vssync =  VLINES_XGA - 11'd1 + VFNPRCH_XGA;
			tc_vesync =  VLINES_XGA - 11'd1 + VFNPRCH_XGA + VSYNCPW_XGA;
			tc_veblnk =  VLINES_XGA - 11'd1 + VFNPRCH_XGA + VSYNCPW_XGA + VBKPRCH_XGA;
		end

		SW_SXGA: begin
			hvsync_polarity = 1'b0; // positive polarity

			tc_hsblnk = HPIXELS_SXGA - 11'd1;
			tc_hssync = HPIXELS_SXGA - 11'd1 + HFNPRCH_SXGA;
			tc_hesync = HPIXELS_SXGA - 11'd1 + HFNPRCH_SXGA + HSYNCPW_SXGA;
			tc_heblnk = HPIXELS_SXGA - 11'd1 + HFNPRCH_SXGA + HSYNCPW_SXGA + HBKPRCH_SXGA;
			tc_vsblnk =  VLINES_SXGA - 11'd1;
			tc_vssync =  VLINES_SXGA - 11'd1 + VFNPRCH_SXGA;
			tc_vesync =  VLINES_SXGA - 11'd1 + VFNPRCH_SXGA + VSYNCPW_SXGA;
			tc_veblnk =  VLINES_SXGA - 11'd1 + VFNPRCH_SXGA + VSYNCPW_SXGA + VBKPRCH_SXGA;
		end
		
		SW_CAMERA: begin
			hvsync_polarity = 1'b0; // positive polarity

			tc_hsblnk = HPIXELS_CAMERA - 11'd1;
			tc_hssync = HPIXELS_CAMERA - 11'd1 + HFNPRCH_CAMERA;
			tc_hesync = HPIXELS_CAMERA - 11'd1 + HFNPRCH_CAMERA + HSYNCPW_CAMERA;
			tc_heblnk = HPIXELS_CAMERA - 11'd1 + HFNPRCH_CAMERA + HSYNCPW_CAMERA + HBKPRCH_CAMERA;
			tc_vsblnk =  VLINES_CAMERA - 11'd1;
			tc_vssync =  VLINES_CAMERA - 11'd1 + VFNPRCH_CAMERA;
			tc_vesync =  VLINES_CAMERA - 11'd1 + VFNPRCH_CAMERA + VSYNCPW_CAMERA;
			tc_veblnk =  VLINES_CAMERA - 11'd1 + VFNPRCH_CAMERA + VSYNCPW_CAMERA + VBKPRCH_CAMERA;
		end

		default: begin //SW_HDTV720P:
			hvsync_polarity = 1'b0;

			tc_hsblnk = HPIXELS_HDTV720P - 11'd1;
			tc_hssync = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P;
			tc_hesync = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P;
			tc_heblnk = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P + HBKPRCH_HDTV720P;
			tc_vsblnk =  VLINES_HDTV720P - 11'd1;
			tc_vssync =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P;
			tc_vesync =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P;
			tc_veblnk =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P + VBKPRCH_HDTV720P;
		end
	endcase
end

wire [10:0] bgnd_hcount;
wire [10:0] bgnd_vcount;

`ifdef ORIGINAL
`else
wire VGA_HSYNC_INT, VGA_VSYNC_INT;
wire          bgnd_hsync;
wire          bgnd_hblnk;
wire          bgnd_vsync;
wire          bgnd_vblnk;

wire restart = reset;

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
	.restart(restart),
	.clk74m(pclk),
	.clk125m(RXCLK),
	.fifo_wr_en(recv_fifo_wr_en),
	.y_din(y_din)
);

/////////////////////////////////////////
// V/H SYNC and DE generator
/////////////////////////////////////////

wire active;
reg active_q;
reg vsync, hsync;
reg VGA_HSYNC, VGA_VSYNC;
reg vde;

assign active = !bgnd_hblnk && !bgnd_vblnk;

always @ (posedge pclk) begin
	hsync <= VGA_HSYNC_INT ^ hvsync_polarity ;
	vsync <= VGA_VSYNC_INT ^ hvsync_polarity ;
	VGA_HSYNC <= hsync;
	VGA_VSYNC <= vsync;

	active_q <= active;
	vde <= active_q;
end
`endif
///////////////////////////////////
// Video pattern generator:
//   SMPTE HD Color Bar
///////////////////////////////////
wire [7:0] red_data, green_data, blue_data;
wire [11:0]hcnt = {1'd0,bgnd_hcount};
wire [11:0]vcnt = {1'd0,bgnd_vcount};

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

assign JA[0] = RXDV;
assign JA[1] = VGA_HSYNC;
assign JA[2] = VGA_VSYNC;
assign JA[3] = ax_recv_rd_en;
assign JA[4] = ax_send_rd_en;
assign JA[5] = fifo_read;
////////////////////////////////////////////////////////////////
// DVI Encoder
////////////////////////////////////////////////////////////////
wire [4:0] tmds_data0, tmds_data1, tmds_data2;
wire serdes_rst = RSTBTN | ~bufpll_lock;

/*reg [4:0] adecnt;
reg [11:0]aclkc;
reg ade;
reg vde_h,ade_q;
reg init, initq,initqq;
*/
//assign ax_recv_rd_en = ({init,initq} == 2'b10) || ade;
//assign ax_recv_rd_en = (bgnd_vblnk) ? : (hcnt >= 1559 & hcnt <= 1590) ? 1'b1 : 1'b0;

//
// ax_recv_rd_en Generator
//

always@(posedge pclk)begin
	if(RSTBTN)begin
		init <= 1'b0;
		ax_recv_rd_en <= 1'b0;
	end else begin
      if(fifo_read) begin
		    init <= 1'b1;
	    end
		if(bgnd_vblnk)begin
			if(hcnt >= 1559 & hcnt <= 1590)
				ax_recv_rd_en <= 1'b1;
			else 
				ax_recv_rd_en <= 1'b0;
		end else begin
			if(vcnt == 725)begin
				if(hcnt > 8 & hcnt <= 200)
					ax_recv_rd_en <= 1'b1;
				else
					ax_recv_rd_en <= 1'b0;
			end else begin
				if(hcnt >= 1559 & hcnt <= 1590)
					ax_recv_rd_en <= 1'b1;
				else 
					ax_recv_rd_en <= 1'b0;
			end
		end
	end
end

/*
always@(posedge pclk)begin
    if(RSTBTN)begin
		ade      <=  1'b0;
		adecnt   <=  6'd0;
		vde_h    <=  1'b0;
		aclkc    <= 24'd0;
		ade_q    <=  1'b0;
		init     <=  1'b0;
		initq    <=  1'b0;
		initqq   <=  1'b0;
	end else begin
	    vde_h  <= vde;
	    ade_q  <= ade;
	    initq  <= init;
		initqq <= initq; 
        //first read signal
        if(fifo_read) begin
		    init <= 1'b1;
	    end
		if({initq,initqq}==2'b10 || {ade,ade_q}==2'b01) begin
			aclkc <= axdout[23:12]; 
		end
		
	    if(init & ~vde  & hcnt == aclkc) begin
		    ade <= 1'b1;
	    end
		// Aux Data Enable period 
	    if(ade)begin
			case(adecnt)
				//6'd0:  
				6'd31: adecnt <= 6'd0;
				default: adecnt <= adecnt + 6'd1;
			endcase
		    if(adecnt == 6'd31)begin
			    ade    <= 1'b0;
		        adecnt <= 6'd0;
		    end else begin
			    adecnt <= adecnt + 6'd1;
		    end
	    end
    end
end
*/
//assign out_aux0 = {axdout[ 3:2],VGA_VSYNC, VGA_HSYNC};
assign out_aux0 = axdout[ 3:0];
assign out_aux1 = axdout[ 7:4];
assign out_aux2 = axdout[11:8];

dvi_encoder_top dvi_tx0 (
    .pclk        (pclk),
    .pclkx2      (pclkx2),
    .pclkx10     (pclkx10),
    .serdesstrobe(serdesstrobe),
    .rstin       (reset),
	  .serdes_rst  (serdes_rst),
    .blue_din    (blue_data),
    .green_din   (green_data),
    .red_din     (red_data),
	  .aux0_din	   (out_aux0),
	  .aux1_din	   (out_aux1),
	  .aux2_din	   (out_aux2),
    .hsync       (VGA_HSYNC),
    .vsync       (VGA_VSYNC),
    .vde         (vde),
    .ade         (ax_rx_rd_en),
    .TMDS        (TMDS),
    .TMDSB       (TMDSB)
);

//-----------------------------------------------------------
//  FIFO(48bit) to GMII
//		Depth --> 4096
//-----------------------------------------------------------
wire        send_full;
wire        send_empty;
wire [47:0] tx_data;
wire        rd_en;
wire [47:0] din_fifo = {in_vcnt/*in_hcnt*/,index, rx0_red, rx0_green, rx0_blue};
wire        rx0_pclk;           
wire        rx0_hsync;          // hsync data
wire        rx0_vsync;          // vsync data
wire        send_fifo_wr_en = video_en & (in_hcnt <= 12'd1200); /* & in_vcnt < 12'd720) & */

fifo48_8k asfifo_send (
	.rst(RSTBTN | rx0_vsync),
	.wr_clk(rx0_pclk),  // TMDS clock 74.25MHz 
	.rd_clk(clk_125M),  // GMII TX clock 125MHz
	.din(din_fifo),     // data input 48bit
	.wr_en(send_fifo_wr_en),
	.rd_en(rd_en),
	.dout(tx_data),    // data output 48bit 
	.full(send_full),
	.empty(send_empty)
);

// Generating a Number of audio enable period
reg [3:0] ade_c;
reg [3:0] ade_num;
reg [4:0] cnt_32;
reg       vde_b;

always @ (posedge rx0_pclk)begin
  vde_b <= rx0_vde;
  if(rx0_reset || video_hcnt == 11'd1)begin
	  ade_c  <= 4'd0;
	  cnt_32 <= 5'd0; 
	  ade_num <= ade_c;
	end else begin
	  if(rx0_ade)begin
		  if(cnt_32 == 5'd31)begin
			cnt_32 <= 5'd0;
			ade_c  <= ade_c + 4'd1;
		  end else begin
		    cnt_32 <= cnt_32 + 5'd1;
		  end
		end
	end
end

// Generate AUDIO FIFO data
reg [11:0]ade_buf, ade_hcnt;
reg [23:0]ade_out;
reg ade_gg;
reg start;
reg st,stc;
always @ (posedge rx0_pclk)begin
	if(rx0_reset)begin
		ade_buf  <= 12'd0;
	  ade_out  <= 24'd0;
	  ade_hcnt <= 12'd0;
		ade_gg   <=  1'b0;
		start    <=  1'b0;
		st       <=  1'b0;
		stc      <=  1'b0;
	end else begin
		/*
		ade_buf <= {rx0_aux2, rx0_aux1, rx0_aux0};
		ade_gg <= rx0_ade;
		if(cnt_32 == 5'd1)begin
			ade_hcnt <= {1'b0, video_hcnt - 11'd1};
		end
		if(ade_gg)begin
			ade_out <= {ade_hcnt,ade_buf};
		end
		*/
		// To 
		if(video_en)begin
			start <= 1'b1;
			st    <= 1'b1;
			stc   <= 1'b0;
		end
		if(video_hcnt == 11'd220)
			st <= 1'b0;
		if(st == 1'b1)begin
			if(stc == 1'b0)begin
				ade_buf <= {rx0_aux2, rx0_aux1, rx0_aux0};
				ade_gg <= rx0_ade;
				if(cnt_32 == 5'd1)begin
					ade_hcnt <= {1'b0, video_hcnt - 11'd1};
				end
				if(ade_gg)begin
					ade_out <= {ade_hcnt,ade_buf};
				end
			end else begin
				stc <= 1'b1;
			end
		end else begin
			ade_buf <= {rx0_aux2, rx0_aux1, rx0_aux0};
			ade_gg <= rx0_ade;
			if(cnt_32 == 5'd1)begin
				ade_hcnt <= {1'b0, video_hcnt - 11'd1};
			end
			if(ade_gg)begin
				ade_out <= {ade_hcnt,ade_buf};
			end
		end
	end
end

wire        ax_send_full, ax_send_empty;
wire        ax_send_wr_en, ax_send_rd_en;
wire [23:0] ax_din = ade_out;
wire [23:0] ax_dout;

//assign   ax_send_wr_en = (start) ? ade_gg : 1'b0;
assign   ax_send_wr_en = (start) ? ade_gg : 1'b0;
wire     rx0_reset;
wire     rx0_vde;
wire [11:0] in_hcnt = {1'b0, video_hcnt[10:0]};
wire [11:0] in_vcnt = {1'b0, video_vcnt[10:0]};
wire [10:0] video_hcnt;
wire [10:0] video_vcnt;
wire [11:0] index;
wire        video_en;

afifo24_recv auxfifo24_tx(
  .rst(rx0_reset | RSTBTN | ((video_vcnt == 11'd21) && rx0_vde) ),
	.wr_clk(rx0_pclk),
	.rd_clk(clk_125M),
	.din(ax_din),
	.wr_en(ax_send_wr_en),
	.rd_en(ax_send_rd_en),
	.dout(ax_dout),
	.full(ax_send_full),
	.empty(ax_send_empty)
);

//////////////////////////////////////////////////
//
// TMDS Input Port 0 (BANK : )
//
//////////////////////////////////////////////////
wire        rx0_tmdsclk;
wire        rx0_pclkx10, rx0_pllclk0;
wire        rx0_plllckd;
wire        rx0_serdesstrobe;

wire        rx0_psalgnerr;      // channel phase alignment error
wire [3:0]  rx0_aux0;
wire [3:0]  rx0_aux1;
wire [3:0]  rx0_aux2;
wire [7:0]  rx0_red;      // pixel data out
wire [7:0]  rx0_green;    // pixel data out
wire [7:0]  rx0_blue;     // pixel data out
wire        rx0_ade;
wire [29:0] rx0_sdata;
wire        rx0_blue_vld;
wire        rx0_green_vld;
wire        rx0_red_vld;
wire        rx0_blue_rdy;
wire        rx0_green_rdy;
wire        rx0_red_rdy;

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
	.ade         (rx0_ade),
	.vde         (rx0_vde),

	.blue_vld    (rx0_blue_vld),
	.green_vld   (rx0_green_vld),
	.red_vld     (rx0_red_vld),
	.blue_rdy    (rx0_blue_rdy),
	.green_rdy   (rx0_green_rdy),
	.red_rdy     (rx0_red_rdy),

	.psalgnerr   (rx0_psalgnerr),

	.sdout       (rx0_sdata),
	.aux0        (rx0_aux0),
	.aux1        (rx0_aux1),
	.aux2        (rx0_aux2),
	.red         (rx0_red),
	.green       (rx0_green),
	.blue        (rx0_blue)
); 

//-----------------------------------------------------
// TMDS HSYNC VSYNC COUNTER ()
//           (1280x720 progressive 
//                     HSYNC: 45khz   VSYNC : 60Hz)
//-----------------------------------------------------


tmds_timing timing(
	.rx0_pclk(rx0_pclk),
	.rstbtn_n(RSTBTN), 
	.rx0_hsync(rx0_hsync),
	.rx0_vsync(rx0_vsync),
	.video_en(video_en),
	.index(index),
	.video_hcnt(),
	.video_vcnt(),
	.vcounter(video_vnct),
	.hcounter(video_hcnt)
);

//-----------------------------------------------------------
//  GMII TX
//-----------------------------------------------------------

//wire ade_tx = ((video_vcnt < 11'd22) || (video_vcnt > 11'd741)) && ((video_hcnt >= 11'd1) && (video_hcnt < 11'd80));
wire ade_tx = ~video_en && ((video_hcnt >= 11'd1504) && (video_hcnt < 11'd1510));
//wire ade_tx = 1'b0;
wire vperi = ((video_vcnt >= 22) && (video_vcnt <= 741)) ? 1'b1 : 1'b0;
wire fil_wr_en =  video_en & (in_hcnt <= 12'd1200);


gmii_tx gmii_tx(
	.id(DEBUG_SW[0]),
	// FIFO
	.fifo_clk(rx0_pclk),
	.sys_rst(RSTBTN),
	.dout(tx_data), // 48bit
	.empty(send_empty),
	.full(send_full),
	.rd_en(rd_en),
	.wr_en(/*fil_wr_en*/video_en),
	.vperi(vperi),
	.sw(~DEBUG_SW[2]),

	// AX FIFO
	.adesig(ade_tx),
	.ade_num(ade_num),
	.axdout(ax_dout),
	.ax_send_full(ax_send_full),
	.ax_send_empty(ax_send_empty),
	.ax_send_rd_en(ax_send_rd_en),
	
	// Ethernet PHY GMII
	.tx_clk(clk_125M),
	.tx_en(TXEN),
	.txd(TXD)
);

//-----------------------------------------------------------
// DEBUG code : Frame check
//-----------------------------------------------------------
`ifdef FRAME_CHECK
wire [15:0]hf_cnt,vf_cnt,hpwcnt,vpwcnt;
frame_checker frame_checker(
	.clk(rx0_pclk),
	.rst(RSTBTN),
	.hsync(rx0_hsync),
	.vsync(rx0_vsync),
	.hcnt(hf_cnt),
	.vcnt(vf_cnt),
	.hpwcnt(hpwcnt),
	.vpwcnt(vpwcnt)
);
`endif

//////////////////////////////////////
// Status LED 
//////////////////////////////////////
//assign LED = 8'b11111111;
/*
reg pcnt;
always@(posedge rx0_pclk)
	if(RSTBTN)
		pcnt <= 1'd0;
	else
		pcnt <= ~pcnt;

assign JA[3] = pcnt;
assign JA[4] = pcnt;
*/
`ifdef NO
assign LED = LED_out(	.SW(SW), .TXD(TXD), .empty(send_empty), .full(send_full), .rx0_vde(rx0_vde));

function [7:0]LED_out;
	input [3:0]SW;
	input [7:0]TXD;
	input empty;
	input full;
	input rx0_vde;
	begin
		case(SW)
			4'b0000: LED_out ={empty,full, rx0_vde, 5'd0};
			4'b0001: LED_out = TXD;
`ifdef FRAME_CHECK
			4'b0010: LED_out = hf_cnt[7:0];
			4'b0011: LED_out = hf_cnt[15:8];
			4'b0100: LED_out = vf_cnt[7:0];
			4'b0101: LED_out = vf_cnt[15:8];
			4'b0110: LED_out = hpwcnt[7:0];
			4'b0111: LED_out = hpwcnt[15:8];
			4'b1000: LED_out = vpwcnt[7:0];
			4'b1001: LED_out = vpwcnt[15:8];
`endif
		endcase
	end
endfunction
`endif

reg [3:0]anum = 4'd0;
always @(RXCLK) begin
	//sw_dip <= DEBUG_SW;
	if(anum < ade_num)begin
	    anum <= ade_num;
	end
	case(DEBUG_SW[1])
		//1'b0 : LED <= {aclkc[11:8],recv_full,recv_empty,ade,vde};
		//1'b1 : LED <= aclkc[7:0];
		//1'b0 : LED <= {anum,recv_full,recv_empty,ax_rx_rd_en,vde};
		//1'b1 : LED <= {ax_recv_full,ax_recv_empty,ax_recv_wr_en,ax_recv_rd_en,ax_send_full,ax_send_empty,ax_send_wr_en,ax_send_rd_en};
		1'b0 : LED <= {send_full, send_empty, ax_send_full, ax_send_empty,ax_send_rd_en,ax_send_wr_en,ax_rx_rd_en,vde};
		1'b1 : LED <= axdout[7:0];
		//4'b1000 : LED <= {4'b0,recv_full,recv_empty,2'b0};
		//4'b0001 : LED <= error[7:0];
		//4'b0010 : LED <= {5'd0,error[10:8]};
		//4'b0011 : LED <= fifo_din[23:16];
		//4'b0100 : LED <= fifo_din[31:24];
		//4'b0101 : LED <= fifo_din[39:32];
		//4'b0110 : LED <= fifo_din[47:40];
		//4'b0111 : LED <= dout[7:0];
		//4'b1000 : LED <= dout[15:8];
		//4'b1001 : LED <= dout[23:16];
		//4'b1010 : LED <= {4'd0,dout[27:24]};
	endcase
end

endmodule
