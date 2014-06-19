module nuart(clk_i, rst_n_i, Txd_o, Rxd_i, 
						 tx_fifo_rd_o, tx_fifo_data_i, tx_fifo_empty_i,
						 rx_fifo_wr_o, rx_fifo_data_o);
	
	input clk_i; // clk
	input rst_n_i; // asynchronous reset, low active

	//RS 232-C interface
	output Txd_o;  // RS 232-C tx data
	input  Rxd_i;  // RS 233-C rx data

	//tx fifo interface
	output tx_fifo_rd_o;  // tx fifo read request
	input [7:0] tx_fifo_data_i; // tx fifo read data
	input 			tx_fifo_empty_i; // tx fifo empty 

	//rx fifo interface 
	output 			rx_fifo_wr_o;  // rx fifo write request
	output [7:0] rx_fifo_data_o; // rx fifo data

	parameter X16CLK_DIVINE_NUMBER = 50;

	wire 			clk;
	wire 			rst_n;
	wire 			tx_timing;
	wire 			x16_timing;

	
	assign 		clk = clk_i;
	assign    rst_n = rst_n_i;

	defparam 	clkgen.X16CLK_DIVINE_NUMBER = X16CLK_DIVINE_NUMBER;
	nuart_clkgen clkgen 
		(
		 .clk_i(clk),
		 .rst_n_i(rst_n),
		 .tx_timing_o(tx_timing),
		 .rx_timing_x16_o(x16_timing)
		 );
	
	
	nuart_rx rx
		(
		 .clk_i(clk),
		 .x16clk_i(x16_timing),
		 .rst_n_i(rst_n),
		 .fifo_wr_o(rx_fifo_wr_o),
		 .fifo_data_o(rx_fifo_data_o),
		 .rxd_i(Rxd_i)
		 );

	nuart_tx tx
		(
		 .clk_i(clk),
		 .rst_n_i(rst_n),
		 .tx_timing_i(tx_timing),
		 .txd_o(Txd_o),
		 .fifo_rd_o(tx_fifo_rd_o),
		 .fifo_data_i(tx_fifo_data_i),
		 .fifo_empty_i(tx_fifo_empty_i)
		 );
	
	

endmodule // unart



