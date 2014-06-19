`timescale 1ns / 1ps

`define simulation

module tb_uart();


//
// System Clock 50MHz
//
reg sys_clk;
initial sys_clk = 1'b0;
always #10 sys_clk = ~sys_clk;



//
// Test Bench
//
reg sys_rst;
wire TX,RX;
assign RX = 1'b1;
wire [7:0]data = 8'd49;
reg empty;
wire req;

nuart u0 (
  .clk_i(sys_clk), 
	.rst_n_i(sys_rst), 
	.Txd_o(TX), 
	.Rxd_i(RX), 
	.tx_fifo_rd_o(req),
	.tx_fifo_data_i(data), 
	.tx_fifo_empty_i(empty),
	.rx_fifo_wr_o(), 
	.rx_fifo_data_o()
);

//
// a clock
//
task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

//
// Scinario
//


initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_uart);
	sys_rst = 1'b0;
	empty  = 0;
	
	waitclock;
	waitclock;
	
	sys_rst = 1'b1;
	
	waitclock;
	
  #100;
	empty = 1'b1;
  #1;
	empty = 1'b0;
	#1;
	empty = 1'b1;
	
	#200000;
	$finish;
end

endmodule
