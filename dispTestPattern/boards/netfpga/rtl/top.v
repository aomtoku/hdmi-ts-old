//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2008 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor:        Xilinx
// \   \   \/    Version:       1.0.0
//  \   \        Filename:      dvitx_demo.v
//  /   /        Date Created:  September, 2008
// /___/   /\    Last Modified: September, 2008
// \   \  /  \
//  \___\/\___\
//
// Devices:   Spartan-3 Generation FPGA
// Purpose:   DVI TX Only demo top level
// Contact:   
// Reference: None
//
// Revision History:
//   Rev 1.0.0 - Bob Feng
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
// Copyright (c) 2006 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

module top (
  input  wire  SYS_CLK,

  //input  wire  [3:0] SW,
  output wire   [2:0] LED,

  output wire   [3:0] TMDS,
  output wire   [3:0] TMDSB
);

  parameter SW_HDTV720P   = 2'b00;
  parameter SW_HDTV1080I  = 2'b01;

  /******************************************************************
  // Create global clock and synchronous system reset.                
  //*******************************************************************/

  wire          locked;
  reg           switch;
  wire          reset;

  wire          clkx5dcm;
  wire          clkx5notdcm;
  wire          clkx5;
  wire          clkx5not;

  reg clk50;
  always @ (posedge SYS_CLK)
	  clk50 <= ~clk50;

  BUFG   pclkbufg (.I(clk50), .O(pclk));
  DCM_BASE #(
    .CLK_FEEDBACK ("NONE"),
    .CLKFX_DIVIDE	(1),	
    .CLKFX_MULTIPLY	(5))
  DCM_BASE_INST (
    .CLKIN(clk50),
    .CLKFB(),
    .RST(1'b0),
    //.PSEN(1'b0),
    //.PSINCDEC(1'b0),
    //.PSCLK(1'b0),
    //.DSSEN(1'b0),
    .CLK0(),
    .CLK90(),
    .CLK180(),
    .CLK270(),
    .CLKDV(),
    .CLK2X(),
    .CLK2X180(),
    .CLKFX(clkx5dcm),
    .CLKFX180(clkx5notdcm),
    //.STATUS(),
    .LOCKED(locked)
    //.PSDONE()
	);

  //DCM that generates 5x Pixel clock
  /*DCM_SP #(
    .CLK_FEEDBACK ("NONE"),
    .CLKFX_DIVIDE	(1),	
    .CLKFX_MULTIPLY	(5))
  DCM_SP_INST (
    .CLKIN(clk50),
    .CLKFB(),
    .RST(1'b0),
    .PSEN(1'b0),
    .PSINCDEC(1'b0),
    .PSCLK(1'b0),
    .DSSEN(1'b0),
    .CLK0(),
    .CLK90(),
    .CLK180(),
    .CLK270(),
    .CLKDV(),
    .CLK2X(),
    .CLK2X180(),
    .CLKFX(clkx5dcm),
    .CLKFX180(clkx5notdcm),
    .STATUS(),
    .LOCKED(locked),
    .PSDONE());*/

  BUFG clkx5bufg (.I(clkx5dcm), .O(clkx5));
  BUFG clkx5notbufg (.I(clkx5notdcm), .O(clkx5not));

  synchro #(.INITIALIZE("LOGIC1"))
  synchro_reset (.async(!locked | switch),.sync(reset),.clk(pclk));

  // TMDS stuff

  wire [9:0]   red ;
  wire [9:0]   green ;
  wire [9:0]   blue ;
  reg          de ;
  wire         VGA_HSYNC_INT ;
  wire         VGA_VSYNC_INT ;
  wire [3:0]   TMDSINT ;
  wire [7:0]   green_data ;
  wire [7:0]   blue_data ;
  wire [7:0]   red_data ;
  wire [7:0]   tmds_data ;
  wire [29:0]  s_data ;
  reg          VGA_HSYNC;
  reg          VGA_VSYNC;

  wire active;
  dvi_encoder # (
    .SDATAINVERT("TRUE")
  ) enc0 (
    .clkin			(pclk),
    .clkx5in		(clkx5),
    .clkx5notin	(clkx5not),
    .rstin			(reset),
    .blue_din		(blue_data),
    .green_din	(green_data),
    .red_din		(red_data),
    .hsync			(VGA_HSYNC),
    .vsync			(VGA_VSYNC),
    .de			    (de),
    .tmds_data	(tmds_data));

  reg   [7:0] led_out;

  ODDR 	#( 
	         .DDR_CLK_EDGE ("SAME_EDGE"),
	         .INIT (1'b0),
				   .SRTYPE ("SYNC")
	) ddr_reg0   (
	         .C(clkx5), 
           //.C1(clkx5not), 
           .D1(tmds_data[0]), 
           .D2(tmds_data[4]), 
           .CE(1'b1), 
           .R(1'b0), 
           .S(1'b0), 
           .Q(TMDSINT[0])
	) ;

  ODDR 	#( 
	          .DDR_CLK_EDGE ("SAME_EDGE"),
	          .INIT (1'b0),
				    .SRTYPE ("SYNC")
	) ddr_reg1   (
	          .C(clkx5), 
            //.C1(clkx5not), 
            .D1(tmds_data[1]), 
            .D2(tmds_data[5]), 
            .CE(1'b1), 
            .R(1'b0), 
            .S(1'b0), 
            .Q(TMDSINT[1])) ;

  ODDR 	#( .DDR_CLK_EDGE ("SAME_EDGE"),
	       .INIT (1'b0),
				        .SRTYPE ("SYNC")
		) ddr_reg2   (.C(clkx5), 
                  //.C1(clkx5not), 
                  .D1(tmds_data[2]), 
                  .D2(tmds_data[6]), 
                  .CE(1'b1), 
                  .R(1'b0), 
                  .S(1'b0), 
                  .Q(TMDSINT[2])) ;

  ODDR 	#( 
	          .DDR_CLK_EDGE ("SAME_EDGE"),
	          .INIT (1'b0),
				    .SRTYPE ("SYNC")
		) ddr_reg3   ( .C(pclk),         // .C0(clkx5), 
            // .C1(~pclk),        // .C1(clkx5not), 
            .D1(1'b1),         // .D0(tmds_data[3]), 
            .D2(1'b0),         // .D1(tmds_data[7]), 
            .CE(1'b1),         // .CE(1'b1), 
            .R(1'b0),          // .R(1'b0), 
            .S(1'b0),          // .S(1'b0), 
            .Q(TMDSINT[3])
		) ;  // .Q(TMDSINT[3])) ;
/*
  ODDR2 	#(.DDR_ALIGNMENT("NONE")) ddr_reg0   (.C0(clkx5), 
                                              .C1(clkx5not), 
                                              .D0(tmds_data[0]), 
                                              .D1(tmds_data[4]), 
                                              .CE(1'b1), 
                                              .R(1'b0), 
                                              .S(1'b0), 
                                              .Q(TMDSINT[0])) ;

  ODDR2 	#(.DDR_ALIGNMENT("NONE")) ddr_reg1   (.C0(clkx5), 
                                              .C1(clkx5not), 
                                              .D0(tmds_data[1]), 
                                              .D1(tmds_data[5]), 
                                              .CE(1'b1), 
                                              .R(1'b0), 
                                              .S(1'b0), 
                                              .Q(TMDSINT[1])) ;

  ODDR2 	#(.DDR_ALIGNMENT("NONE")) ddr_reg2   (.C0(clkx5), 
                                              .C1(clkx5not), 
                                              .D0(tmds_data[2]), 
                                              .D1(tmds_data[6]), 
                                              .CE(1'b1), 
                                              .R(1'b0), 
                                              .S(1'b0), 
                                              .Q(TMDSINT[2])) ;

  ODDR2 	#(.DDR_ALIGNMENT("NONE")) ddr_reg3   ( .C0(pclk),         // .C0(clkx5), 
                                                 .C1(~pclk),        // .C1(clkx5not), 
                                                 .D0(1'b1),         // .D0(tmds_data[3]), 
                                                 .D1(1'b0),         // .D1(tmds_data[7]), 
                                                 .CE(1'b1),         // .CE(1'b1), 
                                                 .R(1'b0),          // .R(1'b0), 
                                                 .S(1'b0),          // .S(1'b0), 
                                                 .Q(TMDSINT[3])) ;  // .Q(TMDSINT[3])) ;
*/
  OBUFDS TMDS0 (.I(TMDSINT[0]), .O(TMDS[0]), .OB(TMDSB[0])) ;
  OBUFDS TMDS1 (.I(TMDSINT[1]), .O(TMDS[1]), .OB(TMDSB[1])) ;
  OBUFDS TMDS2 (.I(TMDSINT[2]), .O(TMDS[2]), .OB(TMDSB[2])) ;
  OBUFDS TMDS3 (.I(TMDSINT[3]), .O(TMDS[3]), .OB(TMDSB[3])) ;// clock
			
  //******************************************************************//
  // Instantiate picotext using parameter defaults.  Locate the ports //
  // starting from port_id 0x00 up to and including port_id 0x1F.     //
  //******************************************************************//
  // Signals for external background
  // image generation (rotozoomer).

  wire   [11:0] bgnd_hcount;
  wire          bgnd_hsync;
  wire          bgnd_hblnk;
  wire   [11:0] bgnd_vcount;
  wire          bgnd_vsync;
  wire          bgnd_vblnk;

///////////////////////////////////////////////////////////////////////////
// Video Timing Parameters
///////////////////////////////////////////////////////////////////////////

/****************************************************************************************************
  1080i Vertical Timing:

|<-- 540 Active Lines --->|<-- 23 vblnks --->|<-- 540 Active Lines --->|<-- 22 vblnks -->|
|_________......__________|                  |_________......__________|                 |__......
|                         |                  |                         |                 |
|                         |______......______|                         |______......_____|
^                        ^                  ^                         ^                 ^
0                       539                562                       1102              1124

VSYNC:
                              _____                                        _____
                             |     |                                      |     |
_____________________________|     |______________________________________|     |___________

****************************************************************************************************/
  //1920x1080@60HZ - Interlaced
`ifdef SIMULATION
  parameter HPIXELS_HDTV1080I = 12'd1920/10;
`else
  parameter HPIXELS_HDTV1080I = 12'd1920; //Horizontal Live Pixels
`endif
  parameter VLINES_HDTV1080I  = 12'd1080; //Vertical Live ines
  parameter HSYNCPW_HDTV1080I = 12'd44; //HSYNC Pulse Width
  parameter VSYNCPW_HDTV1080I = 12'd5; //VSYNC Pulse Width
  parameter HFNPRCH_HDTV1080I = 12'd88; //Horizontal Front Portch
  parameter VFNPRCH_HDTV1080I = 12'd2; //Vertical Front Portch
  parameter HBKPRCH_HDTV1080I = 12'd148; //Horizontal Front Portch
  parameter VBKPRCH_HDTV1080I = 12'd15; //Vertical Back Portch
  parameter VBLNKLEN_HDTV1080I_1 = VBKPRCH_HDTV1080I + VSYNCPW_HDTV1080I + VFNPRCH_HDTV1080I + 12'd1;
  parameter VBLNKLEN_HDTV1080I_2 = VBKPRCH_HDTV1080I + VSYNCPW_HDTV1080I + VFNPRCH_HDTV1080I;

  //1920x1080@30HZ - Progressive
  parameter HPIXELS_HDTV1080P = 12'd1920; //Horizontal Live Pixels
  parameter VLINES_HDTV1080P  = 12'd1080; //Vertical Live ines
  parameter HSYNCPW_HDTV1080P = 12'd88; //HSYNC Pulse Width
  parameter VSYNCPW_HDTV1080P = 12'd5; //VSYNC Pulse Width
  parameter HFNPRCH_HDTV1080P = 12'd44; //Horizontal Front Portch
  parameter VFNPRCH_HDTV1080P = 12'd4; //Vertical Front Portch
  parameter HBKPRCH_HDTV1080P = 12'd148; //Horizontal Front Portch
  parameter VBKPRCH_HDTV1080P = 12'd36; //Vertical Back Portch

  //1280x720@60HZ
`ifdef SIMULATION
  parameter HPIXELS_HDTV720P = 12'd128; //Horizontal Live Pixels
  parameter VLINES_HDTV720P  = 12'd72;  //Vertical Live ines
`else
  parameter HPIXELS_HDTV720P = 12'd1280; //Horizontal Live Pixels
  parameter VLINES_HDTV720P  = 12'd720;  //Vertical Live ines
`endif
  parameter HSYNCPW_HDTV720P = 12'd40;  //HSYNC Pulse Width
  parameter VSYNCPW_HDTV720P = 12'd5;    //VSYNC Pulse Width
  parameter HFNPRCH_HDTV720P = 12'd110;   //Horizontal Front Portch
  parameter VFNPRCH_HDTV720P = 12'd5;    //Vertical Front Portch
  parameter HBKPRCH_HDTV720P = 12'd220;  //Horizontal Front Portch
  parameter VBKPRCH_HDTV720P = 12'd20;   //Vertical Front Portch

/*
  wire  [3:0] sws_sync; //synchronous output

  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_3 (.async(SW[3]),.sync(sws_sync[3]),.clk(pclk));

  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_2 (.async(SW[2]),.sync(sws_sync[2]),.clk(pclk));

  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_1 (.async(SW[1]),.sync(sws_sync[1]),.clk(pclk));

  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_0 (.async(SW[0]),.sync(sws_sync[0]),.clk(pclk));

  reg [3:0] sws_sync_q;
  always @ (posedge pclk)
  begin
    sws_sync_q <= sws_sync;
  end

  debnce debsw0 (
    .sync(sws_sync_q[0]),
    .event_on(sw0_on),
    .event_off(sw0_off),
    .clk(pclk));

  debnce debsw1 (
    .sync(sws_sync_q[1]),
    .event_on(sw1_on),
    .event_off(sw1_off),
    .clk(pclk));

  debnce debsw2 (
    .sync(sws_sync_q[2]),
    .event_on(sw2_on),
    .event_off(sw2_off),
    .clk(pclk));

  debnce debsw3 (
    .sync(sws_sync_q[3]),
    .event_on(sw3_on),
    .event_off(sw3_off),
    .clk(pclk));

  always @ (posedge pclk)
  begin
    switch <= sw0_on | sw0_off | sw1_on | sw1_off;
  end
*/
  wire  [3:0] sws_clk;      //clk synchronous output
/*
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
*/
  wire baronly = 1'b1;


  reg [11:0] tc_hsblnk = HPIXELS_HDTV720P - 12'd1;                                          
  reg [11:0] tc_hssync = HPIXELS_HDTV720P - 12'd1 + HFNPRCH_HDTV720P;                            
  reg [11:0] tc_hesync = HPIXELS_HDTV720P - 12'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P;              
  reg [11:0] tc_heblnk = HPIXELS_HDTV720P - 12'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P + HBKPRCH_HDTV720P;
  reg [11:0] tc_vsblnk =  VLINES_HDTV720P - 12'd1;                                          
  reg [11:0] tc_vssync =  VLINES_HDTV720P - 12'd1 + VFNPRCH_HDTV720P;                            
  reg [11:0] tc_vesync =  VLINES_HDTV720P - 12'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P;              
  reg [11:0] tc_veblnk =  VLINES_HDTV720P - 12'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P + VBKPRCH_HDTV720P;

  reg [11:0] tc_vsblnk2 = 12'd0;
  reg [11:0] tc_vssync2 = 12'd0;
  reg [11:0] tc_vesync2 = 12'd0;
  reg [11:0] tc_veblnk2 = 12'd0;


  timing timing_inst (
    .interlace(interlace),
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

    .tc_vsblnk2(tc_vsblnk2), //input
    .tc_vssync2(tc_vssync2), //input
    .tc_vesync2(tc_vesync2), //input
    .tc_veblnk2(tc_veblnk2), //input

    .vcount(bgnd_vcount), //output
    .vsync(VGA_VSYNC_INT), //output
    .vblnk(bgnd_vblnk), //output
    .restart(reset),
    .clk(pclk));

  //////////////////////////////////////
  // Status LED
  //////////////////////////////////////
  assign LED = ~locked;

  /////////////////////////////////////////
  // Check Me
  /////////////////////////////////////////
  assign active = !bgnd_hblnk && !bgnd_vblnk;

  reg active_q, active_qq;
  reg vsync, hsync;
  always @ (posedge pclk)
  begin
  	hsync <= VGA_HSYNC_INT;  //  ^ hvsync_polarity ;
  	vsync <= VGA_VSYNC_INT;  //  ^ hvsync_polarity ;
    VGA_HSYNC <= hsync;
    VGA_VSYNC <= vsync;
    
    /* Nick's DVI encoder requires RGB data to be
       1 clock cycle earlier than the DE instead
       of aligning together */
    active_q <= active;
    active_qq <= active_q;
    de <= active_qq;
  end

  hdcolorbar clrbar(
    .i_clk_74M(pclk),
    .i_rst(reset),
    .i_hcnt(bgnd_hcount),
    .i_vcnt(bgnd_vcount),
    .baronly(baronly),
    .i_format({interlace, hdtype}),
    .o_r(red_data),//(red_data),
    .o_g(green_data),//(green_data),
    .o_b(blue_data)//(blue_data)
  );

  ///////////////////////////////////////////////////////////
  // Flying Logo: Spartan3A Logo flying 
  ///////////////////////////////////////////////////////////
  /*reg vsync_q, framestart;
  always @ (posedge pclk) begin
    vsync_q <= VGA_VSYNC;
    framestart <= !vsync_q & VGA_VSYNC;
  end

  reg twoframes;
  always @ (posedge pclk) begin
    if(reset)
      twoframes <= 1'b0;
    else if(framestart)
      twoframes <= ~twoframes;
  end

  reg twoframes_q, dblframe;
  always @ (posedge pclk) begin
    twoframes_q <= twoframes;
    dblframe <= !twoframes_q & twoframes;
  end

  //
  // Here I am simply trying to hold the logo for 2 seconds which consume about 120 frames
  //
  reg [7:0] timestep;
  wire tstep_mid;

  assign tstep_mid = (timestep == 8'd78);

  reg tstep_mid_q;
  reg hldlogo_cnt_rst;
  reg [6:0] hldlogo_cnt; //a counter to hold logo on the top (when timestep is 75)
  wire hldlogo_cnt_full;

  always @ (posedge pclk) begin
    tstep_mid_q <= tstep_mid;
    hldlogo_cnt_rst <= !tstep_mid_q & tstep_mid;
  end

  always @ (posedge pclk) begin
    if(hldlogo_cnt_rst)
      hldlogo_cnt <= 7'h0;
    else if(framestart && !hldlogo_cnt_full)
      hldlogo_cnt <= hldlogo_cnt + 7'h1;
  end

  assign hldlogo_cnt_full = (hldlogo_cnt == 7'hff);

  wire hldlogo;
  assign hldlogo = (tstep_mid && !hldlogo_cnt_full);
  
   always @ (posedge pclk) begin
    if(reset)
      timestep <= 8'h0;
    //else if(dblframe && !hldlogo)
    else if(framestart && !hldlogo)
      timestep <= timestep + 1'b1;
  end

  parameter BLACK  = {8'h0, 8'h0, 8'h0};
  parameter WHITE  = {8'hff, 8'hff, 8'hff};
  parameter YELLOW = {8'hff, 8'hff, 8'h0};
  parameter RED    = {8'hff, 8'h0, 8'h0};

  parameter LOGO_WIDTH  = 12'd128;
  parameter LOGO_HEIGHT = 12'd128;

  wire   [11:0] auto_data_x; 
  wire   [11:0] auto_data_y; 
 
  autopilot autopilot_inst ( //ROM stores logo starting position
    .timestep(timestep),         //Fix me later
    .xlocation(auto_data_x),
    .ylocation(auto_data_y),
    .clk(pclk));

  reg    [11:0] hcount_hwc2_pipe;
  reg    [11:0] vcount_hwc2_pipe;

  reg    [11:0] cursor2_xidx;
  reg    [11:0] cursor2_yidx;
  wire    [1:0] cursor2_data;
  wire          cursor2_mask;

  reg    [11:0] cursor3_xidx;
  reg    [11:0] cursor3_yidx;
  wire    [1:0] cursor3_data;
  wire          cursor3_mask;

  reg     [7:0] cursor2_r;
  reg     [7:0] cursor2_g;
  reg     [7:0] cursor2_b;
  reg           cursor2_t;

  always @(posedge pclk) hcount_hwc2_pipe <= bgnd_hcount;
  always @(posedge pclk) vcount_hwc2_pipe <= bgnd_vcount;

  always @(posedge pclk) cursor2_xidx <= hcount_hwc2_pipe - auto_data_x; //cursor2_xpos;
  always @(posedge pclk) cursor2_yidx <= vcount_hwc2_pipe - auto_data_y; //cursor2_ypos;
  always @(posedge pclk) cursor3_xidx <= 12'h0; //hcount_hwc2_pipe - cursor3_xpos;
  always @(posedge pclk) cursor3_yidx <= 12'h0; //vcount_hwc2_pipe - cursor3_ypos;

  cursor_pair #(.IMAGE("SPARTAN3A"))
  cursor_pair_inst1 (
    .xidx0(cursor2_xidx),
    .yidx0(cursor2_yidx),
    .data0(cursor2_data),
    .mask0(cursor2_mask),
    .xidx1(cursor3_xidx),
    .yidx1(cursor3_yidx),
    .data1(cursor3_data),
    .mask1(cursor3_mask),
    .clk(pclk));

  always @(posedge pclk)
  begin
    if (cursor2_mask)
    begin
      cursor2_r <= 4'h0;
      cursor2_g <= 4'h0;
      cursor2_b <= 4'h0;
      cursor2_t <= 1'b1;
    end
    else
    begin
      case (cursor2_data)
      0: begin
           {cursor2_r, cursor2_g, cursor2_b} <= BLACK;
           cursor2_t <=  1'b0;
         end
      1: begin
           {cursor2_r, cursor2_g, cursor2_b} <= WHITE;
           cursor2_t <= 1'b0;
         end
      2: begin
           {cursor2_r, cursor2_g, cursor2_b} <= RED; //This is really transparent instead
           cursor2_t <= 1'b1;
         end
      3: begin
           {cursor2_r, cursor2_g, cursor2_b} <= YELLOW;
           cursor2_t <= 1'b0;
         end
      endcase
    end
  end

  assign red_data   = (cursor2_t) ? clrbar_r : cursor2_r;
  assign green_data = (cursor2_t) ? clrbar_g : cursor2_g;
  assign blue_data  = (cursor2_t) ? clrbar_b : cursor2_b;
*/
endmodule
