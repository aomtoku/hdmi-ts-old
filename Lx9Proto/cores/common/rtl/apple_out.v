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

reg [1:0] i_format_sync, i_format_q;

always @ (posedge i_clk_74M) begin
  i_format_sync <= i_format_q;
  i_format_q    <= i_format;
end

wire        interlace = i_format_sync[1]; //0-progressive 1-interlace
wire        hdtype    = i_format_sync[0]; //0-720 1-1080
wire [23:0] data;
reg  [16:0] addr;

ram_out ramout(
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
parameter WHITE  = 100;

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
					VSYNC     <= 1;
					v_color   <= 1;
				 end
			240: v_color  <= 0;
      720: VSYNC    <= 0;
      endcase
  end
end

reg h_color;
reg v_color;

assign o_b = (h_color == 1 && v_color == 1) ? data[7:0]   : 8'b11111111;
assign o_g = (h_color == 1 && v_color == 1) ? data[15:8]  : 8'b11111111;
assign o_r = (h_color == 1 && v_color == 1) ? data[23:16] : 8'b11111111;

always @ (posedge i_clk_74M)
begin
  if(i_rst) begin
    //Hregion <= 17'h0;
  end else begin
      if(i_hcnt >= 0 && i_hcnt <= 1279)begin
			if(i_hcnt >= 0 && i_hcnt <= 319)begin
			     if(VSYNC) begin
						addr    <= addr +1;
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

endmodule
