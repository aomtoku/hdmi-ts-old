module nuart_clkgen(clk_i, rst_n_i, tx_timing_o, rx_timing_x16_o);
	input clk_i;
	input rst_n_i;
	output tx_timing_o;
	output rx_timing_x16_o;

	parameter X16CLK_DIVINE_NUMBER = 50;

	reg [31:0] counter_r;
	reg [3:0]  x16_counter_r;
	reg 			 overflow_r;
	reg 			 tx_timing_r;
	
	always @ (posedge clk_i or negedge rst_n_i)begin
		if(rst_n_i == 0)begin
			counter_r <= 0;
		end else begin
			if(counter_r == X16CLK_DIVINE_NUMBER - 1)begin
				counter_r <= 0;
			end else begin
				counter_r <= counter_r + 1;
			end
		end
	end
	
	always @ (posedge clk_i or negedge rst_n_i)begin
		if(rst_n_i == 0)begin
			overflow_r <= 0;
		end else begin
			overflow_r <= (counter_r == 0) ? 1 : 0;
		end
	end
	
	always @ (posedge clk_i or negedge rst_n_i)begin
		if(rst_n_i == 0)begin
			x16_counter_r <= 0;
		end else begin
			if(overflow_r)begin
				x16_counter_r <= x16_counter_r + 1;
			end
		end
	end
	
	always @ (posedge clk_i or negedge rst_n_i)begin
		if(rst_n_i == 0)begin
			tx_timing_r <= 0;
		end else begin
			if(overflow_r & (x16_counter_r == 0))begin
				tx_timing_r <= 1;
			end else begin
				tx_timing_r <= 0;
			end
		end
	end
	
	assign rx_timing_x16_o = overflow_r;
	assign tx_timing_o = tx_timing_r;

endmodule // uart_clkgen

