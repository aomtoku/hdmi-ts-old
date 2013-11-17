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
reg error_pos;
assign error_q = error_buf;
reg empty;
reg [28:0]next;
reg [9:0]pcnt;
reg [1:0]state;
reg [15:0]ecnt;

parameter IDLE = 2'b00;
parameter WAIT = 2'b10;
parameter COMP = 2'b11; 

always@(posedge clk125m)begin
	if(reset)begin
		next <= 29'd0;
		empty <= 1'd1;
		pcnt <= 10'd0;
		ecnt <= 16'd0;
		state <= IDLE;
	end else
		if(fifo_wr_en)
			case(state)
				IDLE : state <= WAIT;
				WAIT : begin
							if(y_din == 11'd719 && pcnt == 1279)begin
								state <= COMP;
								pcnt <= 10'd0;
							end else if(y_din == 11'd719)
								pcnt <= pcnt + 10'd1;
						 end
				COMP : begin
						//CHECK
							if(next[7] == din1[7])
								next[7] <= ~din1[7];
							else begin
								ecnt <= ecnt + 16'd1;
								state <= WAIT;
							end
						// Count
							if(pcnt == 10'd639)begin
								pcnt <= 10'd0;
								if(next[26:16] == 11'd719)
									next[26:16] <= 11'd0;
								else
									next[26:16] <= next[26:16] + 11'd1;
							end else
								pcnt <= pcnt + 10'd1;
							if(next[26:16] != y_din)begin
								state <= 2'b10;
								error;
							end
						end
			endcase
			
			//
			// Not Empty
			//
			/*if(~empty)begin
				if(y_din == next[26:16])
					if(x_din[0] == next[27] && x_din[0] == 1)begin
						next[27] <=  1'd0;
						if(next[26:16] == 11'd719)
							next[26:16] <= 11'd0;
						else
							next[26:16] <= next[26:16] + 11'd1;
					end else if(x_din[0] == next[27] && x_din[0] == 0)
						next[27] <=  1'd1;
				else begin
					error_buf <= next;
					error_pos <= 1'd1;
				end
			end else begin
				//
				// EMPTY 
				//
				emtpy <= 1'd0;
				if(x_din[0] == 1)begin
					next[27] <=  1'd0;
					if(next[26:16] == 11'd719)
						next[26:16] <= 11'd0;
					else
						next[26:16] <= next[26:16] + 11'd1;
				end else if(x_din[0] == 0)begin
					next[27] <=  1'd1;
					if(next[26:16] == 11'd719)
						next[26:16] <= 11'd0;
					else
						next[26:16] <= next[26:16] + 11'd1;
				end
			end*/
end


assign signal[7:0] = frame_cnt_q[7:0];

endmodule
