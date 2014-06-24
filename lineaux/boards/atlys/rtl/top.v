//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2010 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor:        Xilinx
// \   \   \/    Version:       1.0.0
//  \   \        Filename:      dvi_demo.v
//  /   /        Date Created:  Feb. 2010
// /___/   /\    Last Modified: Feb. 2010
// \   \  /  \
//  \___\/\___\
//
// Devices:   Spartan-6  FPGA
// Purpose:   DVI Pass Through Top Module Based On XLAB Atlys Board
// Contact:   
// Reference: None
//
// Revision History:
//   Rev 1.0.0 - (Bob Feng) First created Feb. 2010
//
//////////////////////////////////////////////////////////////////////////////
//
// LIMITED WARRANTY AND DISCLAIMER. These designs are provided to you "as is".
// Xilinx and its licensors make and you receive no warranties or conditions,
// express, implied, statutory or otherwise, and Xilinx specifically disclaims
// any implied warranties of merchantability, non-infringement, or fitness for
// a particular purpose. Xilinx does not warrant that the functions contained
// in these designs will meet your requirements, or that the operation of
// these designs will be uninterrupted or error free, or that defects in the
// designs will be corrected. Furthermore, Xilinx does not warrant or make any
// representations regarding use or the results of the use of the designs in
// terms of correctness, accuracy, reliability, or otherwise.
//
// LIMITATION OF LIABILITY. In no event will Xilinx or its licensors be liable
// for any loss of data, lost profits, cost or procurement of substitute goods
// or services, or for any special, incidental, consequential, or indirect
// damages arising from the use or operation of the designs or accompanying
// documentation, however caused and on any theory of liability. This
// limitation will apply even if Xilinx has been advised of the possibility
// of such damage. This limitation shall apply not-withstanding the failure
// of the essential purpose of any limited remedies herein.
//
//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2010 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps

//`define DIRECTPASS

module top (
  input wire        rstbtn_n,    //The pink reset button
  input wire        clk100,      //100 MHz osicallator
	input wire 				btn,
  input wire [3:0]  RX0_TMDS,
  input wire [3:0]  RX0_TMDSB,

  output wire [3:0] TX0_TMDS,
  output wire [3:0] TX0_TMDSB,

  input  wire [3:0] SW,
  output wire       UART_TX,
	input  wire       UART_RX,
	//output wire [7:0] PMOD,

  output wire [7:0] LED
);

  ////////////////////////////////////////////////////
  // 25 MHz and switch debouncers
  ////////////////////////////////////////////////////
  wire clk25, clk25m;
/*
  BUFIO2 #(.DIVIDE_BYPASS("FALSE"), .DIVIDE(5))
  sysclk_div (.DIVCLK(clk25m), .IOCLK(), .SERDESSTROBE(), .I(clk100));
	*/
  wire clk100m;
  IBUFG ibug100(.I(clk100),.O(clk100m));

	reg buf_c;
	wire clk50m = buf_c;
	always@(posedge clk100m)
			buf_c <= ~buf_c;

	reg buf_d;
	assign clk25m = buf_d;
	always@(posedge clk50m)
			buf_d <= ~buf_d;

  BUFG clk25_buf (.I(clk25m), .O(clk25));

  wire [1:0] sws;

  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_0 (.async(SW[0]),.sync(sws[0]),.clk(clk25));

  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_1 (.async(SW[1]),.sync(sws[1]),.clk(clk25));

  wire [1:0] select = sws;

  reg [1:0] select_q = 2'b00;
  reg [1:0] switch = 2'b00;
  always @ (posedge clk25) begin
    select_q <= select;

    switch[0] = select[0] ^ select_q[0];
    switch[1] = select[1] ^ select_q[1];
  end

  /////////////////////////
  //
  // Input Port 0
  //
  /////////////////////////
  wire rx0_pclk, rx0_pclkx2, rx0_pclkx10, rx0_pllclk0;
  wire rx0_plllckd;
  wire rx0_reset;
  wire rx0_serdesstrobe;
  wire rx0_hsync;          // hsync data
  wire rx0_vsync;          // vsync data
  wire rx0_ade;             // data enable
  wire rx0_vde;             // data enable
  wire rx0_psalgnerr;      // channel phase alignment error
	wire [3:0] rx0_aux0;
	wire [3:0] rx0_aux1;
	wire [3:0] rx0_aux2;
  wire [7:0] rx0_red;      // pixel data out
  wire [7:0] rx0_green;    // pixel data out
  wire [7:0] rx0_blue;     // pixel data out
  wire [29:0] rx0_sdata;
  wire rx0_blue_vld;
  wire rx0_green_vld;
  wire rx0_red_vld;
  wire rx0_blue_rdy;
  wire rx0_green_rdy;
  wire rx0_red_rdy;

	wire [7:0]debug;

  dvi_decoder dvi_rx0 (
    //These are input ports
    .tmdsclk_p   (RX0_TMDS[3]),
    .tmdsclk_n   (RX0_TMDSB[3]),
    .blue_p      (RX0_TMDS[0]),
    .green_p     (RX0_TMDS[1]),
    .red_p       (RX0_TMDS[2]),
    .blue_n      (RX0_TMDSB[0]),
    .green_n     (RX0_TMDSB[1]),
    .red_n       (RX0_TMDSB[2]),
    .exrst       (~rstbtn_n),

    //These are output ports
    .reset       (rx0_reset),
    .pclk        (rx0_pclk),
    .pclkx2      (rx0_pclkx2),
    .pclkx10     (rx0_pclkx10),
    .pllclk0     (rx0_pllclk0), // PLL x10 output
    .pllclk1     (rx0_pllclk1), // PLL x1 output
    .pllclk2     (rx0_pllclk2), // PLL x2 output
    .pll_lckd    (rx0_plllckd),
    .tmdsclk     (rx0_tmdsclk),
    .serdesstrobe(rx0_serdesstrobe),
    .hsync       (rx0_hsync),
    .vsync       (rx0_vsync),
    .ade         (rx0_ade),
    .vde         (rx0_vde),

    .blue_vld    (rx0_blue_vld),
    .green_vld   (rx0_green_vld),
    .red_vld     (rx0_red_vld),
    .blue_rdy    (rx0_blue_rdy),
    .green_rdy   (rx0_green_rdy),
    .red_rdy     (rx0_red_rdy),

    .psalgnerr   (rx0_psalgnerr),
		//.debug			 (PMOD),

    .sdout       (rx0_sdata),
    .aux0 	   	 (rx0_aux0),
    .aux1 	   	 (rx0_aux1),
    .aux2 	   	 (rx0_aux2),
    .red         (rx0_red),
    .green       (rx0_green),
    .blue        (rx0_blue)); 

wire [11:0]din_aux = {rx0_aux2,rx0_aux1, rx0_aux0};
wire [11:0]dout_aux;
//wire [11:0]dout_aux = {rx0_aux2, rx0_aux1, rx0_aux0};
//wire [11:0]din_aux = 12'd0;

wire dbg_empty,dbg_full;
wire rd_en;

auxfifo12 auxfifo(
  .rst(~rstbtn_n /*| rx0_reset*/),
  .wr_clk(rx0_pclk),
  .rd_clk(rx0_pclk),
  .din(din_aux),
  .wr_en(rx0_ade),
  .rd_en(rd_en),
  .dout(dout_aux),
  .full(dbg_full),
  .empty(dbg_empty)
);

wire [3:0]aux0 = dout_aux[3:0];
wire [3:0]aux1 = dout_aux[7:4];
wire [3:0]aux2 = dout_aux[11:8];

wire vde;
wire [10:0]hcnt,vcnt;
tmds_timing tim(
	.rx0_pclk(rx0_pclk),
	.rstbtn_n(~rstbtn_n), 
	.rx0_hsync(rx0_hsync),
	.rx0_vsync(rx0_vsync),
	.video_en(vde),
	.index(),
	.video_hcnt(),
	.video_vcnt(),
	.vcounter(vcnt),
	.hcounter(hcnt)
);

wire aq;
reg buf_vde;
reg adep;
reg ap = 1'b0;
reg apb = 1'b0;
reg apa = 1'b0;

reg [4:0] acnt;

always @ (posedge rx0_pclk)
  if(~rstbtn_n)begin
    acnt <= 5'd0;
  end else begin
    if(rx0_ade)begin
      if(acnt == 5'd31)
        acnt <= 5'd0;
      else
        acnt <= acnt + 5'd1;
    end else
      acnt <= 5'd0;
  end 


reg [9:0]apckt;
always @ (posedge rx0_pclk)
  if(~rstbtn_n)begin
    apckt   <= 10'd0;
  end else begin

    if(rx0_ade & acnt == 5'd0)
      apckt <= apckt + 10'd1;
    if(vcnt == 0 && hcnt == 0)
      apckt <= 10'd0;
  end


reg [7:0]head;
always @ (posedge rx0_pclk)
  if(~rstbtn_n)
    head <= 8'd0;
  else begin
    if(rx0_ade && acnt <= 5'd7)begin
			case(acnt)
			  5'd0 : head[0] <= rx0_aux0[2];
			  5'd1 : head[1] <= rx0_aux0[2];
			  5'd2 : head[2] <= rx0_aux0[2];
			  5'd3 : head[3] <= rx0_aux0[2];
			  5'd4 : head[4] <= rx0_aux0[2];
			  5'd5 : head[5] <= rx0_aux0[2];
			  5'd6 : head[6] <= rx0_aux0[2];
			  5'd7 : head[7] <= rx0_aux0[2];
      endcase
			//head[0] <= rx0_aux0[2];
      //head <= {head[6:0],1'd0};
    end
 end


reg [7:0]hsycnt;

always @ (posedge rx0_pclk) begin
  if(~rstbtn_n)begin
		ap  <= 1'b0;
		apb <= 1'b0;
	end
  buf_vde <= vde;
  if({vde,buf_vde} == 2'b10)begin
     adep <= 1'b1;
	end
  if(rx0_ade)begin
     adep <= 1'b0;
	end
	if(rx0_hsync)
		hsycnt <= hsycnt + 8'd1;
	else
		hsycnt <= 8'd0;

	if(rx0_ade && (hcnt >= 11'd1500) && (hcnt <= 11'd1510))
     ap <= 1'b1;
	if(rx0_ade && (hcnt >= 11'd1531) && (hcnt <= 11'd1535))
     apb <= 1'b1;
	if(rx0_ade && (hcnt >= 11'd1536) && (hcnt <= 11'd1540) )
     apa <= 1'b1;
end

//Controller rd_en logic 
// FIFO for aux data

wire video_ade  = ((vcnt >= 21 && vcnt <= 740) && (hcnt >= 1569 && hcnt <= 1600)) ? 1'b1 : 1'b0;
//wire nvideo_ade = ((vcnt < 21 || vcnt > 740) &&  ~dbg_empty ) ? 1'b1 : 1'b0;
wire nvideo_ade = ((vcnt < 21 || vcnt > 740) && ((hcnt >= 1069 && hcnt <= 1100) || (hcnt >= 1169 && hcnt <= 1200) || (hcnt >= 1269 && hcnt <= 1300) || (hcnt >= 1569 && hcnt <= 1600)) && ~dbg_empty ) ? 1'b1 : 1'b0;

/*
reg ade_g;
assign rd_en = ade_g;
always@(posedge rx0_pclk)begin
  if(~rstbtn_n)begin
		ade_g <= 1'b0;
	end else begin
		if(vcnt >= 21 && vcnt <= 740)begin
	    if(hcnt >= 1559 && hcnt <= 1590)
			  ade_g <= 1'b1;
			else
				ade_g <= 1'b0;
		end else begin
		  if(hcnt >= 1559 && vcnt <= )
				ade_g <= 1'b1;
			else
				ade_g <= 1'b0;
		end
	end
end
*/

wire ade = (vcnt <= 740 & vcnt >= 21) ? ade_q : (adep) ? ade_q : 1'b0;

  // TMDS output
`ifdef DIRECTPASS
  wire rstin         = rx0_reset;
  wire pclk          = rx0_pclk;
  wire pclkx2        = rx0_pclkx2;
  wire pclkx10       = rx0_pclkx10;
  wire serdesstrobe  = rx0_serdesstrobe;
  wire [29:0] s_data = rx0_sdata;

  //
  // Forward TMDS Clock Using OSERDES2 block
  //
  reg [4:0] tmdsclkint = 5'b00000;
  reg toggle = 1'b0;

  always @ (posedge pclkx2 or posedge rstin) begin
    if (rstin)
      toggle <= 1'b0;
    else
      toggle <= ~toggle;
  end

  always @ (posedge pclkx2) begin
    if (toggle)
      tmdsclkint <= 5'b11111;
    else
      tmdsclkint <= 5'b00000;
  end

  wire tmdsclk;

  serdes_n_to_1 #(
    .SF           (5))
  clkout (
    .iob_data_out (tmdsclk),
    .ioclk        (pclkx10),
    .serdesstrobe (serdesstrobe),
    .gclk         (pclkx2),
    .reset        (rstin),
    .datain       (tmdsclkint));

  OBUFDS TMDS3 (.I(tmdsclk), .O(TX0_TMDS[3]), .OB(TX0_TMDSB[3])) ;// clock

  wire [4:0] tmds_data0, tmds_data1, tmds_data2;
  wire [2:0] tmdsint;

  //
  // Forward TMDS Data: 3 channels
  //
  serdes_n_to_1 #(.SF(5)) oserdes0 (
             .ioclk(pclkx10),
             .serdesstrobe(serdesstrobe),
             .reset(rstin),
             .gclk(pclkx2),
             .datain(tmds_data0),
             .iob_data_out(tmdsint[0])) ;

  serdes_n_to_1 #(.SF(5)) oserdes1 (
             .ioclk(pclkx10),
             .serdesstrobe(serdesstrobe),
             .reset(rstin),
             .gclk(pclkx2),
             .datain(tmds_data1),
             .iob_data_out(tmdsint[1])) ;

  serdes_n_to_1 #(.SF(5)) oserdes2 (
             .ioclk(pclkx10),
             .serdesstrobe(serdesstrobe),
             .reset(rstin),
             .gclk(pclkx2),
             .datain(tmds_data2),
             .iob_data_out(tmdsint[2])) ;

  OBUFDS TMDS0 (.I(tmdsint[0]), .O(TX0_TMDS[0]), .OB(TX0_TMDSB[0])) ;
  OBUFDS TMDS1 (.I(tmdsint[1]), .O(TX0_TMDS[1]), .OB(TX0_TMDSB[1])) ;
  OBUFDS TMDS2 (.I(tmdsint[2]), .O(TX0_TMDS[2]), .OB(TX0_TMDSB[2])) ;

  convert_30to15_fifo pixel2x (
    .rst     (rstin),
    .clk     (pclk),
    .clkx2   (pclkx2),
    .datain  (s_data),
    .dataout ({tmds_data2, tmds_data1, tmds_data0}));

`else
  /////////////////
  //
  // Output Port 0
  //
  /////////////////
  wire         tx0_de;
  wire         tx0_pclk;
  wire         tx0_pclkx2;
  wire         tx0_pclkx10;
  wire         tx0_serdesstrobe;
  wire         tx0_reset;
  wire [7:0]   tx0_blue;
  wire [7:0]   tx0_green;
  wire [7:0]   tx0_red;
  wire         tx0_hsync;
  wire         tx0_vsync;
  wire         tx0_pll_reset;

  assign tx0_de           = rx0_vde;
  assign tx0_blue         = rx0_blue;
  assign tx0_green        = rx0_green;
  assign tx0_red          = rx0_red;
  assign tx0_hsync        = rx0_hsync;
  assign tx0_vsync        = rx0_vsync;
  assign tx0_pll_reset    = rx0_reset;

  //////////////////////////////////////////////////////////////////
  // Instantiate a dedicate PLL for output port
  //////////////////////////////////////////////////////////////////
  wire tx0_clkfbout, tx0_clkfbin, tx0_plllckd;
  wire tx0_pllclk0, tx0_pllclk2;

  PLL_BASE # (
    .CLKIN_PERIOD(10),
    .CLKFBOUT_MULT(10), //set VCO to 10x of CLKIN
    .CLKOUT0_DIVIDE(1),
    .CLKOUT1_DIVIDE(10),
    .CLKOUT2_DIVIDE(5),
    .COMPENSATION("SOURCE_SYNCHRONOUS")
  ) PLL_OSERDES_0 (
    .CLKFBOUT(tx0_clkfbout),
    .CLKOUT0(tx0_pllclk0),
    .CLKOUT1(),
    .CLKOUT2(tx0_pllclk2),
    .CLKOUT3(),
    .CLKOUT4(),
    .CLKOUT5(),
    .LOCKED(tx0_plllckd),
    .CLKFBIN(tx0_clkfbin),
    .CLKIN(tx0_pclk),
    .RST(tx0_pll_reset)
  );

  //
  // This BUFGMUX directly selects between two RX PLL pclk outputs
  // This way we have a matched skew between the RX pclk clocks and the TX pclk
  //
  //BUFGMUX tx0_bufg_pclk (.S(select[0]), .I1(rx1_pllclk1), .I0(rx0_pllclk1), .O(tx0_pclk));
	BUFG tx0_bufg_pclk (.I(rx0_pllclk1), .O(tx0_pclk));

  //
  // This BUFG is needed in order to deskew between PLL clkin and clkout
  // So the tx0 pclkx2 and pclkx10 will have the same phase as the pclk input
  //
  BUFG tx0_clkfb_buf (.I(tx0_clkfbout), .O(tx0_clkfbin));

  //
  // regenerate pclkx2 for TX
  //
  BUFG tx0_pclkx2_buf (.I(tx0_pllclk2), .O(tx0_pclkx2));

  //
  // regenerate pclkx10 for TX
  //
  wire tx0_bufpll_lock;
  BUFPLL #(.DIVIDE(5)) tx0_ioclk_buf (.PLLIN(tx0_pllclk0), .GCLK(tx0_pclkx2), .LOCKED(tx0_plllckd),
           .IOCLK(tx0_pclkx10), .SERDESSTROBE(tx0_serdesstrobe), .LOCK(tx0_bufpll_lock));

  assign tx0_reset = ~tx0_bufpll_lock;


	reg hsync_q,vsync_q,vde_q,ade_q;
	reg [3:0]adin0_q,adin1_q,adin2_q;
	reg ade_qq,ade_qqq,ade_qqqq;
	reg [3:0]adin0_qq,adin1_qq,adin2_qq;
	reg [3:0]adin0_qqq,adin1_qqq,adin2_qqq;
	reg [3:0]adin0_qqqq,adin1_qqqq,adin2_qqqq;
	reg hsync_qq,hsync_qqq, vsync_qq,vsync_qqq;
	always @ (posedge rx0_pclk)begin
		if(rx0_reset)begin
			hsync_q <= 1'b0;
			vsync_q <= 1'b0;
			vde_q		<= 1'b0;
		end else begin
			hsync_q <= tx0_hsync;
			vsync_q <= tx0_vsync;

			hsync_qq <= hsync_q;
			vsync_qq <= vsync_q;

			hsync_qqq <= hsync_qq;
			vsync_qqq <= vsync_qq;
			
			vde_q		<= rx0_vde;
			ade_q		<= rx0_ade;
			ade_qq  <= ade_q;
			ade_qqq <= ade_qq;
			ade_qqqq<= ade_qqq;

			adin0_q <= rx0_aux0;
			adin1_q <= rx0_aux1;
			adin2_q <= rx0_aux2;

			adin0_qq <= adin0_q;
			adin1_qq <= adin1_q;
			adin2_qq <= adin2_q;

			adin0_qqq <= adin0_qq;
			adin1_qqq <= adin1_qq;
			adin2_qqq <= adin2_qq;

			adin0_qqqq <= adin0_qqq;
			adin1_qqqq <= adin1_qqq;
			adin2_qqqq <= adin2_qqq;
		end
	end
/*
wire [3:0]test0 = (ade_qqq) ? {1'b1, adin0_qqq[2],vsync_qqq, hsync_qqq} : 4'b0;
wire [3:0]test1 = (ade_qqq) ? adin1_qqq : 4'b0;
wire [3:0]test2 = (ade_qqq) ? {1'b0, adin2_qqq[2:0]} : 4'b0;

wire [3:0]test0 = {1'b1, aux0_qqq[2],vsync_qqq, hsync_qqq} : 4'b0;
wire [3:0]test1 = adin1_qqq : 4'b0;
wire [3:0]test2 = adin2_qqq[2:0]} : 4'b0;
*/
//assign rd_en = video_ade | nvideo_ade;
reg gade,ggade;
reg dade, ddade, dddade, ddddade;
reg rade, rrade, rrrade;
assign rd_en = rrade;
always@(posedge rx0_pclk)begin
	gade  <= rd_en;
	ggade <= gade;

	dade    <= rx0_ade;
	ddade   <= dade   ;
	dddade  <= ddade  ;
	ddddade <= dddade ;
	rade    <= ddddade;
	rrade   <= rade;
	rrrade  <= rrade;
end

wire nade = rd_en;
wire made = (SW[2]) ? ((SW[3]) ? nade : dade) : ((SW[3]) ? dddade : ddddade);


wire [3:0]test0 = {aux0[3:2],rx0_vsync, rx0_hsync};
wire [3:0]test1 = aux1 ;
wire [3:0]test2 = aux2 ;

/*
wire [3:0]test0 = (made) ? {1'b1, aux0[2],rx0_vsync, rx0_hsync} : 4'b0;
wire [3:0]test1 = (made) ? aux1 : 4'b0;
wire [3:0]test2 = (made) ? aux2 : 4'b0;
*/

/*
wire [3:0]test0 = (ddddade) ? aux0 : (dade) ?  {1'b1, 1'b1, 1'b0, 1'b0} :4'b0;
wire [3:0]test1 = (ddddade) ? aux1 : 4'b0;
wire [3:0]test2 = (ddddade) ? aux2 : 4'b0;
*/
dvi_encoder_top dvi_tx0 (
    .pclk        (tx0_pclk),
    .pclkx2      (tx0_pclkx2),
    .pclkx10     (tx0_pclkx10),
    .serdesstrobe(tx0_serdesstrobe),
    .rstin       (tx0_reset),
    .blue_din    (rx0_blue),
    .green_din   (rx0_green),
    .red_din     (rx0_red),
	  .aux0_din		 ({1'b1,1'b0/*aux0[2]*/,rx0_vsync, rx0_hsync}/*test0*//*rx0_aux0*//*{adin0_qqqq[3:2],rx0_vsync, rx0_hsync}*/),
	  .aux1_din		 (4'd0/*aux1*//*test1*//*adin1_qqqq*/),
	  .aux2_din		 (4'd0/*aux2*//*test2*//*adin2_qqqq*/),
    .hsync       (rx0_hsync),
    .vsync       (rx0_vsync),
    .vde         (rx0_vde),
    .ade         (rrrade),
    .TMDS        (TX0_TMDS),
    .TMDSB       (TX0_TMDSB));

`endif

  //////////////////////////////////////
  // Status LED
  //////////////////////////////////////
	reg [7:0]cnt = 0;
	reg [7:0]cnt_q = 0;
	reg ch = 0;
	// Counting clocks during 1 ADE period
	always @ (posedge rx0_pclk)begin
		if(btn)begin
			cnt <= 8'd0;
			ch <= 8'd0;
		end else
			if(ade_q && ch==0)
				cnt <= cnt + 8'd1;
			else if(cnt != 0)begin
				cnt_q <= cnt;
				ch <= 1;
			end
	end

	reg [15:0]qcnt, qcnt_q,q_reg;
	reg ade_bb, vs_q;
	always @ (posedge rx0_pclk)begin
		if(btn)begin
			qcnt 		<= 16'd0;
			qcnt_q 	<= 16'd0;
		end else begin
			vs_q 		<= rx0_vsync;
			ade_bb 	<= ade_q;
			if({rx0_vsync,vs_q} == 2'b10)begin
				qcnt 	<= 16'd0;
				q_reg <= qcnt;
			end
			if({ade_q,ade_bb} == 2'b10)
				qcnt <= qcnt + 16'd1;
		end
	end


 
reg [7:0] data;

reg we;
reg [5:0]xcnt;
wire ready;
reg [39:0]mem;
reg wr_en, send;

always @ (posedge rx0_pclk or negedge rstbtn_n)begin
  if(~rstbtn_n) begin
		xcnt <= 6'd0;
		mem <= 40'd0;
		data <= 8'd0;
		send <= 1'b0;
	end else begin
		if(rx0_ade & acnt == 5'd31)begin
			mem[39:29] <= vcnt;
      mem[28:18] <= hcnt;
      mem[17:8]  <= apckt;
      mem[7:0]   <= head;
			send <= 1'b1;
		end
		if(send)begin
			if(xcnt == 6'd11)begin
			  wr_en <= 1'b1;
			  data  <= 8'h0a;
			  send  <= 1'b0;
				xcnt  <= 6'd0;
		  end else if(xcnt == 6'd10) begin
			  wr_en <= 1'b1;
			  data  <= 8'h0d;
				xcnt  <= 6'd11;
      /*end else if(xcnt == 6'd11 || xcnt == 6'd23 || xcnt == 6'd34)begin
        wr_en <= 1'b1;
        xcnt  <= xcnt + 1;
        data  <= 8'h20;*/
		  end else begin
		    wr_en <= 1'b1;
			  //mem   <= {mem[38:0],1'b0};
			  //data  <= (mem[39]) ? 8'h31 : 8'h30 ;
			  mem  <= {mem[35:0],4'd0};
				data <= ascii(mem[39:36]);
				xcnt  <= xcnt + 1;
		  end
		end else begin
		  wr_en <= 1'b0;
		end
	end
end

function [7:0]ascii;
 input  [3:0] bit;

 begin
   case(bit)
	   4'h0: ascii = 8'h30;
	   4'h1: ascii = 8'h31;
	   4'h2: ascii = 8'h32;
	   4'h3: ascii = 8'h33;
	   4'h4: ascii = 8'h34;
	   4'h5: ascii = 8'h35;
	   4'h6: ascii = 8'h36;
	   4'h7: ascii = 8'h37;
	   4'h8: ascii = 8'h38;
	   4'h9: ascii = 8'h39;
	   4'ha: ascii = 8'h41;
	   4'hb: ascii = 8'h42;
	   4'hc: ascii = 8'h43;
	   4'hd: ascii = 8'h44;
	   4'he: ascii = 8'h45;
	   4'hf: ascii = 8'h46;
   endcase
 end
endfunction




reg empty_buf;
wire [7:0] dout;
wire empty,full;
wire ard_en = ~empty_buf & ready;

always @ (posedge clk100m)
  empty_buf <= empty;


uart_fifo_p u1(
  .rst(~rstbtn_n),
  .wr_clk(rx0_pclk),
  .rd_clk(clk100m),
  .din(data),
  .wr_en(wr_en),
  .rd_en(ard_en),
  .dout(dout),
  .full(full),
  .empty(empty)
);


uart u0 (
 .clk(clk100m),
 .rst_(rstbtn_n),
 .data(dout),
 .we(ard_en),
 .tx(UART_TX),
 .ready(ready)
);



assign LED = {empty, full,wr_en,ready,ard_en,UART_TX,UART_RX,send};

endmodule
