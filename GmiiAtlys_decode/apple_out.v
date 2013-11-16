//------------------------------------------------------------------------------ 
// Copyright (c) 2007 Xilinx, Inc. 
// All Rights Reserved 
//------------------------------------------------------------------------------ 
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /   Vendor: Xilinx 
// \   \   \/    Author: Bob Feng, General Product Division, Xilinx, Inc.
//  \   \        Filename: $RCSfile: hdclrbar.v,v $
//  /   /        Date Last Modified:  $Date: 2010/08/25 00:37:39 $
// /___/   /\    Date Created: July 26, 2007
// \   \  /  \ 
//  \___\/\___\ 
// 
//------------------------------------------------------------------------------ 
/*
This video pattern generator will generate color bars for the 18 video standards
currently supported by the SMPTE 292M (HD-SDI) video standard. The color bars 
comply with SMPTE RP-219 standard color bars, as shown below. This module can
also generate the SMPTE RP-198 HD-SDI checkfield test pattern and 75% color
bars.

|<-------------------------------------- a ------------------------------------->|
|                                                                                |
|        |<----------------------------(3/4)a-------------------------->|        |
|        |                                                              |        |
|   d    |    c        c        c        c        c        c        c   |   d    |
+--------+--------+--------+--------+--------+--------+--------+--------+--------+ - - - - -
|        |        |        |        |        |        |        |        |        |   ^     ^
|        |        |        |        |        |        |        |        |        |   |     |
|        |        |        |        |        |        |        |        |        |   |     |
|        |        |        |        |        |        |        |        |        |   |     |
|        |        |        |        |        |        |        |        |        | (7/12)b |
|  40%   |  75%   | YELLOW |  CYAN  |  GREEN | MAGENTA|   RED  |  BLUE  |  40%   |   |     |
|  GRAY  | WHITE  |        |        |        |        |        |        |  GRAY  |   |     |
|   *1   |        |        |        |        |        |        |        |   *1   |   |     b
|        |        |        |        |        |        |        |        |        |   |     |
|        |        |        |        |        |        |        |        |        |   |     |
|        |        |        |        |        |        |        |        |        |   v     |
+--------+--------+--------+--------+--------+--------+--------+--------+--------+ - - -   |
|100%CYAN|  *2    |                   75% WHITE                         |100%BLUE| (1/12)b |
+--------+--------+-----------------------------------------------------+--------+ - - -   |
|100%YELO|  *3    |                    Y-RAMP                           |100% RED| (1/12)b |
+--------+--------+---+-----------------+-------+--+--+--+--+--+--------+--------+ - - -   |
|        |            |                 |       |  |  |  |  |  |        |        |         |
|  15%   |     0%     |       100%      |  0%   |BL|BL|BL|BL|BL|    0%  |  15%   | (3/12)b |
|  GRAY  |    BLACK   |      WHITE      | BLACK |K-|K |K+|K |K+|  BLACK |  GRAY  |         |
|   *4   |            |                 |       |2%|0%|2%|0%|4%|        |   *4   |         v
+--------+------------+-----------------+-------+--+--+--+--+--+--------+--------+ - - - - -
    d        (3/2)c            2c        (5/6)c  c  c  c  c  c      c       d
                                                 -  -  -  -  -
                                                 3  3  3  3  3

*1: The block marked *1 is 40% Gray for a default value. This value may 
optionally be set to any other value in accordance with the operational 
requirements of the user.    
    
*2: In the block marked *2, the user may select 75% White, 100% White, +I, or
-I.

*3: In the block marked *3, the user may select either 0% Black, or +Q. When the
-I value is selected for the block marked *2, then the +Q signal must be
selected for the *3 block.

*4: The block marked *4 is 15% Gray for a default value. This value may
optionally be set to any other value in accordance with the operational
requirements of the user.

 

*/
module apple_out_gmii(
  input            i_clk_74M, //74.25 MHZ pixel clock
  input		   i_clk_125M,
  input            i_rst,   
  input [1:0]      i_format,
  input [11:0]     i_vcnt, //vertical counter from video timing generator
  input [11:0]     i_hcnt, //horizontal counter from video timing generator
  input  wire		rx_dv,
  input  wire[7:0] rxd,
  
  output	wire[7:0] txd,
  output	wire		tx_en,
  input 				gtxclk,
  //output wire[3:0]	LED,
  input	wire[1:0]	SW,

  output wire[7:0]  o_r,
  output wire[7:0]  o_g,
  output wire[7:0]  o_b
);
/*
parameter  Lvl_100   = 8'd255;
parameter  Lvl_75    = 8'd191;
parameter  Lvl_40    = 8'd102;
parameter  Lvl_15    = 8'd38;
parameter  Lvl_4     = 8'd10;
parameter  Lvl_2     = 8'd5;
parameter  Lvl_0     = 8'd0;
parameter  Lvl_2n    = 8'd5;
parameter  I_R       = 8'd0; // -I signal
parameter  Q_R       = 8'd65;// +Q signal
parameter  I_G       = 8'd63;
parameter  Q_G       = 8'd0; 
parameter  I_B       = 8'd105;
parameter  Q_B       = 8'd120;
*/

reg [1:0] i_format_sync, i_format_q;
always @ (posedge i_clk_74M) begin
  i_format_sync <= i_format_q;
  i_format_q <= i_format;
end

wire interlace = i_format_sync[1]; //0-progressive 1-interlace
wire hdtype = i_format_sync[0]; //0-720 1-1080

//--------------------------------
//
// TODO
//  ・GMIIのmoduleをここにインスタンスする
//  ・トップモジュールでGMII用に125MHzをつくり�//  ここにもってくる�//
//--------------------------------
wire [47:0]data;
wire [13:0]r_count;
wire [13:0]w_count;
wire [47:0]din;
wire rx_en;
wire read_en;
wire empty;

fifo_gen48 fifo48(
	.rst(i_rst),
	.wr_clk(i_clk_125M),
	.rd_clk(i_clk_74M),
	.din(din),
	.wr_en(rx_en),
	.rd_en(read_en),
	.dout(data),
	.full(),
	.empty(empty),
	.rd_data_count(r_count),
	.wr_data_count(w_count));

gmii2fifo24 gmii2fifo24(
   .clk125(i_clk_125M),
	.sys_rst(i_rst),
	.rxd(rxd),
	.rx_dv(rx_dv),
	.datain(din),
	.recv_en(rx_en),
	.txd(txd),
	.tx_en(tx_en),
	.tx_clk(gtxclk)
	//.LED(LED),
	//.SW(SW)
);
//--------------------------------
parameter V_SIZE = 240;
parameter H_SIZE = 320;

parameter V_DATA = 20;
parameter H_DATA = 20;
parameter WHITE = 100;

reg VSYNC;

always @ (posedge i_clk_74M)
begin
  if (i_rst) begin
	v_color <= 0;
  end else 
  	if(i_vcnt)begin
		case(i_vcnt)
		   0: begin
			VSYNC <= 1;
			v_color <= 1;
		      end
                 720: begin
		 	VSYNC <= 0;
			v_color <= 0;
		      end
      		endcase
  end
end

reg h_color;
reg v_color;

wire [11:0] x_res;
wire [11:0] y_res;

assign o_b = (h_color == 1 && v_color == 1) ? data[7:0] : 8'b11111111;
assign o_g = (h_color == 1 && v_color == 1) ? data[15:8] : 8'b11111111;
assign o_r = (h_color == 1 && v_color == 1) ? data[23:16] : 8'b11111111;

assign x_res = data[35:24];
assign y_res = data[47:36];

reg  sync = 0;

//----------------------------------------------------
//   Sync with FIFO
//----------------------------------------------------
//only first
//assign read_en = (h_color == 1'b1 && v_color == 1'b1 && sync == 1'b1) ? h_color : 1'b0;
assign read_en = (h_color==1 && v_color == 1) ? 1'b1 : 1'b0;

always @(posedge i_clk_74M)begin
	if(i_rst) begin
		//read_en <= 1;
		sync <= 0;	
	end else begin
		if(sync == 0)begin
			if(i_hcnt == x_res && i_vcnt == y_res)begin
				//read_en <= 1'b1;
				sync <= 1'b1;
			end else begin
				//read_en <= 1'b0;
				sync <= 0;
			end
		end else  //sync == 1�̂Ƃ�  
			if(x_res == i_hcnt && i_vcnt == y_res)begin
				//read_en <= 1'b1;
			end else begin
				//read_en <= 1'b0;
				sync <= 1'b0;
			end
	end
end

//`define debug_switch
`ifdef debug_switch
///wire busy;
/*wire  [2:0] sws_sync; //synchronous output
reg [2:0] sws_sync_q;
always @ (posedge i_clk_74M)begin
    sws_sync_q <= sws_sync;
end
*/
  //wire sw0_rdy, sw1_rdy, sw2_rdy, sw3_rdy;

  /*synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_4 (.async(SW[3]),.sync(sws_sync[3]),.clk(i_clk_74M));*/
/*  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_5 (.async(SW[2]),.sync(sws_sync[2]),.clk(i_clk_74M));
  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_6 (.async(SW[1]),.sync(sws_sync[1]),.clk(i_clk_74M));
  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_7 (.async(SW[0]),.sync(sws_sync[0]),.clk(i_clk_74M));
  */
/*  
  reg switch = 1'b0;
  always @ (posedge i_clk_74M)
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
*/

assign LED = dataout(
							.SW(SW), 
							.sync(sync),
							.read(read_en),
							.empty(empty),
							.data(x_res)
);

function [3:0]dataout;
input [1:0]SW;
input sync;
input read;
input empty;
input [11:0]data;
begin
	case(SW)
		2'b00: dataout = {1'b0,empty,read,sync};
		2'b01: dataout = data[3:0];
		2'b10: dataout = data[7:4];
		2'b11: dataout = data[11:8];
	endcase
end
endfunction
`endif

//------------------------------------------------------------
//  Determine the Data Space or  Blank Space
//------------------------------------------------------------
always @ (posedge i_clk_74M) begin
  if(i_rst) begin
    //h_color <= 0;
  end else begin
      if(i_hcnt >= 0 && i_hcnt <= 1279)begin
			if(i_hcnt >= 0 && i_hcnt <= 719)begin
			     if(VSYNC /*&& sync*/) begin
						h_color <= 1;
					end 
			end else begin
					if(VSYNC) begin
						h_color <= 0;
					end
			 end
      end else if(i_hcnt == 1280 && i_vcnt == 720)begin
			h_color <= 0;
		end
	end
end

endmodule
