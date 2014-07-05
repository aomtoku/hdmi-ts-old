`timescale 1ns / 1ps

module auxcont (
  input  wire        pclk,
  input  wire        sysrst,
  input  wire        tmds_rst,
	input  wire        vde,
  input  wire        no_video_hsync,
  input  wire [ 9:0] auxy, 
  input  wire [15:0] ctim, 
  output wire        ade,
  output reg         ax_recv_rd_en
);

/* system rst */ 
wire rst = sysrst | tmds_rst;

/* AUX SFM */
parameter FIRST  = 3'd0;
parameter READ   = 3'd1;
parameter VDE    = 3'd2;
parameter IDLE   = 3'd3;
parameter ADE    = 3'd4;
parameter ADE_L  = 3'd5;
parameter RECV   = 3'd6;

reg [ 5:0] acnt;
reg [ 2:0] astate;
reg [15:0] txpos;
reg [15:0] start_pos;
reg [ 8:0] auxd;
reg        adep;
reg        xinit;
reg        firstvde, vdevde;
reg        ax_ts_rd_en;

wire   vde1st = ~firstvde & vde;
wire   vadx   = init & vact &  ({video_en,vde_b} == 2'b10); // The count timing ADE periods
assign ade    = adep; 

/* txpos counts no vde periods */
always @ (posedge pclk) begin
  if(rst) begin
    txpos <= 16'd0;
    vdevde   <= 1'b0;
    firstvde <= 1'b0;
  end else begin
    vdevde   <= vde;
	  if(vde)
      txpos <= 16'd0;
    else
      txpos <= txpos + 16'd1;

    if({vde,vdevde}==2'b01)
      firstvde <= 1'b1;
    if(txpos == 16'd2000)
      firstvde <= 1'b0;
  end
end

always @ (posedge pclk) begin
	if(rst)begin
		ax_recv_rd_en <=  1'b0;
		astate        <=  3'd0; 
    acnt          <=  6'd0;
    adep          <=  1'b0;
		start_pos     <= 16'd0;
		auxd          <=  9'd0;
		xinit         <=  1'b0;
	end else begin
	  if(~recv_empty & fifo_read)
		  xinit <= 1'b1;
	  
	  case(astate)
	    FIRST : begin
                ax_recv_rd_en <= 1'b0;
                if(~ax_recv_empty)
                  astate <= READ;
              end
      READ  : begin
                ax_recv_rd_en <= 1'b1;
                astate        <= RECV;
              end
      RECV  : begin
                ax_recv_rd_en <= 1'b0;
                start_pos     <= axdout[24:9];
                astate        <= VDE;
              end
      VDE   : begin
                if(auxy == vcnt)begin
                  ax_recv_rd_en <= 1'b0;
                  astate        <= IDLE;
                end else if(auxy < vcnt)
                  ax_recv_rd_en <= 1'b1;
                else	  
                  ax_recv_rd_en <= 1'b0;
              end
      IDLE  : begin
                if(txpos+1 == start_pos)begin
                  ax_recv_rd_en <= 1'b1;
                  astate        <= ADE;
                  acnt          <= 6'd0;
                  adep          <= 1'b1;
                end else begin
                  ax_recv_rd_en <= 1'b0;
                  adep          <= 1'b0;
                end
              end
      ADE   : begin
                auxd            <= axdout[8:0];
                acnt            <= acnt + 6'd1;
                adep            <= 1'b1;
                ax_recv_rd_en   <= 1'b1;
                if(acnt == 6'd30)
                  astate        <= ADE_L;
              end
      ADE_L : begin
                if((txpos+1 == axdout[24:9]) && (vcnt == auxy))begin
                  auxd          <= axdout[8:0];
                  astate        <= ADE;
                  acnt          <= 6'd0;
                  adep          <= 1'b0;
                  ax_recv_rd_en <= 1'b1;
                end else begin
                  astate        <= VDE;
                  start_pos     <= axdout[24:9];
                  adep          <= 1'b0;
                  ax_recv_rd_en <= 1'b0;
                end
              end
	  endcase
	end
end


endmodule
