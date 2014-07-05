`timescale 1ns / 1ps

module gmii_top (
  /* Gmii Ethernet wiring */
  input  wire        rxclk,
  input  wire        sysrst,
  input  wire [ 7:0] rxd,
  input  wire        rxdv,
	input  wire        id,
  /* TMDS TX wiring */
  input  wire        pclk,
  input  wire        tmds_rst,
  input  wire        hsync,
  input  wire        vsync,
  input  wire        v

  output wire        ade,
  output wire [ 8:0] aux,
  output wire [15:0] video,  
);


/**/
wire no_video_hsync = ~vact & (~ax_send_wr_en & hsync);

/* Video FIFO*/
wire [28:0] fifo_din;
wire [10:0] y_din = fifo_din[26:16];
wire [ 1:0] x_din = fifo_din[28:27];
wire [28:0] dout;
wire video_full, video_empty;
wire video_fifo_rd_en;
wire video_fifo_wr_en;

/* Aux FIFO */
wire ax_recv_wr_en;
wire ax_recv_rd_en;
wire ax_recv_full, ax_recv_empty;
wire ax_rx_rd_en ;
wire [34:0] axdin;
wire [34:0] axdout;
reg init;

wire datavalid;


/* Logic */

gmii2fifo24 gmii2fifo24(
	.clk125(rxclk),
	.sys_rst(sysrst),
	.id(id),
	.rxd(rxd),
	.rx_dv(rxdv),
	.datain(fifo_din),
	.recv_en(video_fifo_wr_en),
	.packet_en(),
	.aux_data_in(axdin),
	.aux_wr_en(ax_recv_wr_en)
);

auxcont (
  .pclk(pclk),
  .sysrst(sysrst),
  .tmds_rst(tmds_rst),
	.vde(vde),
  .no_video_hsync(no_video_hsync),
  .auxy(axdout[34:25]), 
  .ctim(axdout[24:10]), 
  .ade(ade),
  .ax_recv_rd_en(ax_recv_rd_en)
);

fifo29_32768 asfifo_video (
	.rst(tmds_rst),
	.wr_clk(rxclk), // GMII RX clock 125MHz
	.rd_clk(pclk),  // TMDS clock 74.25MHz 
	.din(fifo_din), // data input
	.wr_en(video_fifo_wr_en),
	.rd_en(video_fifo_rd_en),
	.dout(dout),    // data output
	.full(video_full),
	.empty(video_empty)
);

fifo35 asfifo_aux (
  .rst(tmds_rst | sysrst),
	.wr_clk(rxclk),
	.rd_clk(pclk),
	.din(axdin),
	.wr_en(ax_recv_wr_en),
	.rd_en(ax_recv_rd_en),
	.dout(axdout),
	.full(ax_recv_full),
	.empty(ax_recv_empty)
);

endmodule
