//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2010 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor:        Xilinx
// \   \   \/    Version:       1.0.0
//  \   \        Filename:      dvi_demo.v
//  /   /        Date Created:  Feb. 2010
// /___/   /\    Last Modified: Feb. 2010
// \   \  /  \
//  \___\/\___\
//
// Devices:   Spartan-6  FPGA
// Purpose:   DVI Pass Through Top Module Based On XLAB Atlys Board
// Contact:   
// Reference: None
//
// Revision History:
//   Rev 1.0.0 - (Bob Feng) First created Feb. 2010
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
// Copyright (c) 2010 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

module dvi_demo (
  /**** SYSTEM ****/
  input wire        rstbtn_n,    //The BTN NORTH
  input wire        clk100,      //100 MHz osicallator
  
  /**** TMDS OUTPUT ****/
  input wire [3:0]  RX0_TMDS,
  input wire [3:0]  RX0_TMDSB,

  /**** Ethernet PHY ****/
  output wire 		  RESET,
  input	wire		  RXCLK,
  output	wire 		  GTXCLK,
  output	wire 		  TXEN,
  output wire [7:0] TXD,

  input  wire [3:0] SW,
  output wire [1:0] PMOD,

  output wire [7:0] LED
);

`define FRAME_CHECK

//-----------------------------------------------------------
//  CLOCK for GMII TX 125MHz
//-----------------------------------------------------------
wire gmii_tx_clk, gmii_tx_clk_90;
assign GTXCLK = gmii_tx_clk;

IBUFG sysclk_buf (.I(clk100), .O(sysclk));

clk_wiz_v3_6 gmii_tx_clk125
 (// Clock in ports
  .CLK_IN1(sysclk),
  // Clock out ports
  .CLK_OUT1(gmii_tx_clk),
  .CLK_OUT2(gmii_tx_clk_90),
  // Status and control signals
  .RESET(rstbtn_n),
  .LOCKED()
 );

//-----------------------------------------------------------
//  PHY RESET
//-----------------------------------------------------------
reg [19:0] coldsys_rst = 0;
wire coldsys_rst10ms = (coldsys_rst == 20'h100000);
always @(posedge RXCLK)
  coldsys_rst <= !coldsys_rst10ms ? coldsys_rst + 20'h1 : 20'h100000;
assign RESET = coldsys_rst10ms;

//-----------------------------------------------------------
//  FIFO(48bit) to GMII
//		Depth --> 4096
//-----------------------------------------------------------
wire full;
wire empty;
wire [47:0]tx_data;
wire rd_en;
wire [47:0]din_fifo = {in_vcnt/*in_hcnt*/,index, rx0_red, rx0_green, rx0_blue};
wire rx0_pclk;           
wire rx0_hsync;          // hsync data
wire rx0_vsync;          // vsync data
wire fifo_wr_en = /*(in_hcnt <= 12'd1280 & in_vcnt < 12'd720) & */video_en;

fifo48_8k asfifo(
	.rst(rstbtn_n | rx0_vsync),
	.wr_clk(rx0_pclk),  // TMDS clock 74.25MHz 
	.rd_clk(gmii_tx_clk),  // GMII TX clock 125MHz
	.din(din_fifo),     // data input 48bit
	.wr_en(fifo_wr_en),
	.rd_en(rd_en),
	.dout(tx_data),    // data output 48bit 
	.full(full),
	.empty(empty)
);

  //////////////////////////////////////////////////
  //
  // TMDS Input Port 0 (BANK : )
  //
  //////////////////////////////////////////////////
  wire rx0_tmdsclk;
  wire rx0_pclkx10, rx0_pllclk0;
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
    .exrst       (rstbtn_n),

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
    .blue        (rx0_blue)); 


  //-----------------------------------------------------
  // TMDS HSYNC VSYNC COUNTER ()
  //           (1280x720 progressive 
  //                     HSYNC: 45khz   VSYNC : 60Hz)
  //-----------------------------------------------------
  
  wire [11:0]in_hcnt = {1'b0, video_hcnt[10:0]};
  wire [11:0]in_vcnt = {1'b0, video_vcnt[10:0]};
  wire [10:0]video_hcnt;
  wire [10:0]video_vcnt;
  wire [11:0]index;
  wire video_en;

  tmds_timing timing(
		.rx0_pclk(rx0_pclk),
		.rstbtn_n(rstbtn_n), 
		.rx0_hsync(rx0_hsync),
		.rx0_vsync(rx0_vsync),
		.video_en(video_en),
		.index(index),
		.video_hcnt(video_hcnt),
		.video_vcnt(video_vcnt)
  );


//-----------------------------------------------------------
//  GMII TX
//-----------------------------------------------------------
  
  gmii_tx gmii_tx(
	/*** FIFO ***/
	.fifo_clk(rx0_pclk),
	.sys_rst(rstbtn_n),
	.dout(tx_data), //48bit
	.empty(empty),
	.full(full),
	.rd_en(rd_en),
	.wr_en(video_en),
	
	/*** Ethernet PHY GMII ***/
	.tx_clk(gmii_tx_clk),
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
	.rst(rstbtn_n),
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
  reg pcnt;
  always@(posedge rx0_pclk)
	if(rstbtn_n)
		pcnt <= 1'd0;
	else
		pcnt <= ~pcnt;
  
  assign PMOD[0] = pcnt;
  assign PMOD[1] = pcnt;
  
  assign LED = LED_out(	.SW(SW), 
								.TXD(TXD), 
								.empty(empty), 
								.full(full), 
								.rx0_de(rx0_de)
							);
  
  function [7:0]LED_out;
  input [3:0]SW;
  input [7:0]TXD;
  input empty;
  input full;
  input rx0_de;
  begin
	case(SW)
		4'b0000: LED_out ={empty,full, rx0_de, 5'd0};
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

endmodule
