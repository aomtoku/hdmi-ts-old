`timescale 1 ns / 1 ps

module frame_check(
	input wire clk100m,
	input wire clk125m,
	input wire reset,
	input wire fifo_wr_en,
	input wire [10:0]y_din,
	input wire [1:0]x_din,
	input wire [7:0]din1,
	input wire [7:0]din2,
	input wire [1:0]sw,
	input wire [7:0]dipsw,
	output wire [7:0]signal,
	output wire [10:0]error_q,
	output wire frame
);


reg [10:0]y_din_q,y_din_qq;
reg [7:0]frame_cnt,frame_cnt_q;
reg over,over_q;
assign frame = frame_cnt[0];

always@(posedge clk125m)begin
	if(reset)begin
	    y_din_q 	<= 11'b0;
	    y_din_qq 	<= 11'b0;
	end else begin
		y_din_qq <= y_din_q;
		if(fifo_wr_en)
			y_din_q 	<= y_din; 
			if(y_din_q < y_din_qq)begin
				frame_cnt  <= frame_cnt + 8'd1;
			end
	end
end

reg [10:0]error,error_buf;
reg right;
reg [3:0]yc; // same ydin?
reg xc;
wire err = (yc > 2'd1);
assign error_q = error_buf;
always@(posedge clk125m)begin
	if(reset)begin
	    error 	<= 11'b0;
	end else begin
		if(fifo_wr_en)
			if(y_din != y_din_q)begin
				yc <= 4'd0;
				if(y_din == 0 && y_din_q == 11'd719)begin
					right <= 1'd0;
					error <= 11'd0;
					error_buf <= error;
				end else if(y_din_q + 11'd1 == y_din && y_din <= 11'd719)
					right <= 1'd1;
				else
					error <= error + 11'd1;
			end else if(y_din == y_din_q)begin
				yc <= yc + 4'd1;
				if(x_din[0] ==  1'b1)
					xc <= 1;
				else if(x_din[0] == 1)
					xc <= 0;
			end
	end
end


assign signal[7:0] = frame_cnt_q[7:0];

endmodule
