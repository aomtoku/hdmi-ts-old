`timescale 1ns / 1ps

module tb_uart();

//
// System Clock 125MHz
//
reg sys_clk;
initial sys_clk = 1'b0;
always #8 sys_clk = ~sys_clk;

reg sys_rst;

reg [7:0] d;
reg we;

wire txd;
wire err;

uart_tx u0(
  .clk(sys_clk),
	.rst(sys_rst),
	.data(d),
	.we(we),
	.tx(txd),
	.wr(err)
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
	sys_rst = 1'b1;

	waitclock;
	waitclock;

	sys_rst = 1'b0;

	waitclock;
  
  if(~err)begin
    d <= 8'd0; 
    we <= 1;
    #1;
  end
  
  if(~err)begin
    d <= 8'd40; 
    we <= 1;
    #1;
  end
  
  if(~err)begin
    d <= 8'd90; 
    we <= 1;
    #1;
  end

	#100000;
	$finish;
end

endmodule
