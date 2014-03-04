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
	reg buf_c;
	wire clk50m = buf_c;
	always@(posedge clk100)
		if(rstbtn_n)
			buf_c <= 1'b0;
		else
			buf_c <= ~buf_c;

	reg buf_d;
	assign clk25m = buf_d;
	always@(posedge clk50m)
		if(rstbtn_n)
			buf_d <= 1'b0;
		else
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


wire vde;
wire [10:0]hcnt,vcnt;
tmds_timing(
	.rx0_pclk(rx0_pclk),
	.rstbtn_n(rstbtn_n), 
	.rx0_hsync(rx0_hsync),
	.rx0_vsync(rx0_vsync),
	.video_en(vde),
	.index(),
	.video_hcnt(hcnt),
	.video_vcnt(vnct)
);

wire aq;
reg buf_vde;
reg adep;
reg ap = 1'b0;
reg apb = 1'b0;

reg [7:0]hsycnt;

always @ (posedge rx0_pclk) begin
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

	if(rx0_ade & hcnt >= 11'd1500 & hcnt <= 11'd1510)
     ap <= 1'b1;
	if(rx0_ade & hcnt > 11'd1510)
     apb <= 1'b1;
end




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
	reg ade_qq,ade_qqq;
	reg [3:0]adin0_qq,adin1_qq,adin2_qq;
	reg [3:0]adin0_qqq,adin1_qqq,adin2_qqq;
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

			adin0_q <= rx0_aux0;
			adin1_q <= rx0_aux1;
			adin2_q <= rx0_aux2;

			adin0_qq <= adin0_q;
			adin1_qq <= adin1_q;
			adin2_qq <= adin2_q;

			adin0_qqq <= adin0_qq;
			adin1_qqq <= adin1_qq;
			adin2_qqq <= adin2_qq;
		end
	end
/*
	reg [18:0] Y, Cb, Cr, a_r, a_g, a_b;
	reg [7:0] b_r, b_g, b_b;
	reg chk;
	always @ (posedge rx0_pclk)begin
		if(rx0_reset)begin
			chk			 <= 1'b0;
			a_r      <= 19'h00;
			a_g      <= 19'h00;
			a_b      <= 19'h00;
			b_r      <= 8'h00;
			b_g      <= 8'h00;
			b_b      <= 8'h00;
		end else begin
			if(tx0_de)begin
				chk <= ~chk;
				Y <= {11'b0,tx0_green};
				if (chk == 1'b0)
					Cr <= {11'b0, tx0_blue};
				else
					Cb <= {11'b0, tx0_blue};
				
				a_r <= ( (Y<<8) + (19'b1_0110_0111*Cr) - 19'hb380)>>8;
				a_g <= ( (Y<<8) + 19'h8780 - (19'b1011_0111*Cr) - (19'b0101_1000*Cb) )>>8;
				a_b <= ( (Y<<8) + (19'b1_1100_0110*Cb) - 19'he300)>>8;
				b_r <= (a_r >= 19'hff) ? 8'hff : a_r[7:0];
				b_g <= (a_g >= 19'hff) ? 8'hff : a_g[7:0];
				b_b <= (a_b >= 19'hff) ? 8'hff : a_b[7:0];
			end
		end
	end
*/  

wire [3:0]test0 = (ade_qqq) ? {1'b1, adin0_qqq[2],vsync_qqq, hsync_qqq} : 4'b0;
wire [3:0]test1 = (ade_qqq) ? adin1_qqq : 4'b0;
wire [3:0]test2 = (ade_qqq) ? {1'b0, adin2_qqq[2:0]} : 4'b0;

	dvi_encoder_top dvi_tx0 (
    .pclk        (tx0_pclk),
    .pclkx2      (tx0_pclkx2),
    .pclkx10     (tx0_pclkx10),
    .serdesstrobe(tx0_serdesstrobe),
    .rstin       (tx0_reset),
    .blue_din    (rx0_blue/*b_b*/),
    .green_din   (rx0_green/*b_g*/),
    .red_din     (rx0_red/*b_r*/),
	.aux0_din		 (test0/*rx0_aux0*//*adin0_q*/),
	.aux1_din		 (test1/*adin1_q*/),
	.aux2_din		 (test2/*adin2_q*/),
    .hsync       (rx0_hsync/*_q*/),
    .vsync       (rx0_vsync/*_q*/),
    .vde          (rx0_vde/*_q*/),
    .ade          (ade_qqq/*_q*/),
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

	
 // assign LED = (SW[2]) ? cnt_q : (SW[3]) ? q_reg[7:0] : q_reg[15:8] ;
	assign LED = {6'd0,ap,apb};
	//assign PMOD = debug;
/*	assign PMOD[1] = rx0_vsync;
	assign PMOD[2] = rx0_vde;
	assign PMOD[3] = debug;
	assign PMOD[4] = debug;
	assign PMOD[5] = debug;
	assign PMOD[6] = debug;
	assign PMOD[7] = debug;
*/
endmodule
