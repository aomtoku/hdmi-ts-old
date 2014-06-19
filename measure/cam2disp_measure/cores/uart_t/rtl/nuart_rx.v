module nuart_rx(clk_i, x16clk_i, rst_n_i, fifo_wr_o, fifo_data_o, rxd_i);
	input clk_i; 
	input x16clk_i; //x16 clock for RS232C
	input rst_n_i; 
	output fifo_wr_o; 
	output [7:0] fifo_data_o; 
	input rxd_i;

	reg [1:0] rxd_r;
	wire 			rxd_fall;

	reg [3:0] x16cnt_r;
	reg 			sampling_timing_r;
	reg 			fifo_wr_r;
	reg [7:0] rx_buf_r;
	
	reg [3:0] state;
	parameter IDLE_STATE = 0, START_BIT_STATE = 1, RX_STATE = 2, FIFO_WR_STATE = 3, END_STATE = 4;
	wire 			rx_in;
	reg [3:0] rx_cnt_r;
	
	always @ (posedge clk_i or negedge rst_n_i)begin
		if(rst_n_i == 0)begin
			fifo_wr_r <= 0;
			state <= IDLE_STATE;
		end else begin
			case(state)
				IDLE_STATE:begin
					fifo_wr_r <= 0;
					rx_buf_r <= 0;
					rx_cnt_r <= 0;
					if(rxd_fall)begin
						state <= START_BIT_STATE;
					end
				end
				START_BIT_STATE:begin
					if(sampling_timing_r)begin
						if(rx_in)begin  // no start bit
							state <= IDLE_STATE;
						end else begin
							state <= RX_STATE;
						end
					end
				end
				RX_STATE:begin
					if(sampling_timing_r)begin
						rx_buf_r <= {rx_buf_r[6:0], rx_in};
						rx_cnt_r <= rx_cnt_r + 1;
						if(rx_cnt_r == 7)begin
							state <= FIFO_WR_STATE;
						end
					end
				end
				FIFO_WR_STATE:begin
					fifo_wr_r <= 1;
					state <= END_STATE;
				end
				END_STATE:begin
					fifo_wr_r <= 0;
					state <= IDLE_STATE;
				end
			endcase // case(state)
		end
	end


	// fall detect
	assign 		rxd_fall = rxd_r[1] & !rxd_r[0];
	assign 		rx_in = rxd_r[1];
	always @ (posedge clk_i or negedge rst_n_i)begin
		if(rst_n_i == 0)begin
			rxd_r <= 2'b11;
		end else begin
			rxd_r <= {rxd_r[0], rxd_i};
		end
	end

	//adjust sampling timing
	always @ (posedge clk_i or negedge rst_n_i)begin
		if(rst_n_i == 0)begin
			x16cnt_r <= 0;
		end else begin
			if((state == IDLE_STATE) && rxd_fall)begin
				x16cnt_r <= 8;  // adjust
			end else if(x16clk_i)begin
				x16cnt_r <= x16cnt_r + 1;  // expect overflow
			end
		end
	end

	always @ (posedge clk_i or negedge rst_n_i)begin
		if(rst_n_i == 0)begin
			sampling_timing_r <= 0;
		end else begin
			sampling_timing_r <= (x16clk_i && x16cnt_r == 0) ? 1 : 0;
		end
	end

	assign fifo_data_o = rx_buf_r;
	assign fifo_wr_o = fifo_wr_r;
	
endmodule
						 