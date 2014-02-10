`timescale 1ns / 1ps

`define simulation

module tb_ether();


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

// Generate Video Signal
// for Gmii_tx
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

wire fifo_read = vde;

//
// generate Audio Enable period
//

reg [4:0] adecnt;
reg [11:0]aclkc;
reg ade;
reg vde_h,ade_q;
reg init, initq,initqq;
wire [11:0]axdout;
assign ax_recv_rd_en = ({init,initq} == 2'b10) || ade || ade_q;

always@(posedge fifo_clk)begin
    if(sys_rst)begin
		ade      <=  1'b0;
		adecnt   <=  6'd0;
		vde_h    <=  1'b0;
		aclkc    <= 12'd0;
		ade_q    <=  1'b0;
		init     <=  1'b0;
		initq    <=  1'b0;
		initqq   <=  1'b0;
	end else begin
	    vde_h  <= vde;
	    ade_q  <= ade;
	    initq  <= init;
		initqq <= initq; 
        //first read signal
        if(fifo_read) begin
		    init <= 1'b1;
	    end
		if({initq,initqq}==2'b10)begin
			aclkc <= axdout; 
		end
		
	    if(init & ~vde & ~ade & hcnt == aclkc)begin
		    ade <= 1'b1;
	    end
		// Aux Data Enable period 
	    if(ade)begin
		    if(adecnt == 6'd31)begin
			    ade    <= 1'b0;
		        adecnt <= 6'd0;
		    end else begin
			    adecnt <= adecnt + 6'd1;
		    end
	    end
	    if({ade,ade_q} == 2'b01)begin
		    aclkc <= axdout;
	    end
    end
end

// Generating a Number of audio enable period
reg [3:0] ade_c;
reg [3:0] ade_numd;
reg [4:0] cnt_32;
reg       vde_b;
always @ (posedge fifo_clk)begin
  vde_b <= vde;
  if(sys_rst || {vde,vde_b}==2'b10)begin
	  ade_c  <= 4'd0;
	  cnt_32 <= 5'd0; 
	  ade_numd <= ade_c;
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


wire ade_tx = ((vcnt < 11'd22) || (vcnt > 11'd741)) && ((hcnt >= 11'd1) && (hcnt < 11'd80));
wire [3:0]ade_num = (vcnt >= 22 && vnct <= 741) ? 4'd0 : 4'd10;
reg [11:0]ax_dout;
reg ax_send_full;
reg ax_send_empty = 1'b0;
wire ax_send_rd_en;

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


wire [28:0]fifo_din;
wire recv_fifo_wr_en;
wire [11:0]axdin;
wire ax_recv_wr_en;

gmii2fifo24 gmii2fifo24(
	.clk125(sys_clk),
	.sys_rst(sys_rst),
	.id(1'b0),
	.rxd(TXD),
	.rx_dv(TXEN),
	.datain(fifo_din),
	.recv_en(recv_fifo_wr_en),
	.packet_en(),
	.aux_data_in(axdin),
	.aux_wr_en(ax_recv_wr_en)
);
wire axempty,axfull;

afifo12 afifo12 (
    .Data(axdin),
    .WrClock(sys_clk),
    .RdClock(fifo_clk),
    .WrEn(ax_recv_wr_en),
    .RdEn(ax_recv_rd_en),
    .Reset(sys_rst),
    .RPReset(sys_rst),
    .Q(axdout),
    .Empty(axempty),
    .Full(axfull)
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
	$dumpvars(0, tb_ether);
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
