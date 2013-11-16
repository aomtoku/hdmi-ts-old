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
module apple_out(
  input            i_clk_74M, //74.25 MHZ pixel clock
  input            i_rst,   
  input            baronly, //output only 75% color bar 
  input [1:0]      i_format,
  input [11:0]     i_vcnt, //vertical counter from video timing generator
  input [11:0]     i_hcnt, //horizontal counter from video timing generator

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

///////////////////////////////////////////////////////////
// There are total 4 vertical and 17 horizontal regions
///////////////////////////////////////////////////////////
/*
reg [16:0] Hregion;
reg [3:0]  Vregion;

parameter VRGN1 = 4'd0;
parameter VRGN2 = 4'd1;
parameter VRGN3 = 4'd2;
parameter VRGN4 = 4'd3;

parameter HRGN1   = 17'd0;
parameter HRGN2   = 17'd1;
parameter HRGN3   = 17'd2;
parameter HRGN4   = 17'd3;
parameter HRGN5   = 17'd4;
parameter HRGN6   = 17'd5;
parameter HRGN7   = 17'd6;
parameter HRGN8   = 17'd7;
parameter HRGN9   = 17'd8;
parameter HRGN10  = 17'd9;
parameter HRGN11  = 17'd10;
parameter HRGN12  = 17'd11;
parameter HRGN13  = 17'd12;
parameter HRGN14  = 17'd13;
parameter HRGN15  = 17'd14;
parameter HRGN16  = 17'd15;
parameter HRGN17  = 17'd16;
*/
///////////////////////////////////////////////////////////
// Define Vertical and Horizontal regions
///////////////////////////////////////////////////////////
/*
wire [11:0] vbar1bgn, vbar1bgn2;
wire [11:0] vbar2bgn, vbar2bgn2;
wire [11:0] vbar3bgn, vbar3bgn2;
wire [11:0] vbar4bgn, vbar4bgn2;

wire [11:0] hbar1bgn;
wire [11:0] hbar2bgn;
wire [11:0] hbar3bgn;
wire [11:0] hbar4bgn;
wire [11:0] hbar5bgn;
wire [11:0] hbar6bgn;
wire [11:0] hbar7bgn;
wire [11:0] hbar8bgn;
wire [11:0] hbar9bgn;
wire [11:0] hbar10bgn;
wire [11:0] hbar11bgn;
wire [11:0] hbar12bgn;
wire [11:0] hbar13bgn;
wire [11:0] hbar14bgn;
wire [11:0] hbar15bgn;
wire [11:0] hbar16bgn;
wire [11:0] hbar17bgn;
*/
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

wire [23:0]data;
reg [16:0]addr;

blk_mem_gen_v4_3 ramout(
	.clka(i_clk_74M),
	.wea(0),
	.addra(addr),
	.dina(),
	.douta(data)
);

parameter V_SIZE = 240;
parameter H_SIZE = 320;

parameter V_DATA = 20;
parameter H_DATA = 20;
parameter WHITE = 100;

reg VSYNC;
/*
always @ (posedge i_clk_74M)
begin
  if (i_rst) begin
    //Vregion <= 4'h0;
  end else begin
		case(i_vcnt)
		   25: begin
					VSYNC <= 1;
					v_color <= 1;
				 end
			265: v_color <= 0;
         745: VSYNC <= 0;
      endcase
  end
end
*/


always @ (posedge i_clk_74M)
begin
  if (i_rst) begin
    //Vregion <= 4'h0;
  end else begin
		case(i_vcnt)
		   0: begin
					VSYNC <= 1;
					v_color <= 1;
				 end
			240: v_color <= 0;
         720: VSYNC <= 0;
      endcase
  end
end

reg h_color;
reg v_color;

assign o_b = (h_color == 1 && v_color == 1) ? data[7:0] : 8'b11111111;
assign o_g = (h_color == 1 && v_color == 1) ? data[15:8] : 8'b11111111;
assign o_r = (h_color == 1 && v_color == 1) ? data[23:16] : 8'b11111111;

always @ (posedge i_clk_74M)
begin
  if(i_rst) begin
    //Hregion <= 17'h0;
  end else begin
      if(i_hcnt >= 0 && i_hcnt <= 1279)begin
			if(i_hcnt >= 0 && i_hcnt <= 319)begin
			     if(VSYNC) begin
						addr <= addr +1;
						h_color <= 1;
					end
			end else begin
					if(VSYNC) begin
						h_color <= 0;
					end
			 end
						
      end else if(i_hcnt == 1280 && i_vcnt == 720)begin
						addr <= 0;
		end
	end
end

/*
always @ (posedge i_clk_74M)
begin
  if(i_rst) begin
    o_r <= Lvl_0;
    o_g <= Lvl_0;
    o_b <= Lvl_0;
  end else
    case (Vregion)
		V_DATA : begin
			case (Hregion)
				H_DATA : begin
					addr <= addr + 1;
					o_r <= data[7:0];
					o_g <= data[15:8];
					o_b <= data[23:16];
				end
				WHITE : begin
				   addr <= addr + 1;
					o_r <= 8'b11111111;
					o_g <= 8'b11111111;
					o_b <= 8'b11111111;
				end
			endcase
		end
		
		WHITE : begin
		   addr <= addr + 1;
			o_r <= 8'b11111111;
			o_g <= 8'b11111111;
			o_b <= 8'b11111111;
		end

      default: begin
        o_r <= Lvl_0;
        o_g <= Lvl_0;
        o_b <= Lvl_0;
      end
    endcase
end
*/
endmodule
