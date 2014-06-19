module nuart_tx(clk_i, rst_n_i, tx_timing_i, txd_o, fifo_rd_o, fifo_data_i, fifo_empty_i);
	input clk_i;
	input rst_n_i;
	input tx_timing_i;
	output txd_o;
	output fifo_rd_o;
	input [7:0] fifo_data_i;
	input fifo_empty_i;

	//bit[9]:start bit, bit[8:1]:tx data, bit[0]:stop bit.
	reg [9:0] tx_buf_r;  
	reg [3:0] state;
	reg [3:0] tx_cnt;

	reg 			fifo_rd_r;
	reg 			txd_r;
	
  parameter IDLE_STATE = 0, FIFO_READ_STATE = 1, TX_STATE = 2, END_STATE = 3;
	
	always @ (posedge clk_i or negedge rst_n_i)begin
		if(rst_n_i == 0)begin
			state <= IDLE_STATE;
			txd_r <= 1;
			fifo_rd_r <= 0;
			tx_cnt <= 0;
			tx_buf_r <= 0;
		end else begin
			case(state)
				IDLE_STATE:begin
					txd_r <= 1;
					tx_cnt <= 0;
					if(!fifo_empty_i)begin
						fifo_rd_r <= 1;
						state <= FIFO_READ_STATE;
					end
				end
				FIFO_READ_STATE:begin
					fifo_rd_r <= 0;
					tx_buf_r <= {1'b0, fifo_data_i,1'b1}; //start bit, data , stop bit
					state <= TX_STATE;
				end
				TX_STATE:begin
					if(tx_timing_i)begin
						txd_r <= tx_buf_r[9];
						tx_buf_r[9:0] <= {tx_buf_r[8:0], 1'b0};
						tx_cnt <= tx_cnt + 1;
						if(tx_cnt == 9)begin
							state <= END_STATE;
						end 
					end
				end
			 END_STATE:begin
				 state <= IDLE_STATE;
			 end
			endcase // case(state)
		end
	end					 

	assign fifo_rd_o = fifo_rd_r;
	assign txd_o = txd_r;

endmodule // nuart_tx
