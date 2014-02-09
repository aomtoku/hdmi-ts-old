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


reg ade_tx;
reg [3:0]ade_num;
reg [11:0]ax_dout;
reg ax_send_full;
reg ax_send_empty;
wire ax_send_rd_en;

gmii_tx gmiisend(
	/*** FIFO ***/
	.fifo_clk(fifo_clk),
	.sys_rst(sys_rst),
	.dout(tx_data), //24bit
	.empty(empty),
	.full(full),
	.rd_en(rd_en),
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

reg [10:0] tc_hsblnk;
reg [10:0] tc_hssync;
reg [10:0] tc_hesync;
reg [10:0] tc_heblnk;
reg [10:0] tc_vsblnk;
reg [10:0] tc_vssync;
reg [10:0] tc_vesync;
reg [10:0] tc_veblnk;


parameter HPIXELS_HDTV720P = 11'd1280; //Horizontal Live Pixels
parameter VLINES_HDTV720P  = 11'd720;  //Vertical Live ines
parameter HSYNCPW_HDTV720P = 11'd40;  //HSYNC Pulse Width
parameter VSYNCPW_HDTV720P = 11'd5;    //VSYNC Pulse Width
parameter HFNPRCH_HDTV720P = 11'd110; //Horizontal Front Portch hotoha72
parameter VFNPRCH_HDTV720P = 11'd5;    //Vertical Front Portch
parameter HBKPRCH_HDTV720P = 11'd220;  //Horizontal Front Portch
parameter VBKPRCH_HDTV720P = 11'd20;   //Vertical Front Portch


always @(*)begin
 tc_hsblnk = HPIXELS_HDTV720P - 11'd1;
 tc_hssync = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P;
 tc_hesync = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P;
 tc_heblnk = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P + HBKPRCH_HDTV720P;
 tc_vsblnk =  VLINES_HDTV720P - 11'd1;
 tc_vssync =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P;
 tc_vesync =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P;
 tc_veblnk =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P + VBKPRCH_HDTV720P;
end
wire [10:0] bgnd_hcount;
wire [10:0] bgnd_vcount;

wire VGA_HSYNC_INT, VGA_VSYNC_INT;
wire          bgnd_hsync;
wire          bgnd_hblnk;
wire          bgnd_vsync;
wire          bgnd_vblnk;


timing_gen timing_inst (
	.tc_hsblnk(tc_hsblnk), //input
	.tc_hssync(tc_hssync), //input
	.tc_hesync(tc_hesync), //input
	.tc_heblnk(tc_heblnk), //input
	.hcount(bgnd_hcount), //output
	.hsync(VGA_HSYNC_INT), //output
	.hblnk(bgnd_hblnk), //output
	.tc_vsblnk(tc_vsblnk), //input
	.tc_vssync(tc_vssync), //input
	.tc_vesync(tc_vesync), //input
	.tc_veblnk(tc_veblnk), //input
	.vcount(bgnd_vcount), //output
	.vsync(VGA_VSYNC_INT), //output
	.vblnk(bgnd_vblnk), //output
	.restart(sys_rst),
	.clk74m(pclk),
	.clk125m(RXCLK),
	.fifo_wr_en(recv_fifo_wr_en),
	.y_din(y_din)
);
wire active;
assign active = !bgnd_hblnk && !bgnd_vblnk;
assign rd_en = active;

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
		tx_data 	<= vrom[vcounter];
		vcounter	<= vcounter + 12'd1;
	end
	if(ax_send_rd_en)begin
		ax_dout  <= arom[acounter];
		acounter <= acounter + 12'd1;
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
