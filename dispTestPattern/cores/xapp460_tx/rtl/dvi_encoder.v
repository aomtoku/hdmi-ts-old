//////////////////////////////////////////////////////////////////////////////
//
//  Xilinx, Inc. 2007                 www.xilinx.com
//
//  XAPP xyz
//
//////////////////////////////////////////////////////////////////////////////
//
//  File name :       dvi_encoder.v
//
//  Description :     dvi_encoder 
//
//  Date - revision : Feb. 2008 - 1.0.0
//
//  Author :          Bob Feng
//
//  Disclaimer: LIMITED WARRANTY AND DISCLAMER. These designs are
//              provided to you "as is". Xilinx and its licensors makeand you
//              receive no warranties or conditions, express, implied,
//              statutory or otherwise, and Xilinx specificallydisclaims any
//              implied warranties of merchantability, non-infringement,or
//              fitness for a particular purpose. Xilinx does notwarrant that
//              the functions contained in these designs will meet your
//              requirements, or that the operation of these designswill be
//              uninterrupted or error free, or that defects in theDesigns
//              will be corrected. Furthermore, Xilinx does not warrantor
//              make any representations regarding use or the results ofthe
//              use of the designs in terms of correctness, accuracy,
//              reliability, or otherwise.
//
//              LIMITATION OF LIABILITY. In no event will Xilinx or its
//              licensors be liable for any loss of data, lost profits,cost
//              or procurement of substitute goods or services, or forany
//              special, incidental, consequential, or indirect damages
//              arising from the use or operation of the designs or
//              accompanying documentation, however caused and on anytheory
//              of liability. This limitation will apply even if Xilinx
//              has been advised of the possibility of such damage. This
//              limitation shall apply not-withstanding the failure ofthe
//              essential purpose of any limited remedies herein.
//
//  Copyright © 2004 Xilinx, Inc.
//  All rights reserved
//
//////////////////////////////////////////////////////////////////////////////
`timescale 1 ps / 1ps

module dvi_encoder # (
  parameter SDATAINVERT = "FALSE" //Invert or not SDATA before serilize it
)(
input			clkin,			// system clock
input			clkx5in,		// system clock x5
input     clkx5notin, // system clock x5 not
input			rstin,			// reset
input		[7:0]	blue_din,		// Blue data in
input		[7:0]	green_din,		// Green data in
input		[7:0]	red_din,		// Red data in
input			hsync,			// hsync data
input			vsync,			// vsync data
input			de,			// data enable
output	[7:0]	tmds_data) ;		// data outputs to ddr in IOB, bit 3(and 7) is clock
	
wire 	[9:0]	red ;
wire 	[9:0]	green ;
wire 	[9:0]	blue ;
wire 	[29:0]	s_data ;

encode encb (
	.clkin	(clkin),
	.rstin	(rstin),
	.din		(blue_din),
	.c0			(hsync),
	.c1			(vsync),
	.de			(de),
	.dout		(blue)) ;

encode encr (
	.clkin	(clkin),
	.rstin	(rstin),
	.din		(green_din),
	.c0			(1'b0),
	.c1			(1'b0),
	.de			(de),
	.dout		(green)) ;
	
encode encg (
	.clkin	(clkin),
	.rstin	(rstin),
	.din		(red_din),
	.c0			(1'b0),
	.c1			(1'b0),
	.de			(de),
	.dout		(red)) ;

assign s_data = {red[9], green[9], blue[9], red[8], green[8], blue[8],
	   	 red[7], green[7], blue[7], red[6], green[6], blue[6],
	   	 red[5], green[5], blue[5], red[4], green[4], blue[4],
	   	 red[3], green[3], blue[3], red[2], green[2], blue[2],
	   	 red[1], green[1], blue[1], red[0], green[0], blue[0]} ;

reg [29:0] s_data_q;

always @ (posedge clkin) begin
  if(SDATAINVERT == "TRUE")
    s_data_q <= ~s_data;
  else
    s_data_q <= s_data;
end

serdes_4b_10to1 serialise (
	.clk			(clkin),
	.clkx5		(clkx5in),
	.clkx5not	(clkx5notin),
	.datain		(s_data_q),
	.rst			(rstin),
	.dataout	(tmds_data)) ;
		
endmodule
