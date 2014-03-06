`timescale 1ns / 1ps

`define simulation

module tb_gmiisend();


//
// System Clock 125MHz
//
reg sys_clk;
initial sys_clk = 1'b0;
always #4 sys_clk = ~sys_clk;

reg gmii_tx_clk;
initial gmii_tx_clk = 1'b0;
always #4 gmii_tx_clk = ~gmii_tx_clk;

reg fifo_clk;
initial fifo_clk = 1'b0;
always #6.734 fifo_clk = ~fifo_clk;


//
// Test Bench
//
reg sys_rst;
reg empty = 0;
reg full  = 0;
wire rd_en;
wire TXEN;
wire [7:0]TXD;
reg [47:0]tx_data;


wire [10:0]hcnt,vcnt;
wire video_en;

wire ade_tx = ~video_en && ((hcnt >= 11'd1504) && (hcnt < 11'd1510));

// Generating a Number of audio enable period
reg [3:0] ade_c;
reg [3:0] ade_num;
reg [4:0] cnt_32;
reg       vde_b;

always @ (posedge fifo_clk)begin
  vde_b <= vde;
  if(sys_rst || hcnt == 11'd1502)begin
	  ade_c   <= 4'd0;
	  cnt_32  <= 5'd0; 
	  ade_num <= ade_c;
	end else begin
	  if(ade)begin
		  if(cnt_32 == 5'd31)begin
			cnt_32 <= 5'd0;
			ade_c  <= ade_c + 4'd1;
		  end else begin
		    cnt_32 <= cnt_32 + 5'd1;
		  end
		end
	end
end



reg [11:0]ax_dout;
reg ax_send_full;
reg ax_send_empty = 1'b0;
wire ax_send_rd_en;


wire vperi = (vcnt >= 21) && (vcnt <= 741) 

gmii_tx gmiisend(
    .id(1'b1),
	/*** FIFO ***/
	.fifo_clk(fifo_clk),
	.sys_rst(sys_rst),
	.dout(tx_data), //48bit
	.empty(empty),
	.full(full),
	.rd_en(rd_en),
	.wr_en(vde),
	.vperi(vperi),
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

reg hs,vs;
reg hs_q,vs_q;
reg [10:0]hc,vc;
always @ (posedge fifo_clk)begin
  if(sys_rst)begin
		hs <= 1'b0;
		vs <= 1'b0;
		hc <= 11'b0;
		vc <= 11'b0;
	end else begin
	  hs_q <= hs;
	  vs_q <= vs;
	  // hcounter , vcounter Generate 
		if(hc == 11'd1649)begin
			hc <= 11'd0;
			if(vc == 11'd749)
				vc <= 11'd0;
			else
				vc <= vc + 11'd1;
		end else
		  hc <= hc + 11'd1;

		//hsync, vsync Generate
		if((hc >= 110) && (hc <= 149))
			hs <= 1'b1;
		else 
			hs <= 1'b0;

		if((vc >= 0) && (vc <= 4))
			vs <= 1'b1;
		else 
			vs <= 1'b0;

	end
end


wire vde = (hcnt > 220 && hcnt < 1500) && (vcnt > 20 && vcnt < 740); 

//ADE Generator
//   *** ADE has 804 or 805 period in a Frame.
//   *** entire 750 lines ---> at least, one ADE per line
//   *** 2 ade periods every 15 lines.
// 
reg [3:0]c15;
reg [10:0]vc_b;
reg ade;
always@(posedge fifo_clk)begin
  if(sys_rst)begin
		ade <= 1'b0;
		c15 <= 4'd0;
		vc_b <= 11'd0;
	end else begin
	  vc_b <= vc;
		if(vc != vc_b)begin
			if(c15 == 4'd14)
				c15 <= 4'd0;
			else
				c15 <= c15 + 4'd1;
		end

	  if(vc == 0)begin
			if( ((hcnt >= 1000) && (hcnt <= 1128)) || ((hc  >= 93) && (hc <= 125)) )
				ade <= 1'b1;
			else
				ade <= 1'b0;
		end else if(c15 == 4'd14)begin
			if( ((hc >= 59) && (hc <= 91)) || ((hc >= 93) && (hc <= 125)) )
				ade <= 1'b1;
			else
				ade <= 1'b0;
		end else begin
			if( (hc >= 59) && (hc <= 91) )
				ade <= 1'b1;
			else
				ade <= 1'b0;
		end
	end
end

tmds_timing timing_inst (
  .rx0_pclk(fifo_clk),
  .rstbtn_n(sys_rst), 
  .rx0_hsync(hs),
  .rx0_vsync(vs),
  .video_en(video_en),
  .index(),
  .video_hcnt(),
  .video_vcnt(),
  .vcounter(vcnt),
  .hcounter(hcnt)
);

assign rd_en = vde;

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
	
	
	#1000000;
	$finish;
end

endmodule
