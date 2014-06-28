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
wire vsyn,hsyn;
reg [23:0]tmds_data;
wire rd_en;
wire TXEN;
wire [7:0]TXD;
wire [47:0]tx_data;


wire [10:0]hcnt,vcnt;
wire video_en;

// Generating a Number of audio enable period
reg [3:0] ade_c;
reg [3:0] ade_num;
reg [4:0] cnt_32;
reg       vde_b;
/*
always @ (posedge fifo_clk)begin
  vde_b <= vde;
  if(sys_rst || hcnt == 11'd1)begin
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
*/
reg ainit;
wire txx = ainit & ~video_en & (hcnt == 11'd1447); // The count timing ADE period
wire vadx = ainit & ({vde,vde_b} == 2'b10); // The count timing ADE periods

always @ (posedge fifo_clk)begin
  vde_b <= vde;
  if(sys_rst)begin
	  cnt_32  <= 5'd0; 
	  ade_c   <= 4'd0;
	  ade_num <= 4'd0;
	end else begin
	  if(ade & cnt_32 == 5'd0)
			ade_c <= ade_c + 4'd1;
	  if(txx | vadx)begin
	    ade_c  <= 4'd0;
	    ade_num <= ade_c;
	  end
	  if(ade)begin
	    if(cnt_32 == 5'd31)begin
	      cnt_32 <= 5'd0;
	    end else begin
	      cnt_32 <= cnt_32 + 5'd1;
	    end
		end
	end
end




wire [47:0]vdin;
assign vdin = {1'b0,vcnt,1'b0,hcnt,tmds_data};
wire vempty,vfull;
wire send_fifo_wr_en = video_en && (hcnt >= 12'd220 && hcnt < 12'd1420);

afifo48 send_video_fifo(
     .Data(vdin),
     .WrClock(fifo_clk),
     .RdClock(gmii_tx_clk),
     .WrEn(send_fifo_wr_en),
     .RdEn(rd_en),
     .Reset(sys_rst),
     .RPReset(),
     .Q(tx_data),
     .Empty(vempty),
     .Full(vfull)
);


wire [11:0] adin;
wire aempty,afull;
wire ade;

always@(posedge fifo_clk)
  if(sys_rst)
		ainit <= 1'b0;
	else if(video_en)
		ainit <= 1'b1;

wire a_wr_en = ainit & ade;
wire [23:0] ax_din = {vcnt, 4'd0, adin[11:4],adin[2]};
wire [23:0] ax_dout;


afifo24 send_audio_fifo(
     .Data(ax_din),
     .WrClock(fifo_clk),
     .RdClock(gmii_tx_clk),
     .WrEn(a_wr_en),
     .RdEn(ax_send_rd_en),
     .Reset(sys_rst),
     .RPReset(),
     .Q(ax_dout),
     .Empty(aempty),
     .Full(afull)
);

wire ade_tx = ~video_en && ((hcnt >= 11'd1498) && (hcnt < 11'd1500));
//wire vperi = ((video_vcnt >= 25) && (video_vcnt <= 745)) ? 1'b1 : 1'b0;
wire fil_wr_en =  video_en & (hcnt > 12'd220 & hcnt <= 12'd1420);



//wire fil_wr_en =  video_en & (hcnt >= 12'd220 & hcnt < 12'd1420);
wire [23:0] out = ax_dout;
//wire ade_tx = ~video_en && ((hcnt >= 11'd1504) && (hcnt < 11'd1510));

gmii_tx gmiisend(
    .id(1'b1),
	/*** FIFO ***/
	.fifo_clk(fifo_clk),
	.sys_rst(sys_rst),
	.dout(tx_data), //48bit
	.empty(vempty),
	.full(full),
	.rd_en(rd_en),
	.wr_en(fil_wr_en),
	// AX FIFO
	
	.adesig(ade_tx),
	.ade_num(ade_num),
	.axdout(out),
	.ax_send_empty(aempty),
	.ax_send_rd_en(ax_send_rd_en),

	/*** Ethernet PHY GMII ****/
	.tx_clk(gmii_tx_clk),
	.tx_en(TXEN),
	.txd(TXD),
	.sw(1'b1)
);


wire vde = (hcnt > 220 && hcnt < 1500) && (vcnt > 20 && vcnt < 740); 

tmds_timing timing_inst (
  .rx0_pclk(fifo_clk),
  .rstbtn_n(sys_rst), 
  .rx0_hsync(hsyn),
  .rx0_vsync(vsyn),
  .video_en(video_en),
  .index(),
  .video_hcnt(),
  .video_vcnt(),
  .vcounter(vcnt),
  .hcounter(hcnt)
);

//assign rd_en = vde;

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

reg [11:0] adata;
reg [47:0] vrom [0:2475000];
reg [11:0] arom [0:2024];
reg [21:0]vcounter = 22'd0;
reg [11:0]acounter = 12'd0;
reg [3:0]vv,hh,aa;
assign vsyn = vv[0];
assign hsyn = hh[0];
assign ade  = aa[0];
assign adin = adata;

always@(posedge fifo_clk)begin
  {vv,hh,aa,tmds_data,adata}     <= vrom[vcounter];
	vcounter	<= vcounter + 22'd1;
end
/*if(rd_en)begin
		//tx_data 	<= vrom[vcounter];
		vcounter	<= vcounter + 12'd1;
	end
*/
/*
always@(posedge fifo_clk)begin

	if(ax_send_rd_en)begin
		ax_dout  <= arom[acounter];
		acounter <= acounter + 12'd1;
  end
end
*/

initial begin
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_gmiisend);
	$readmemh("request.mem",vrom);
	//$readmemh("arequest.mem",arom);
	sys_rst = 1'b1;
	vcounter = 0;
	acounter = 0;
	
	waitclock;
	waitclock;
	
	sys_rst = 1'b0;
	
	waitclock;
	
	
	#41000000;
	$finish;
end

endmodule
