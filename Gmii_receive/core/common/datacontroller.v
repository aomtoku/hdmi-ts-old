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
  
  output reg [7:0]  o_r,
  output reg [7:0]  o_g,
  output reg [7:0]  o_b
);
wire [1:0] x_count;
wire [10:0] y_count;
assign x_count = data[28:27];
assign y_count = data[26:16];


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

always @ (posedge i_clk_74M) begin
	if(i_rst) begin
	    hactive  <= 1'b0;
	    vactive  <= 1'b0;
            o_r      <= 8'h00;
            o_g      <= 8'h00;
            o_b      <= 8'h00;
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
				if(sw)begin
					if (x_count[0] == xblock) begin
						o_b <= data[7:0];
						o_g <= data[15:8];
						o_r <= 8'b0;
					end else begin
						o_b <= 8'h0;
						o_g <= 8'h0;
						o_r <= 8'h0;
					end
				end else begin
					o_b <= i_hcnt[9:2];
					o_g <= i_vcnt[8:1];
					o_r <= 8'h0;
				end
			end else begin
				o_b <= 8'h00;
				o_g <= 8'h00;
				o_r <= 8'h00;
			end
	end
end

assign fifo_read = (hactive & vactive);

endmodule
