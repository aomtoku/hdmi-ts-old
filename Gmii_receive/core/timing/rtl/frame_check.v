`timescale 1 ns / 1 ps

module frame_check(
	input wire clk100m,
	input wire clk125m,
	input wire reset,
	input wire fifo_wr_en,
	input wire [28:0]din,
	input wire [1:0]sw,
	input wire [7:0]dipsw,
	output wire [7:0]signal,
	output wire [15:0]error_q,
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
			y_din_q 	<= din[26:16]; 
			if(y_din_q < y_din_qq)begin
				frame_cnt  <= frame_cnt + 8'd1;
			end
	end
end


reg empty;
reg [28:0]next;
reg [10:0]pcnt;
reg lerror;
reg [1:0]state;
reg [15:0]ecnt;
assign error_q = ecnt;

parameter IDLE = 2'b00;
parameter WAIT = 2'b10;
parameter COMP = 2'b11; 

always@(posedge clk125m)begin
	if(reset)begin
		next <= 29'd0;
		empty <= 1'd1;
		lerror <= 1'b0;
		pcnt <= 11'd0;
		ecnt <= 16'd0;
		state <= IDLE;
	end else
		if(fifo_wr_en)
			case(state)
				IDLE : state <= WAIT;
				WAIT : begin
							if(din[26:16] == 11'd719 && pcnt == 11'd1279)begin
								next[26:16] <= 11'd0;
								next[7] <= 1'b0;
								state <= COMP;
								pcnt <= 11'd0;
							end else if(din[26:16] == 11'd719)
								pcnt <= pcnt + 11'd1;
						 end
				COMP : begin
							//CHECK
							if(next[7] != din[7])
								ecnt <= ecnt + 16'd1;
							// Counting
							if(pcnt == 11'd639)
								next[7] <= 1'b1;
							if(pcnt == 11'd1279)begin
								pcnt <= 11'd0;
								next[7] <= 1'b0;
								if(next[26:16] == 11'd719)
									next[26:16] <= 11'd0;
								else
									next[26:16] <= next[26:16] + 11'd1;
							end else
								pcnt <= pcnt + 11'd1;
							if(next[26:16] != din[26:16])begin
								state <= WAIT;
								lerror <= 1'b1;
							end
						end
			endcase
end


assign signal[7:0] = frame_cnt_q[7:0];

endmodule
