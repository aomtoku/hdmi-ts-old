/**************************************************************
 *   Data Encoder like adpcm
 *      by Yuta TOKUSASHI
 * ***********************************************************/

module en_adpcm(
  input  wire        clk,     // System Clock
  input  wire        rst,     // System Reset
  input  wire        eo,      // Even bit, Odd bit
  input  wire        in_en,   // Input Enable Signal
  input  wire [15:0] din,     // Decoded data(input)
  output wire        out_en,  // Output Enable Signal
  output wire [15:0] dout     // Encoded Data(output)
);

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
      if(yin > ybp)
        y    <= (({8'd0,yin} - {8'd0,ybp}) * 8 + 127)/254;
      else
        y    <= (({8'd0,ybp} - {8'd0,yin}) * 8 + 127)/254;
      if(rbin > rbbp)
        cbcr <= (({8'd0,rbin} - {8'd0,rbbp}) * 8 + 127)/254;
      else
		cbcr <= (({8'd0,rbbp} - {8'd0,rbin}) * 8 + 127)/254;
	end else begin
      out <= din;
    end
  end
end

endmodule
