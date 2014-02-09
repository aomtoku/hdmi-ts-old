`timescale 1ns / 1ps

`define simulation

module tb_gmiisend();


//
// System Clock 125MHz
//
reg sys_clk;
initial sys_clk = 1'b0;
always #8 sys_clk = ~sys_clk;

reg gmii_tx_clk;
initial gmii_tx_clk = 1'b0;
always #8 gmii_tx_clk = ~gmii_tx_clk;

reg fifo_clk;
initial fifo_clk = 1'b0;
always #13.468 fifo_clk = ~fifo_clk;

// Generate Video Signal
wire vsync, hsync;
reg [10:0]hcnt,vcnt;
assign vsync = (vcnt >= 746 || vcnt == 0);
assign hsync = (hcnt >= 1611 || hcnt == 0);
always@(posedge fifo_clk)begin
  if(sys_rst)begin
	  hcnt <= 11'd0;
	  vcnt <= 11'd0;
  end else begin
    if(hcnt == 1649)begin
	  hcnt <= 11'd0;
	  if(vcnt == 749)
	    vcnt <= 11'd0;
	  else
		vcnt <= vcnt + 11'd1;
	end else begin
      hcnt <= hcnt + 11'd1;
	end
  end
end

wire vde = (hcnt > 220 && hcnt < 1500) && (vcnt > 20 && vcnt < 740); 
//
// Test Bench
//
reg sys_rst;
reg empty;
reg full;
wire rd_en;
wire TXEN;
wire [7:0]TXD;
reg [47:0]tx_data;


wire ade_tx = ((vcnt < 11'd22) || (vcnt > 11'd741)) && ((hcnt >= 11'd1) && (hcnt < 11'd80));
reg [3:0]ade_num;
reg [11:0]ax_dout;
reg ax_send_full;
reg ax_send_empty;
wire ax_send_rd_en;

gmii_tx gmiisend(
	/*** FIFO ***/
	.fifo_clk(fifo_clk),
	.sys_rst(sys_rst),
	.dout(tx_data), //48bit
	.empty(empty),
	.full(full),
	.rd_en(rd_en),
	.wr_en(vde),
	// AX FIFO
	.adesig(ade_tx),
	.ade_num(ade_num),
	.axdout(ax_dout),
	.ax_send_full(ax_send_full),
	.ax_send_empty(ax_send_empty),
	.ax_send_rd_en(ax_send_rd_en),

	/*** Ethernet PHY GMII ****/
	.tx_clk(gmii_tx_clk),
	.tx_en(TXEN),
	.txd(TXD)
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

reg [47:0] vrom [0:2024];
reg [11:0] arom [0:2024];
reg [11:0]vcounter = 12'd0;
reg [11:0]acounter = 12'd0;

always@(posedge sys_clk)begin
  if(rd_en)begin
	{tx_data}  <= vrom[vcounter];
	vcounter   <= vcounter + 12'd1;
  end
  if(ax_send_rd_en)begin
	{ax_dout}  <= arom[acounter];
	acounter   <= acounter + 12'd1;
  end
end


initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_gmiisend);
	$readmemh("vrequest.mem",vrom);
	$readmemh("arequest.mem",arom);
	sys_rst = 1'b1;
	vcounter = 0;
	acounter = 0;
	
	waitclock;
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	
	#100000;
	$finish;
end

endmodule
