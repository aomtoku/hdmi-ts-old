`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Keio University
// Engineer: Yuta Tokusashi
// 
// Create Date:    18:06:07 08/27/2013 
// Design Name:    Gmii Ethernet Transport
// Module Name:    gmii_tx 
// Project Name:  
// Target Devices: Atlys 
// Tool versions:  ISE 14.6
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`define DATA_YUV
`define DEBUG
`define FORCE

module gmii_tx#(
	parameter [47:0]  src_mac       = {8'h00,8'h23,8'h45,8'h67,8'h89,8'h01},
	parameter [47:0]  dst_mac       = {8'h00,8'h23,8'h45,8'h67,8'h89,8'h02},
	parameter [15:0]  ip_type       = 16'h0800,
	parameter [15:0]  ip_ver        = 16'h4500,
`ifdef FORCE
	parameter [15:0]  ip_len        = 16'd1232 - 16'd1, // (Pixel byte =1200) + (packet header 2) + (UDP h = 8) + (AUDIO 32)
	parameter [15:0]  ip_alen       = 16'd29,
`else // DATA_YUV
	parameter [15:0]  ip_len        = 16'd1312 - 16'd1,
	parameter [15:0]  ip_alen       = 16'd43,
`endif
	parameter [15:0]  ip_iden       = 16'h0000,
	parameter [15:0]  ip_flag       = 16'h4000,
	parameter [7:0]   ip_ttl        = 8'h40,
	parameter [7:0]   ip_prot       = 8'h11,
	parameter [31:0]  ip_src_addr   = {8'd192,8'd168,8'd0,8'd1},
	parameter [31:0]  ip_dst_addr   = {8'd192,8'd168,8'd0,8'd2},
`ifdef FORCE
	parameter [15:0]  udp_len       = 16'd1212 - 16'd1 //  (Pixel = 1280) + (X,Y = 4) + (UDP header= 8)
`else //DATA_YUV
	parameter [15:0]  udp_len       = 16'd1292 - 16'd1 //  (Pixel = 1280) + (X,Y = 4) + (UDP header= 8)
`endif
)(
	input   wire        id,
	/*** FIFO ***/
	input   wire        fifo_clk,
	input   wire        sys_rst,
	input   wire [47:0] dout,
	input   wire        empty,
	input   wire        full,
	output  wire        rd_en,
	input   wire        wr_en,
//	input   wire        vperi,
  /*** AUX ***/
	input   wire        adesig,
	input   wire [3:0]  ade_num,
	input   wire [24:0] axdout,
	//input   wire        ax_send_full,
	input   wire        ax_send_empty,
	output  reg         ax_send_rd_en,

	input   wire        sw,
	output  wire        vntrans,

	
	/*** Ethernet PHY GMII ***/
	input   wire        tx_clk,
	output  reg         tx_en,
	output  reg [7:0]   txd
);


//--------------------------------------------------------------------------------
//***** MODE  DATA_YUV ******
//    1280x720 YUV422
//   	 G(channel 1) --> Y  8bit
//	 R(channel 2) --> Cb 8bit/ Cr8bit
//
//	 Packet is
//	 UDP Header |Y(2 Byte) | X(2 Byte) | Y0(1Byte) | Cb0(1Byte) | Y1(1Byte)
//	 | Cr1(1Byte) .............
//--------------------------------------------------------------------------------
`define DATA_YUV

//--------------------------------------------------------------------------------
//  CRC 
//--------------------------------------------------------------------------------

reg         crc_rd;
reg         crc_init;// = (state == SFD && count ==0);
wire [31:0] crc_out;
wire        crc_data_en = ~crc_rd;

crc_gen crc_gen(
	.Reset(sys_rst),
	.Clk(tx_clk),
	.Init(crc_init),
	.Frame_data(txd),
	.Data_en(crc_data_en),
	.CRC_rd(crc_rd),
	.CRC_out(crc_out),
	.CRC_end()
);

//-------------------------------------------------------------------------------
//  FIFO for VIDEO controller 
//-------------------------------------------------------------------------------
reg fstate,ppl;  
reg buf1_wr_en, buf2_wr_en; //To aboid Metastability
reg buf1_tx_en, buf2_tx_en;
wire send_enable = fstate;
reg [11:0] vcnt;
reg vp;

assign vntrans = fstate;

always @(posedge fifo_clk) begin
	if(sys_rst) begin
		fstate     <= 1'b0;
		ppl        <= 1'b0;
		buf1_wr_en <= 1'b0;
		buf2_wr_en <= 1'b0;
		vp         <= 1'b0;
		vcnt       <= 12'd0;
	end else begin
		buf1_wr_en <= wr_en;
		buf2_wr_en <= buf1_wr_en;
		buf1_tx_en <= tx_en;
		buf2_tx_en <= buf1_tx_en;
		if({buf1_wr_en,buf2_wr_en} == 2'b01)begin // Check buffering 1 line 
			fstate   <= 1'b1;
			vp <= 1'b1;
			//vcnt <= 12'd0;
		end
		//if(vperi && ({buf1_tx_en,buf2_tx_en} == 2'b01)) begin
		if({buf1_tx_en,buf2_tx_en} == 2'b01) begin
			if(vp)begin
			  if(vcnt == 12'd1439)begin
				  vp <= 1'b0;
				  vcnt <= 12'd0;
				end else
			    vcnt <= vcnt + 12'd1;
			  if(ppl)begin
				  ppl     <= 1'b0;
				  fstate  <= 1'b0;
			  end else begin
				  ppl     <= 1'b1;
			  end
			end
		end
	end
end

//---------------------------------------------------------------------
//  LOGIC
//---------------------------------------------------------------------

parameter IDLE        = 4'h0;
parameter PRE         = 4'h1;
parameter SFD         = 4'h2;
parameter DATA_ETH    = 4'h3;
parameter DATA_IP     = 4'h4;
parameter PCKTIDNT    = 4'h5;
parameter DATA_RESOL  = 4'h6;
parameter DATA_RGB    = 4'h7;
parameter AUXID       = 4'h8;
parameter AUX         = 4'h9;
parameter FCS         = 4'ha;
parameter IFG         = 4'hb;

parameter AUDIOMAX    = 5'd20;

parameter auxsize     = 12'd38;
parameter video       = 4'b0000;
parameter audio       = 4'b0001;
parameter vidax       = 4'b0010;

reg [3:0]   state;
reg [10:0]  count;
reg [1:0]   fcs_count;
reg [1:0]   cnt3;
reg [31:0]  gap_count;
reg [23:0]  ip_check;
reg [15:0]  ip_length;
reg [15:0]  udp_length;
reg [3:0]   pcktinfo;
reg [11:0]  packet_size;

reg [7:0]   tmp;
reg [4:0]   c9;
reg [4:0]   left_ade;
reg [3:0]   adecnt;
always @(posedge tx_clk)begin
	if(sys_rst)begin
		txd       <= 8'd0;
		tx_en     <= 1'd0;
		count     <= 11'd0;
		state     <= IDLE;
		cnt3      <= 2'd0;
		fcs_count <= 2'd0;
		crc_rd    <= 1'b1;
		gap_count <= 32'd0;
		crc_init  <= 1'd0;
		ip_check  <= 24'd0;
		ax_send_rd_en <= 1'b0;
		packet_size <= 12'd0;
		pcktinfo  <= 4'd0;
		tmp       <= 8'd0;
		c9        <= 5'd0;
		adecnt    <= 4'd0;
	end else begin
		crc_rd    <= 1'b0; 
		case(state)
			IDLE: begin
				if(empty == 1'b0 & send_enable)begin
					txd        <= 8'h55;
					tx_en      <= 1'b1;
					state      <= PRE;
					ip_check   <= {8'd0,ip_ver} + {8'd0,ip_len} + {8'd0,ip_iden} + {8'd0,ip_flag} 
                        + {8'd0,ip_ttl,ip_prot} + {8'd0,ip_src_addr[31:16]} +           
												{8'd0,ip_src_addr[15:0]} + {8'd0,ip_dst_addr[31:16]} + {8'd0,ip_dst_addr[15:0]};
//`ifdef simulation
          //pcktinfo    <= video;
					//:wqpacket_size <= 12'd0;
//`else
                    if(ppl /*& ax_send_empty ade_num == 4'd0*/)begin
					  adecnt      <= ade_num;
						packet_size <= auxsize * ade_num;
						pcktinfo    <= vidax;
					end else begin
						packet_size <= 12'd0;
						pcktinfo    <= video;
					end
//`endif
				end else if(/*~ax_send_empty &*/ adesig /*& ~vp*/)begin
					txd         <= 8'h55;
					tx_en       <= 1'b1;
					state       <= PRE;
					packet_size <= auxsize * {8'd0,ade_num};
					adecnt      <= ade_num;
					ip_check    <= {8'd0,ip_ver} + {8'd0,ip_alen} + {8'd0,ip_iden} + {8'd0,ip_flag} + 
                         {8'd0,ip_ttl,ip_prot} + {8'd0,ip_src_addr[31:16]} +               
                         {8'd0,ip_src_addr[15:0]} + {8'd0,ip_dst_addr[31:16]} + {8'd0,ip_dst_addr[15:0]};
					pcktinfo    <= audio;
				end
			end
			PRE: begin
				tx_en <= 1'b1;
				count <= count + 11'h1;
				case(count)
					11'h0: begin
					    txd	<= 8'h55;
						ip_check  <= ip_check + {12'd0,packet_size};
					end
					11'h5: begin
						txd       <= 8'h55;
						ip_check  <= ~(ip_check[15:0] + ip_check[23:16]);
						state     <= SFD;
						count     <= 11'h0;
						case(pcktinfo)
							video: begin
								ip_length <= ip_len;
								udp_length<= udp_len;
							end
							audio:begin
								ip_length <= ip_alen + {4'd0,packet_size};
								udp_length<= 16'd9 + {4'd0,packet_size};
							end
							vidax:begin
								ip_length <= ip_len + {4'd0,packet_size};
								udp_length<= udp_len + {4'd0,packet_size};
							end
						endcase
					end
					//default tx_en <= 1'b0;
				endcase
			end
			SFD: begin
				txd       <= 8'hd5;
				crc_init  <= 1'd1;
				state     <= DATA_ETH;
			end
			DATA_ETH: begin
				tx_en     <= 1'b1;
				count     <= count + 11'h1;
				crc_init  <= 1'd0;
				case(count)
					/* DST MAC 00:23:45:67:89:ac */
					11'h0: txd	<= dst_mac[47:40];
					11'h1: txd	<= dst_mac[39:32];
					11'h2: txd	<= dst_mac[31:24];
					11'h3: txd	<= dst_mac[23:16];
					11'h4: txd	<= dst_mac[15:8];
					11'h5: txd	<= dst_mac[7:0] - {7'd0,id};
					/* SRC MAC 00:23:45:67:89:ab */
					11'h6: txd	<= src_mac[47:40];
					11'h7: txd	<= src_mac[39:32];
					11'h8: txd	<= src_mac[31:24];
					11'h9: txd	<= src_mac[23:16];
					11'ha: txd	<= src_mac[15:8];
					11'hb: txd	<= src_mac[7:0] + {7'd0,id};
					/* IP TYPE  0800 = */
					11'hc: txd	<= ip_type[15:8];
					11'hd: 	begin
							state 	<= DATA_IP;
							txd     <= ip_type[7:0];
							count 	<= 11'h0;
			 		end
					//default: tx_en <= 1'b0;
				endcase
			end
			DATA_IP: begin
				tx_en <= 1'b1;
				count <= count + 11'h1;
				case(count)
					/* IP Verision = 4 & IP header Length = 20byte ----> 8'h45 */
					11'h0: txd  <= ip_ver[15:8];
					/* DSF */
					11'h1: txd  <= ip_ver[7:0];
					/* Total Length  992byte (=0x03e0) */
					11'h2: txd  <= ip_length[15:8];
					11'h3: txd  <= ip_length[7:0];
					/* Identification  ---> <<later>> */
					11'h4: txd  <= ip_iden[15:8];
					11'h5: txd  <= ip_iden[7:0];
					/* Flag */
					11'h6: txd  <= ip_flag[15:8];
					11'h7: txd  <= ip_flag[7:0];
					/* TTL  64 = 0x40 */
					11'h8: txd  <= ip_ttl;
					/* Protocol = (UDP =  17 ==0x11 )*/
					11'h9: txd  <= ip_prot;
					/* checksum = *(culcurate) */
					11'ha: txd  <= ip_check[15:8];
					11'hb: txd  <= ip_check[7:0];
					/* IP v4 SRC Address 10.0.21.9 */
					11'hc: txd  <= ip_src_addr[31:24];
					11'hd: txd  <= ip_src_addr[23:16];
					11'he: txd  <= ip_src_addr[15:8];
					11'hf: txd  <= ip_src_addr[7:0] + {7'd0,id};
					/* IP v4 DEST Adress 203.178.143.241 */
					11'h10: txd <= ip_dst_addr[31:24];
					11'h11: txd <= ip_dst_addr[23:16];
					11'h12: txd <= ip_dst_addr[15:8];
					11'h13: txd <= ip_dst_addr[7:0] - {7'd0,id};
					/* UDP SRC PORT 12344  = 0x3038 */
					11'h14: txd <= 8'h30;
					11'h15: txd <= 8'h38;
					/* UDP DEST PORT 12345 = 0x3039 */
					11'h16: txd <= 8'h30;
					11'h17: txd <= 8'h39;
					/* UDP Length 972byte = 0x03cc */
					11'h18: txd <= udp_length[15:8];
					11'h19: txd <= udp_length[7:0];
					/* UDP checksum ͐ݒ肵ȂĂH*/
					11'h1a: begin
						txd   <= 8'h00;
						cnt3  <= 2'd3;
					end
					11'h1b: begin
						txd     <= 8'h00;
						state   <= PCKTIDNT;
						count   <= 11'd0;
					end
					//default: tx_en <= 1'b0;
				endcase
			end
			// 1Byte
			PCKTIDNT: begin
				case(pcktinfo)
					audio:begin
						txd   <= {adecnt,audio};
						state <= AUXID;
						count <= 11'd0;
						ax_send_rd_en <= 1'b1;
						/*if(adecnt > AUDIOMAX)
							left_ade <= AUDIOMAX;
						else
							left_ade <= adecnt;*/
					end
					video:begin
						state <= DATA_RESOL;
						txd   <= {4'd0,video};
						cnt3  <= 2'd0; //read X,Y om FIRO
						count <= 11'd0;
					end
					vidax:begin
						state <= DATA_RESOL;
						txd   <= {adecnt,vidax};
						cnt3  <= 2'd0; //read X,Y om FIRO
						count <= 11'd0;
						left_ade <= adecnt;
					end
				endcase
			end
			// 2Byte
			DATA_RESOL: begin
				cnt3    <= 2'd2;
				tx_en   <= 1'b1;
				count   <= count + 11'h1;
				case(count)
					10'h0: txd <= dout[43:36];
					10'h1: begin
						txd   <= {dout[27:24],dout[47:44]};
						count <= 11'h0;
						cnt3  <= 2'd3;
						state <= DATA_RGB;
					end
				endcase
			end
`ifdef FORCE
			DATA_RGB: begin
				if(count == 11'd1199)begin
					if(pcktinfo == video)begin
					  state <= FCS;
					end else begin
					  state <= AUXID;
					  ax_send_rd_en <= 1'b1;
					end
			 		txd   <= dout[23:16];
					count <= 11'd0;
					cnt3  <= 2'd0;
				end else begin
					tx_en <= 1'b1;
					count <= count + 11'h1;
					casex(cnt3)
						2'b1x: begin
							if(sw)
								txd 	<= /*dout[31:24]*/dout[15:8]; // Green
							else
								txd 	<= dout[45:38]; // Y
								cnt3	<= 2'd1;
						end
						2'b01: begin
							if(sw)
								txd 	<= /*{4'd0,dout[35:32]}*/dout[23:16];  // Red
							else
								txd 	<= {dout[24], count[10:4]};  // X
								cnt3 	<= 2'd2;
				    end
						//default: tx_en <= 1'b0;
					endcase
				end
			end
`else
			DATA_RGB: begin
				if(count == 11'd1279)begin
					if(pcktinfo == video)begin
					  state <= FCS;
					end else begin
					  state <= AUXID;
					  ax_send_rd_en <= 1'b1;
					end
			 		txd   <= dout[23:16];
					count <= 11'd0;
					cnt3  <= 2'd0;
				end else begin
					tx_en <= 1'b1;
					count <= count + 11'h1;
					casex(cnt3)
						2'b1x: begin
							if(sw)
								txd 	<= /*dout[31:24]*/dout[15:8]; // Green
							else
								txd 	<= dout[45:38]; // Y
								cnt3	<= 2'd1;
						end
						2'b01: begin
							if(sw)
								txd 	<= /*{4'd0,dout[35:32]}*/dout[23:16];  // Red
							else
								txd 	<= {dout[24], count[10:4]};  // X
								cnt3 	<= 2'd2;
				       		end
						//default: tx_en <= 1'b0;
					endcase
				end
			end
`endif
      // 16bit AUXID : left audio ade number -> 4bit | clock 12bit
      AUXID: begin
				if(count == 11'd1)begin
				  //txd   <= {left_ade, 1'b0,axdout[23:21]};
				  txd   <= {axdout[24:17]};
				  if(left_ade != 4'd0)begin
				    left_ade <= left_ade - 4'd1;
				  end
			    count         <= 11'd0;
				  state         <= AUX;
				  cnt3          <= 2'd0;
				  ax_send_rd_en <= 1'b0;
					c9            <= 5'd0;
				end else begin
				  ax_send_rd_en <= 1'b0;
				  count         <= 11'd1;
			    txd           <= axdout[16:9];
				end
			end
      AUX: begin
			 if(count == 11'd35)begin
			   if(left_ade == 4'd0)begin
				  state <= FCS;
				  ax_send_rd_en <= 1'b0;
			   end else begin
				  state <= AUXID;
				  ax_send_rd_en <= 1'b1;
			   end
			   txd   <= tmp;
				 c9    <= 5'd0;
				 //txd           <= axdout[7:0];
			   count <= 11'd0;
			 end else begin
			   tx_en <= 1'b1;
			   count <= count + 11'd1;
				 if(c9 == 5'd8)
					 c9 <= 5'd0;
				 else
					 c9 <= c9 + 5'd1;
				 case(c9)
				   4'd0 : begin
					          txd <= axdout[7:0];
										tmp[0] <= axdout[8];
										ax_send_rd_en <= 1'b1;
				          end
					 4'd1 : begin
					          txd <= {axdout[6:0],tmp[0]};
										tmp[1:0] <= axdout[8:7];
										ax_send_rd_en <= 1'b1;
									end
				   4'd2 : begin
					          txd <= {axdout[5:0],tmp[1:0]};
										tmp[2:0] <= axdout[8:6];
										ax_send_rd_en <= 1'b1;
				          end
					 4'd3 : begin
					          txd <= {axdout[4:0],tmp[2:0]};
										tmp[3:0] <= axdout[8:5];
										ax_send_rd_en <= 1'b1;
									end
				   4'd4 : begin
					          txd <= {axdout[3:0],tmp[3:0]};
										tmp[4:0] <= axdout[8:4];
										ax_send_rd_en <= 1'b1;
				          end
					 4'd5 : begin
					          txd <= {axdout[2:0],tmp[4:0]};
										tmp[5:0] <= axdout[8:3];
										ax_send_rd_en <= 1'b1;
									end
				   4'd6 : begin
					          txd <= {axdout[1:0],tmp[5:0]};
										tmp[6:0] <= axdout[8:2];
										ax_send_rd_en <= 1'b1;
				          end
					 4'd7 : begin
					          txd <= {axdout[0],tmp[6:0]};
										tmp[7:0] <= axdout[8:1];
										ax_send_rd_en <= 1'b0;
									end
				   4'd8 : begin
					          txd <= tmp;
										ax_send_rd_en <= 1'b1;
									end
				 endcase
				 //txd           <= axdout[7:0];
				 //ax_send_rd_en <= 1'b1;
			   /*
				 case(cnt3)
				  2'd0: begin
				    txd           <= axdout[7:0];
					  tmp[3:0]      <= axdout[11:8];
					  ax_send_rd_en <= 1'b1;
					  cnt3          <= 2'd1;
				  end
				  2'd1: begin
					  txd           <= {tmp,axdout[3:0]};
					  tmp           <= axdout[11:4];
					  cnt3          <= 2'd2;
					  ax_send_rd_en <= 1'b0;
				  end
				  2'd2: begin
					  txd           <= tmp;
					  cnt3          <= 2'd0;
					  ax_send_rd_en <= 1'b1;
				  end
				endcase*/
			  end
			end
	 FCS: begin
			tx_en     <= 1'b1;
			fcs_count <= fcs_count + 1'b1;
			crc_rd    <= 1'b1;
			case(fcs_count)
				2'h0: txd <= crc_out[31:24];
				2'h1: txd <= crc_out[23:16];
				2'h2: txd <= crc_out[15:8];
				2'h3: begin
					txd       <= crc_out[7:0];
					gap_count <= 32'd14; // Inter Frame Gap = 14 (offset value -2)
					state     <= IFG;
				end
				//default : tx_en <= 1'b0;
			endcase
		end
	 IFG: begin
			if(gap_count == 32'd0) 
				state     <= IDLE;
			else begin
				tx_en     <= 1'b0;
				gap_count <= gap_count - 32'd1;
			end
		end
			//default: tx_en <= 1'b0;
	endcase
  end
end

`ifdef simulation
assign rd_en = ((state == DATA_RGB & cnt3 == 2'd1 ) | (state == DATA_RESOL & cnt3 == 2'd3 )) ;
`else
assign rd_en = ((state == DATA_RGB & cnt3 == 2'd2 ) | (state == DATA_RESOL & cnt3 == 2'd3 ) | (state == PCKTIDNT & cnt3 == 2'd3 ));
`endif
endmodule
