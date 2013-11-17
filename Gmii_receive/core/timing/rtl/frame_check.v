`timescale 1 ns / 1 ps

module frame_check(
	input wire clk125m,
	input wire reset,
	input wire fifo_wr_en,
	input wire [28:0] din,
	input wire [2:0] sw,
	output wire [7:0] led,
);

reg  [28:0] din_q;
wire [10:0] din_y, din_q_y;
wire [1:0]  din_x, din_q_x;
wire [15:0] din_data, din_q_data;
assign din_x      = din[28:27];
assign din_y      = din[26:16];
assign din_data   = din[15: 0];
assign din_q_x    = din_q[28:27];
assign din_q_y    = din_q[26:16];
assign din_q_data = din_q[15: 0];

parameter INIT  = 2'h0;
parameter WAIT  = 2'h1;
parameter CHECK = 2'h2;
reg [1:0] state = IDLE;
reg [10:0] count;
reg [1:0]  next_x;
reg [10:0] next_y;
reg skip1 = 1'b0;

reg [28:0] led_din, led_din_q;
reg [10:0] led_count;

always@(posedge clk125m)begin
	if(reset)begin
		din_q <= 28'b0;
		count <= 11'h0;
		skip1 <= 1'b0;
		state <= INIT;
	end else begin
		if (fifo_wr_en == 1'b1) begin
			din_q <= din;
			case (state)
				INIT: begin
					state <= WAIT;
				end
				WAIT: begin
					if ( {din_x,din_y} != {din_q_x,din_q_y} )	// if din_xy != din_q_xy then CHECK
						state <= CHECK;
					skip1 <= 1'b1;
					count <= 11'd0;
				end
				CHECK: begin
					skip1 <= 1'b0;
					if ((( din_x != next_x ) || ( din_y != next_y )) && skip1 == 1'b0) begin
						led_din   <= din;
						led_din_q <= din_q;
						led_count <= count;
					end
					if (count != 11'd640) begin
						count <= count + 11'd1;
						next_x <= din_x;
						next_y <= din_y;
					end else begin
						count <= 11'd0;
						if (din_x == 1'b1) begin
							if (din_y != 11'd719)
								next_y <= din_y + 11'd1;
							else
								next_y <= 11'd0;
						end
						next_x <= !din_x;
					end
				end
			endcase
		end
	end
end

assign led =	 (sw[2:0] == 3'h0) ? led_din  [23:16] :
		 (sw[2:0] == 3'h1) ? led_din  [28:24] :
		 (sw[2:0] == 3'h2) ? led_din_q[23:16] :
		 (sw[2:0] == 3'h3) ? led_din_q[28:24] :
		 (sw[2:0] == 3'h4) ? led_count[ 7: 0] :
		 (sw[2:0] == 3'h5) ? led_count[10: 8] ;

endmodule
