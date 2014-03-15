/**************************************************************
 *   Data Decoder like adpcm
 *      by Yuta TOKUSASHI
 * ***********************************************************/

module dc_adpcm(
  input  wire        clk,     // System clock
  input  wire        rst,     // System Reset 
  input  wire        in_en,   // Input Enable Signal
  input  wire [15:0] din,     // Encoded Data(input)
  output wire        out_en,  // Output Enable signal 1 clock sycle delay
  output wire [15:0] dout     // Decoded Data(output)
);

reg        eo;
reg [15:0] bp;
reg [15:0] y,cbcr;
reg [15:0] out;
reg        oen;
wire [7:0] yin  = din[7:0 ]; 
wire [7:0] rbin = din[15:8];
wire [7:0] ybp  = bp [7:0 ];
wire [7:0] rbbp = bp [15:8];

wire [15:0]yout = (~eo) ? {cbcr[7:0], y[7:0]} : out;

assign dout = (oen) ? yout : 16'd0;
assign out_en = oen;

always@(posedge clk)
  if(~in_en)
		eo <= 1'b0;
	else
		eo <= ~eo;



always@(posedge clk)begin
  if(rst)begin
	  bp   <= 16'd0;
	  y    <= 16'd0;
	  cbcr <= 16'd0;
	  out  <= 16'd0;
  end else begin
    oen <= in_en;
	  bp <= din;
	  if(eo)begin
			if(din[3]) // Adactive Differencial Value 
			  y  <= {8'd0,bp[7:0]} + ({13'd0,din[2:0]} * 16'd254 / 16'd8);
			else
			  y  <= {8'd0,bp[7:0]} - ({13'd0,din[2:0]} * 16'd254 / 16'd8);
			if(din[7])
			  cbcr  <= {8'd0,bp[15:8]} + ({13'd0,din[6:4]} * 16'd254 / 16'd8);
			else
			  cbcr  <= {8'd0,bp[15:8]} - ({13'd0,din[6:4]} * 16'd254 / 16'd8);
	  end else begin // Non compressing Data
      out <= din;
    end
  end
end

endmodule
