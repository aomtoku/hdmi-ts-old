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
  output reg  [7:0] LED,
	input  wire       JA,
	output wire       REDLED,
	input  wire       BTNU
);

  //******************************************************************//
  // Create global clock and synchronous system reset.                //
  //******************************************************************//
	wire          clk100,sysclk;

  IBUF sysclk_buf (.I(SYS_CLK), .O(sysclk));
	BUFG sysclk_bufg (.I(sysclk), .O(clk100));


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
			 READY : if(flg) state <= START;
			 START : if(light) state <= STOP;
			 STOP  : state <= IDLE;
		 endcase
	 end
 end

 /* Counter */
 reg [27:0] cnt;
 reg [27:0] dcnt;
 reg led_r;
 assign REDLED = led_r;
 always @ (posedge clk100)
   if(~RSTBTN_)begin
		 cnt  <= 28'd0;
		 dcnt <= 28'd0;
		 flg  <= 1'b0;
		 led_r <= 1'b0;
	 end else begin
	   if(state == IDLE)begin
		   cnt <= 28'd0;
			 flg <= 1'b0;
		   led_r <= 1'b0;
		 end
	   if(state == READY)begin
		   led_r <= 1'b0;
		   if(cnt == 28'd100000000)begin
				 flg <= 1'b1;
				 cnt <= 28'd0;
			 end else
			   cnt <= cnt + 28'd1;
		 end
		 if(state == START)begin
		   led_r <= 1'b1;
			 flg  <= 1'b0;
			 cnt  <= cnt + 28'd1;
			 dcnt <= 28'd0;
		 end
		 if(state == STOP)begin
		   led_r <= 1'b0;
			 dcnt <= cnt;
		 end
   end

  
	always @ (*) begin
		case(swled)
		  2'b00 : LED <= dcnt[7:0];
		  2'b01 : LED <= dcnt[15:8];
		  2'b10 : LED <= dcnt[23:16];
		  2'b11 : LED <= {state,1'd0,dcnt[27:24]};
		endcase
	end
 
endmodule