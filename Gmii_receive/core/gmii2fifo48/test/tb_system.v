`timescale 1ns / 1ns

module tb_system();


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
reg [7:0] rxd;
wire [28:0] datain;
wire recv_en;
wire packet_en;

gmii2fifo24 gmiififo24_inst (
	.clk125(sys_clk),
	.sys_rst(sys_rst),
	.rxd(rxd),
	.rx_dv(rx_dv),
	.datain(datain),
	.recv_en(recv_en),
	.packet_en(packet_en)
);

//
// a clock
//
task waitclock;
begin
	@(posedge sys_clk);
//	#1;
end
endtask

//
// Scinario
//

reg [8:0] rom [0:65535];
reg [15:0] counter = 16'd0;

always @(posedge sys_clk) begin
	{rx_dv, rxd} 	<= rom[counter];
	counter		<= counter + 16'd1;
end


initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_system);
	$readmemh("phy_rx.hex", rom);
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
