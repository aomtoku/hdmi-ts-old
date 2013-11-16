module apple_out_gmii(
  input wire        i_clk_74M, //74.25 MHZ pixel clock
  input	wire	    i_clk_125M,
  input wire        i_rst,   
  input wire [1:0]  i_format,
  input wire [11:0] i_vcnt, //vertical counter from video timing generator
  input wire [11:0] i_hcnt, //horizontal counter from video timing generator
  input wire	    rx_dv,
  input wire[7:0]   rxd,
  //output	wire[7:0] txd,
  //output	wire		tx_en,
  input wire	    gtxclk,
  output wire[7:0]	LED,
  input	wire[3:0]	SW,

  output wire[7:0]  o_r,
  output wire[7:0]  o_g,
  output wire[7:0]  o_b
);


reg [1:0] i_format_sync, i_format_q;
always @ (posedge i_clk_74M) begin
  i_format_sync <= i_format_q;
  i_format_q <= i_format;
end

wire interlace = i_format_sync[1]; //0-progressive 1-interlace
wire hdtype = i_format_sync[0]; //0-720 1-1080
wire [23:0]data;
wire [47:0]din;
wire rx_en;
reg [17:0]addr_in, addr_out;

wire [11:0]x_res = din[35:24];
wire [11:0]y_res = din[47:36];

//----------------------------------------------------------
//  DP_RAM Control
// 		For Writing
//----------------------------------------------------------
reg dpram_xen,dpram_yen;
wire dpram_wen = (dpram_xen & dpram_yen);
wire dp_wren = (x_res < 12'd320 & y_res < 12'd240 & rx_en);

always @(posedge i_clk_125M)begin
	if(i_rst) begin
		addr_in <= 18'd0;
		dpram_xen <= 1'b0;
		dpram_yen <= 1'b0;
	end else begin
		if(x_res == 12'd0)
		    dpram_xen <= 1'b1;
		if(x_res == 12'd319)
		    dpram_xen <= 1'b0;
		if(y_res == 12'd0)
		    dpram_yen <= 1'b1;
		if(y_res == 12'd239)
		    dpram_yen <= 1'b0;
		
		if(dpram_wen)
		    addr_in <= 18'd320 * {6'd0, y_res} + {6'd0,x_res};
		else
		    addr_in <= 18'd0;
	end
end

//-----------------------------------------------------------
//  GMII RECIEVE 
//-----------------------------------------------------------

gmii2fifo24 gmii2fifo24(
   .clk125(i_clk_125M),
	.sys_rst(i_rst),
	.rxd(rxd),
	.rx_dv(rx_dv),
	.datain(din),
	.recv_en(rx_en)
);


//------------------------------------------------------------
//  Determine the Data Space or  Blank Space
//------------------------------------------------------------
parameter hstart = 12'd1649;
parameter hfin	 = 12'd319;
parameter vstart = 12'd749;
parameter vfin	 = 12'd239;

reg hactive,vactive;

always @ (posedge i_clk_74M) begin
	if(i_rst) begin
	    hactive  <= 1'b0;
	    vactive  <= 1'b0;
	    addr_out <= 18'd0;
	end else begin
		if(i_hcnt == hstart) 
		    	hactive <= 1'b1;
		if(i_hcnt == hfin) 
		    	hactive <= 1'b0;
		
		if(i_vcnt == vstart) 
		    	vactive <= 1'b1;
		if(i_vcnt == vfin) 
		    	vactive <= 1'b0;

		if(read_dp_en)
		    	addr_out <= addr_out + 18'd1;
		if(i_hcnt == hfin & i_vcnt == vfin)
		    	addr_out <= 18'd0;
	end
end

wire read_dp_en = (hactive & vactive);

assign o_b = (hactive  & vactive) ? data[7:0] 	: 8'b11111111;
assign o_g = (hactive  & vactive) ? data[15:8] 	: 8'b11111111;
assign o_r = (hactive  & vactive) ? data[23:16] : 8'b11111111;

`ifdef simulation
`else
dpram_frame dp_ram(
	.clka(i_clk_125M),
	.wea(dp_wren),
	.addra(addr_in), // 18bit
	.dina(din[23:0]),
	.clkb(i_clk_74M),
	.addrb(addr_out), //18bit
	.enb(read_dp_en),
	.doutb(data[23:0])
);
`endif

//
//  FIFO control
//
/*
wire empty,full;
wire reset_timing = (data[47:36] == 12'd0 & data[35:24] == 12'd0);

wire sync = (data[47:36] == i_hcnt & data[35:24] == i_vcnt); 
wire read_fifo = (read_dp_en & sync);

fifo48_4096 asfifo(
	.rst(i_rst),
	.wr_clk(i_clk_125M),  // TMDS clock 74.25MHz 
	.rd_clk(i_clk_74M),  // GMII TX clock 125MHz
	.din(din),     // data input 48bit
	.wr_en(recv_en),
	.rd_en(read_fifo),
	.dout(data),    // data output 48bit 
	.full(full),
	.empty(empty)
);
*/
//
//  DEBUG 
//

//`define debug_switch
assign LED = (SW) ? 8'd0 : 8'd1;

`ifdef debug_switch

assign LED = dataout(
		.SW(SW),
		.i_hcnt(i_hcnt),
		.i_vcnt(i_vcnt),
		.h_color(hactive),
		.v_color(vactuve),
		.y(y_res),
		.data_b(data[23:0])
);

function [7:0]dataout;
input [3:0]SW;
input i_hcnt;
input i_vcnt;
input h_color;
input v_color;
input	[23:0]data_b;
begin
	case(SW)
		4'b0010: dataout = {x[11:8],4'd0};
	endcase
end
endfunction
`endif

endmodule
