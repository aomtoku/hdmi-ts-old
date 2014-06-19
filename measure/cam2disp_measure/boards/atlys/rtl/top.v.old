//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2009 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor:        Xilinx
// \   \   \/    Version:       1.0.0
//  \   \        Filename:      vtc_demo.v
//  /   /        Date Created:  April 8, 2009
// /___/   /\    Author:        Bob Feng   
// \   \  /  \
//  \___\/\___\
//
// Devices:   Spartan-6 Generation FPGA
// Purpose:   SP601 board demo top level
// Contact:   
// Reference: None
//
// Revision History:
// 
//
//////////////////////////////////////////////////////////////////////////////
//
// LIMITED WARRANTY AND DISCLAIMER. These designs are provided to you "as is".
// Xilinx and its licensors make and you receive no warranties or conditions,
// express, implied, statutory or otherwise, and Xilinx specifically disclaims
// any implied warranties of merchantability, non-infringement, or fitness for
// a particular purpose. Xilinx does not warrant that the functions contained
// in these designs will meet your requirements, or that the operation of
// these designs will be uninterrupted or error free, or that defects in the
// designs will be corrected. Furthermore, Xilinx does not warrant or make any
// representations regarding use or the results of the use of the designs in
// terms of correctness, accuracy, reliability, or otherwise.
//
// LIMITATION OF LIABILITY. In no event will Xilinx or its licensors be liable
// for any loss of data, lost profits, cost or procurement of substitute goods
// or services, or for any special, incidental, consequential, or indirect
// damages arising from the use or operation of the designs or accompanying
// documentation, however caused and on any theory of liability. This
// limitation will apply even if Xilinx has been advised of the possibility
// of such damage. This limitation shall apply not-withstanding the failure
// of the essential purpose of any limited remedies herein.
//
//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2009 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////

`timescale 1 ps / 1 ps

`include "setup.v"

module top (
  input  wire RSTBTN_,

  input  wire SYS_CLK,
	input  wire [1:0] swled,

  input  wire [3:0] SW,
  
  output wire [3:0] TMDS,
  output wire [3:0] TMDSB,
  output reg  [7:0] LED,
	//input  wire       UART_TX,
	//output wire       UART_RX,
	input  wire       JA,
	output wire [1:0] DB,
	input  wire       BTNU
);

  //******************************************************************//
  // Create global clock and synchronous system reset.                //
  //******************************************************************//
  wire          locked;
  wire          reset;

  wire          clk50m, clk50m_bufg;

  wire          pwrup;
	wire          clk100;

  IBUF sysclk_buf (.I(SYS_CLK), .O(sysclk));
	BUFG sysclk_bufg (.I(sysclk), .O(clk100));

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
  always @ (posedge clk50m_bufg)
  begin
    sws_sync_q <= sws_sync;
  end

  wire sw0_rdy, sw1_rdy, sw2_rdy, sw3_rdy;

  debnce debsw0 (
    .sync(sws_sync_q[0]),
    .debnced(sw0_rdy),
    .clk(clk50m_bufg));

  debnce debsw1 (
    .sync(sws_sync_q[1]),
    .debnced(sw1_rdy),
    .clk(clk50m_bufg));

  debnce debsw2 (
    .sync(sws_sync_q[2]),
    .debnced(sw2_rdy),
    .clk(clk50m_bufg));

  debnce debsw3 (
    .sync(sws_sync_q[3]),
    .debnced(sw3_rdy),
    .clk(clk50m_bufg));

  reg switch = 1'b0;
  always @ (posedge clk50m_bufg)
  begin
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
  parameter SW_FLHD      = 4'b1100;

  reg [7:0] pclk_M, pclk_D;
  always @ (posedge clk50m_bufg)
  begin
    if(switch) begin
      case (sws_sync_q)
        SW_VGA: //25 MHz pixel clock
        begin
          pclk_M <= 8'd2 - 8'd1;
          pclk_D <= 8'd4 - 8'd1;
        end

        SW_SVGA: //40 MHz pixel clock
        begin
         pclk_M <= 8'd4 - 8'd1;
         pclk_D <= 8'd5 - 8'd1;
        end

        SW_XGA: //65 MHz pixel clock
        begin
          pclk_M <= 8'd13 - 8'd1;
          pclk_D <= 8'd10 - 8'd1;
        end

        SW_SXGA: //108 MHz pixel clock
        begin
          pclk_M <= 8'd54 - 8'd1;
          pclk_D <= 8'd25 - 8'd1;
        end

        SW_FLHD: //148.5 MHz pixel clock
        begin
          pclk_M <= 8'd199 - 8'd1;
          pclk_D <= 8'd67  - 8'd1;
        end

        default: //74.25 MHz pixel clock
        begin
          pclk_M <= 8'd37 - 8'd1;
          pclk_D <= 8'd25 - 8'd1;
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
  wire          clkfx, pclk;
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

  reg led;
	reg [28:0]ledc;
	always @ (posedge pclk)begin
	  if(~RSTBTN_)begin
			ledc <= 29'd0;
			led  <= 1'd0;
		end else begin
			if(ledc == 29'd148500000)begin
				led <= ~led;
				ledc <= 29'd0;
			end else 
			  ledc <= ledc + 29'd1;
		end
	end
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

  reg [11:0] tc_hsblnk;
  reg [11:0] tc_hssync;
  reg [11:0] tc_hesync;
  reg [11:0] tc_heblnk;
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
  always @ (posedge pclk)
  begin
    sws_clk_sync <= sws_clk;
  end

  reg hvsync_polarity; //1-Negative, 0-Positive
  always @ (*)
  begin
    case (sws_clk_sync)
      SW_VGA:
      begin
        hvsync_polarity = 1'b1;

        tc_hsblnk = HPIXELS_VGA - 12'd1;
        tc_hssync = HPIXELS_VGA - 12'd1 + HFNPRCH_VGA;
        tc_hesync = HPIXELS_VGA - 12'd1 + HFNPRCH_VGA + HSYNCPW_VGA;
        tc_heblnk = HPIXELS_VGA - 12'd1 + HFNPRCH_VGA + HSYNCPW_VGA + HBKPRCH_VGA;
        tc_vsblnk =  VLINES_VGA - 11'd1;
        tc_vssync =  VLINES_VGA - 11'd1 + VFNPRCH_VGA;
        tc_vesync =  VLINES_VGA - 11'd1 + VFNPRCH_VGA + VSYNCPW_VGA;
        tc_veblnk =  VLINES_VGA - 11'd1 + VFNPRCH_VGA + VSYNCPW_VGA + VBKPRCH_VGA;
      end

      SW_SVGA:
      begin
        hvsync_polarity = 1'b0;

        tc_hsblnk = HPIXELS_SVGA - 12'd1;
        tc_hssync = HPIXELS_SVGA - 12'd1 + HFNPRCH_SVGA;
        tc_hesync = HPIXELS_SVGA - 12'd1 + HFNPRCH_SVGA + HSYNCPW_SVGA;
        tc_heblnk = HPIXELS_SVGA - 12'd1 + HFNPRCH_SVGA + HSYNCPW_SVGA + HBKPRCH_SVGA;
        tc_vsblnk =  VLINES_SVGA - 11'd1;
        tc_vssync =  VLINES_SVGA - 11'd1 + VFNPRCH_SVGA;
        tc_vesync =  VLINES_SVGA - 11'd1 + VFNPRCH_SVGA + VSYNCPW_SVGA;
        tc_veblnk =  VLINES_SVGA - 11'd1 + VFNPRCH_SVGA + VSYNCPW_SVGA + VBKPRCH_SVGA;
      end

      SW_XGA:
      begin
        hvsync_polarity = 1'b1;

        tc_hsblnk = HPIXELS_XGA - 12'd1;
        tc_hssync = HPIXELS_XGA - 12'd1 + HFNPRCH_XGA;
        tc_hesync = HPIXELS_XGA - 12'd1 + HFNPRCH_XGA + HSYNCPW_XGA;
        tc_heblnk = HPIXELS_XGA - 12'd1 + HFNPRCH_XGA + HSYNCPW_XGA + HBKPRCH_XGA;
        tc_vsblnk =  VLINES_XGA - 11'd1;
        tc_vssync =  VLINES_XGA - 11'd1 + VFNPRCH_XGA;
        tc_vesync =  VLINES_XGA - 11'd1 + VFNPRCH_XGA + VSYNCPW_XGA;
        tc_veblnk =  VLINES_XGA - 11'd1 + VFNPRCH_XGA + VSYNCPW_XGA + VBKPRCH_XGA;
      end

      SW_SXGA:
      begin
        hvsync_polarity = 1'b0; // positive polarity

        tc_hsblnk = HPIXELS_SXGA - 12'd1;
        tc_hssync = HPIXELS_SXGA - 12'd1 + HFNPRCH_SXGA;
        tc_hesync = HPIXELS_SXGA - 12'd1 + HFNPRCH_SXGA + HSYNCPW_SXGA;
        tc_heblnk = HPIXELS_SXGA - 12'd1 + HFNPRCH_SXGA + HSYNCPW_SXGA + HBKPRCH_SXGA;
        tc_vsblnk =  VLINES_SXGA - 11'd1;
        tc_vssync =  VLINES_SXGA - 11'd1 + VFNPRCH_SXGA;
        tc_vesync =  VLINES_SXGA - 11'd1 + VFNPRCH_SXGA + VSYNCPW_SXGA;
        tc_veblnk =  VLINES_SXGA - 11'd1 + VFNPRCH_SXGA + VSYNCPW_SXGA + VBKPRCH_SXGA;
      end
      
			SW_FLHD:
      begin
        hvsync_polarity = 1'b0; // positive polarity

        tc_hsblnk = HPIXELS_FLHD - 12'd1;
        tc_hssync = HPIXELS_FLHD - 12'd1 + HFNPRCH_FLHD;
        tc_hesync = HPIXELS_FLHD - 12'd1 + HFNPRCH_FLHD + HSYNCPW_FLHD;
        tc_heblnk = HPIXELS_FLHD - 12'd1 + HFNPRCH_FLHD + HSYNCPW_FLHD + HBKPRCH_FLHD;
        tc_vsblnk =  VLINES_FLHD - 11'd1;
        tc_vssync =  VLINES_FLHD - 11'd1 + VFNPRCH_FLHD;
        tc_vesync =  VLINES_FLHD - 11'd1 + VFNPRCH_FLHD + VSYNCPW_FLHD;
        tc_veblnk =  VLINES_FLHD - 11'd1 + VFNPRCH_FLHD + VSYNCPW_FLHD + VBKPRCH_FLHD;
      end

      default: //SW_HDTV720P:
      begin
        hvsync_polarity = 1'b0;

        tc_hsblnk = HPIXELS_HDTV720P - 12'd1;
        tc_hssync = HPIXELS_HDTV720P - 12'd1 + HFNPRCH_HDTV720P;
        tc_hesync = HPIXELS_HDTV720P - 12'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P;
        tc_heblnk = HPIXELS_HDTV720P - 12'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P + HBKPRCH_HDTV720P;
        tc_vsblnk =  VLINES_HDTV720P - 11'd1;
        tc_vssync =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P;
        tc_vesync =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P;
        tc_veblnk =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P + VBKPRCH_HDTV720P;
      end
    endcase
  end

  wire VGA_HSYNC_INT, VGA_VSYNC_INT;
  wire   [11:0] bgnd_hcount;
  wire          bgnd_hsync;
  wire          bgnd_hblnk;
  wire   [10:0] bgnd_vcount;
  wire          bgnd_vsync;
  wire          bgnd_vblnk;

  timing timing_inst (
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
    .restart(reset),
    .clk(pclk));

  /////////////////////////////////////////
  // V/H SYNC and DE generator
  /////////////////////////////////////////
  assign active = !bgnd_hblnk && !bgnd_vblnk;

  reg active_q;
  reg vsync, hsync;
  reg VGA_HSYNC, VGA_VSYNC;
  reg de;

  always @ (posedge pclk)
  begin
    hsync <= VGA_HSYNC_INT ^ hvsync_polarity ;
    vsync <= VGA_VSYNC_INT ^ hvsync_polarity ;
    VGA_HSYNC <= hsync;
    VGA_VSYNC <= vsync;

    active_q <= active;
    de <= active_q;
  end

	assign DB[0] = hsync;
	assign DB[1] = vsync;

  ///////////////////////////////////
  // Video pattern generator:
  //   SMPTE HD Color Bar
  ///////////////////////////////////
  wire [7:0] red_data, green_data, blue_data;
/*
  hdcolorbar clrbar(
    .i_clk_74M(pclk),
    .i_rst(reset),
    .i_hcnt(bgnd_hcount),
    .i_vcnt(bgnd_vcount),
    .baronly(1'b0),
    .i_format(2'b00),
    .o_r(red_data),
    .o_g(green_data),
    .o_b(blue_data)
  );
  */
	////////////////////////////////////////////////////////////////
  // DVI Encoder
  ////////////////////////////////////////////////////////////////
  wire [4:0] tmds_data0, tmds_data1, tmds_data2;

  dvi_encoder enc0 (
    .clkin      (pclk),
    .clkx2in    (pclkx2),
    .rstin      (reset),
    .blue_din   (blue_data),
    .green_din  (green_data),
    .red_din    (red_data),
    .hsync      (VGA_HSYNC),
    .vsync      (VGA_VSYNC),
    .de         (de),
    .tmds_data0 (tmds_data0),
    .tmds_data1 (tmds_data1),
    .tmds_data2 (tmds_data2));


  wire [2:0] tmdsint;

  wire serdes_rst = ~RSTBTN_ | ~bufpll_lock;


  serdes_n_to_1 #(.SF(5)) oserdes0 (
             .ioclk(pclkx10),
             .serdesstrobe(serdesstrobe),
             .reset(serdes_rst),
             .gclk(pclkx2),
             .datain(tmds_data0),
             .iob_data_out(tmdsint[0])) ;

  serdes_n_to_1 #(.SF(5)) oserdes1 (
             .ioclk(pclkx10),
             .serdesstrobe(serdesstrobe),
             .reset(serdes_rst),
             .gclk(pclkx2),
             .datain(tmds_data1),
             .iob_data_out(tmdsint[1])) ;

  serdes_n_to_1 #(.SF(5)) oserdes2 (
             .ioclk(pclkx10),
             .serdesstrobe(serdesstrobe),
             .reset(serdes_rst),
             .gclk(pclkx2),
             .datain(tmds_data2),
             .iob_data_out(tmdsint[2])) ;

  OBUFDS TMDS0 (.I(tmdsint[0]), .O(TMDS[0]), .OB(TMDSB[0])) ;
  OBUFDS TMDS1 (.I(tmdsint[1]), .O(TMDS[1]), .OB(TMDSB[1])) ;
  OBUFDS TMDS2 (.I(tmdsint[2]), .O(TMDS[2]), .OB(TMDSB[2])) ;

  reg [4:0] tmdsclkint = 5'b00000;
  reg toggle = 1'b0;

  always @ (posedge pclkx2 or posedge serdes_rst) begin
    if (serdes_rst)
      toggle <= 1'b0;
    else
      toggle <= ~toggle;
  end

  always @ (posedge pclkx2) begin
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
    .ioclk        (pclkx10),
    .serdesstrobe (serdesstrobe),
    .gclk         (pclkx2),
    .reset        (serdes_rst),
    .datain       (tmdsclkint));

  OBUFDS TMDS3 (.I(tmdsclk), .O(TMDS[3]), .OB(TMDSB[3])) ;// clock
 
 wire light = JA;
 wire btn   = BTNU;

 parameter IDLE  = 3'b000;
 parameter READY = 3'b001; // Waiting 1 second for save button input
 parameter WAIT  = 3'b010;
 parameter START = 3'b011;
 parameter STOP  = 3'b100;

 reg [2:0] state = IDLE;
 reg       flg;
 
 /* FSM of Counter */
 always @ (posedge clk100) begin
   if(~RSTBTN_)begin
		 state <= IDLE;
   end else begin
	   case(state)
		   IDLE  : if(btn) state <= READY;
			 READY : if(flg) state <= WAIT;
			 WAIT  : if(start) state <= START;
			 START : if(light) state <= STOP;
			 STOP  : state <= IDLE;
		 endcase
	 end
 end

 /* Counter */
 reg [27:0] cnt;
 reg [27:0] dcnt;
 reg        blank, start;
 reg [7:0] red, green, blue;
 always @ (posedge clk100)
   if(~RSTBTN_)begin
		 cnt  <= 28'd0;
		 dcnt <= 28'd0;
		 flg  <= 1'b0;
		 blank <= 1'b0;
		 start <= 1'b0;
		 red   <= 8'd15;
		 green <= 8'd15;
		 blue  <= 8'd15;
	 end else begin
	   if(state == IDLE)begin
		   cnt <= 28'd0;
			 flg <= 1'b0;
			 blank <= 1'b0;
			 start <= 1'b0;
		   red   <= 8'd15;
		   green <= 8'd15;
		   blue  <= 8'd15;
		 end
	   if(state == READY)begin
		   red   <= 8'd15;
		   green <= 8'd15;
		   blue  <= 8'd15;
		   if(cnt == 28'd100000000)begin
				 flg <= 1'b1;
				 cnt <= 28'd0;
			 end else
			   cnt <= cnt + 28'd1;
		 end
	   if(state == WAIT)begin
		   red   <= 8'd15;
		   green <= 8'd15;
		   blue  <= 8'd15;
			 if(bgnd_vblnk)
				 blank <= 1'b1;
			 if(blank & !bgnd_vblnk)
				 start <= 1'b1;
		 end
		 if(state == START)begin
		   red   <= 8'd240;
		   green <= 8'd240;
		   blue  <= 8'd240;
			 flg  <= 1'b0;
			 cnt  <= cnt + 28'd1;
			 dcnt <= 28'd0;
		 end
		 if(state == STOP)begin
		   red   <= 8'd15;
		   green <= 8'd15;
		   blue  <= 8'd15;
			 dcnt <= cnt;
		 end
   end

	assign red_data   = (state == IDLE | state == READY | state == WAIT) ? 8'd15 : 8'd240;
  assign green_data = (state == IDLE | state == READY | state == WAIT) ? 8'd15 : 8'd240;
	assign blue_data  = (state == IDLE | state == READY | state == WAIT) ? 8'd15 : 8'd240;

	//assign red_data   = red;
  //assign green_data = green;
	//assign blue_data  = blue;
  
	always @ (*) begin
		case(swled)
		  2'b00 : LED <= dcnt[7:0];
		  2'b01 : LED <= dcnt[15:8];
		  2'b10 : LED <= dcnt[23:16];
		  2'b11 : LED <= {state,led,dcnt[27:24]};
		endcase
	end
 
 // UART module
 /* wire err;
 reg [31:0] mem;
 reg we, wr, err_b;
 reg [1:0]mcnt;
 always @ (posedge clk100 or negedge RSTBTN)
   if(~RSTBTN)begin
     mem  <= 32'd0;
		 we   <= 1'b0;
		 wr   <= 1'b0;
		 mcnt <= 2'd0;
   end else begin
		 if(state == STOP) begin
			 mem <= {8'd0,dcnt};
			 we  <= 1'd1;
     end
		 if(mcnt == 2'd2) begin
       we   <= 1'd0;
       mcnt <= 2'd0;
     end else if(~err & we & ~wr) begin
			 mem <= {8'd0,mem[31:8]};
			 mcnt <= mcnt + 1;
			 wr  <= 1'd1;
		 end

		 err_b <= err;
		 if({err,err_b} == 2'b01)
			 wr <= 1'd0;
   end

 reg [9:0] clkcnt;
 reg uclk = 1'b0;
 always @ (posedge clk100 or negedge RSTBTN)
   if(~RSTBTN) begin
     clkcnt <= 10'd0;
     uclk   <= 1'd0;
   end else begin
	   if(clkcnt == 10'd651)begin
       clkcnt <= 10'd0;
			 uclk <= ~uclk;
     end else
       clkcnt <= clkcnt + 10'd1;
	 end
		 

 uart_tx uart(
   .clk(uclk),
	 .rst(~RSTBTN),
	 .data(mem[7:0]),
	 .we(we),
	 .tx(UART_RX),
	 .busy(err)
 );
*/
endmodule
