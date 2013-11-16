`timescale 1ns / 1ps

module tb_fifo48();


/* 125MHz GMII RX CLOCK */
reg rx_clk;
initial rx_clk = 1'b0;
always #8 rx_clk = ~rx_clk;

/* 75MHz TMDS CLOCK */
reg tmds_clk;
initial tmds_clk = 1'b0;
always #13 tmds_clk = ~tmds_clk;



reg sys_rst;
reg [47:0]din;
reg [47:0]dout;
reg empty;
wire rd_en;
wire wr_en;


fifo_gen48 fifo_tb(
	.rst(sys_rst),
	.wr_clk(rx_clk),
	.rd_clk(tmds_clk),
	.din(din),
	.wr_en(wr_en),
	.rd_en(rd_en),
	.dout(dout),
	.full(),
	.empty(empty));



task waitclock;
begin 
	@(posedge rx_clk);
	#1;
end
endtask


initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tx_fifo48);
	$readmemh("./fifo.hex",rom);
	
	sys_rst = 1'b1;
	counter = 0;
	
	waitclock;
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	
	//exec time 30000nsec = 30micro sec
	#30000
	
	$finish;
end

endmodule
