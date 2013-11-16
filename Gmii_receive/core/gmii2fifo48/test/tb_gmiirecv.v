`timescale 1ns / 1ps

module tb_gmiirecv();


//
// System Clock 125MHz
//
reg sys_clk;
initial sys_clk = 1'b0;
always #8 sys_clk = ~sys_clk;


//
// Test Bench
//
reg sys_rst;
reg rx_dv;
reg [7:0]rxd;

gmii2fifo24 recv(
	.clk125(sys_clk),
	.sys_rst(sys_rst),
	.rxd(rxd),
	.rx_dv(rx_dv),
	.datain(),
	.recv_en()
	//.txd(),
	//.tx_en(),
	//.tx_clk(),
	//.LED(),
	//.SW()
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

reg [8:0] rom [0:1320];
reg [11:0]counter = 12'd0;

always@(posedge sys_clk)begin
	{rx_dv, rxd} 	<= rom[counter];
	counter			<= counter + 12'd1;
end


initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_gmiirecv);
	$readmemh("request.mem", rom);
	sys_rst = 1'b1;
	counter = 0;
	
	waitclock;
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	
	#1000000;
	$finish;
end

endmodule
