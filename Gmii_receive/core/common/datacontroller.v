module datacontroller # (
  parameter empty_interval = 21'd1237500
)(
  input wire        i_clk_74M, //74.25 MHZ pixel clock
  input wire        i_rst,   
  input wire [1:0]  i_format,
  input wire [11:0] i_vcnt, //vertical counter from video timing generator
  input wire [11:0] i_hcnt, //horizontal counter from video timing generator
  output wire  fifo_read,
  input wire [28:0] data,
  input wire 		  sw,
  
  output [7:0]  o_r,
  output [7:0]  o_g,
  output [7:0]  o_b
);
wire [1:0] x_count;
wire [10:0] y_count;
assign x_count = data[28:27];
assign y_count = data[26:16];

//`define CLIP(X) ( (X) > 16'd255 ? 16'd255 : (X) < 16'd0 ? 16'd0 : X)
// YCbCr -> RGB
//`define CYCbCr2B(Y, Cb, Cr) CLIP( Y + (116129 * Cb >> 16 ) - 226 )
//`define CYCbCr2G(Y, Cb, Cr) CLIP( Y - (( 22544 * Cb + 46793 * Cr ) >> 16) + 135)
//`define CYCbCr2R(Y, Cb, Cr) CLIP( Y + ( 91881 * Cr >> 16 ) - 179 )


/*
reg [1:0] i_format_sync, i_format_q;
always @ (posedge i_clk_74M) begin
  i_format_sync <= i_format_q;
  i_format_q <= i_format;
end

wire interlace = i_format_sync[1]; //0-progressive 1-interlace
wire hdtype = i_format_sync[0]; //0-720 1-1080
*/

//------------------------------------------------------------
//  Determine the Data Space or  Blank Space
//------------------------------------------------------------
`ifndef NO
parameter hstart = 12'd1;
parameter hfin	 = 12'd1281;
parameter vstart = 12'd24;
parameter vfin	 = 12'd745;
`else
parameter hstart = 12'd1;
parameter hfin	 = 12'd1281;
parameter vstart = 12'd25;
parameter vfin	 = 12'd745;
`endif

reg hactive,vactive;
reg xblock;
reg [18:0] Y, Cb, Cr, a_r, a_g, a_b;

always @ (posedge i_clk_74M) begin
	if(i_rst) begin
	    hactive  <= 1'b0;
	    vactive  <= 1'b0;
            a_r      <= 8'h00;
            a_g      <= 8'h00;
            a_b      <= 8'h00;
	    xblock   <= 1'b0;
	end else begin
			if(i_hcnt == hstart) begin
					hactive <= 1'b1;
					xblock  <= 1'b0;
			end
			if(i_hcnt == (hstart + 640)) begin
					xblock  <= 1'b1;
			end
			if(i_hcnt == hfin) 
					hactive <= 1'b0;
		
			if(i_vcnt == vstart) 
					vactive <= 1'b1;
			if(i_vcnt == vfin) 
					vactive <= 1'b0;
			if (hactive & vactive) begin
				Y <= {11'b0,data[15:8]};
				if (i_hcnt[0] == 1'b0)
					Cr <= {11'b0, data[7:0]};
				else
					Cb <= {11'b0, data[7:0]};
				if(sw)begin
					if (x_count[0] == xblock) begin
						a_r <= ( (Y<<8) + (19'd359*Cr) - 19'd45952)>>8;
						a_g <= ((Y<<8) + 19'd34688 - 19'd183*Cr - 19'd88*Cb )>>8;
						a_b <= ( (Y << 8) + (19'd454*Cb) - 19'd58112)>>8;
//						a_b <= data[7:0];
//						a_g <= data[15:8];
//						a_r <= 8'b0;
					end else begin
						a_b <= 8'h0;
						a_g <= 8'h0;
						a_r <= 8'h0;
					end
				end else begin
					a_b <= i_hcnt[9:2];
					a_g <= i_vcnt[8:1];
					a_r <= 8'h0;
				end
			end else begin
				a_b <= 8'h00;
				a_g <= 8'h00;
				a_r <= 8'h00;
			end
	end
end

assign fifo_read = (hactive & vactive);
assign o_r = a_r[7:0];
assign o_g = a_g[7:0];
assign o_b = a_b[7:0];

endmodule
