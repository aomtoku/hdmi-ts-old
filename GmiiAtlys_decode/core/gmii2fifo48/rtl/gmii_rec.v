`timescale 1ns / 1ps

module gmii2fifo24#(
	parameter [31:0]	ipv4_dst_rec = {8'd192, 8'd168, 8'd0, 8'd2},
	parameter [15:0]	dst_port_rec = 16'd12345,
	parameter [15:0]	ethernet_type = 16'h0800, 
	parameter [7:0]	ip_version = 8'h45,
	parameter [7:0]	ip_protcol = 8'h11

)(
	input clk125,
	input sys_rst,
	input wire [7:0]rxd,
	input wire rx_dv,
	output reg [47:0] datain,
	output reg recv_en
);

reg packet_dv;
reg [10:0]rx_state;

//---------------------------------------------------------
//  Ethernet Header & IP Header & UDP Header
//---------------------------------------------------------
reg [15:0]eth_type;
reg [7:0]ip_ver;
reg [7:0]ipv4_proto;
reg [31:0]ipv4_src;
reg [31:0]ipv4_dst;
reg [15:0]src_port;
reg [15:0]dst_port;

//----------------------------------------------------------
//
//  Counting the Recv Byte
//					& Check each Header
//----------------------------------------------------------
reg pre_en;
reg invalid;
reg [15:0]x_info;
reg [15:0]y_info;

always@(posedge clk125)begin
	if(sys_rst)begin
		rx_state <= 11'd0;
	end else
		if(rx_dv)
			rx_state <= rx_state + 11'd1;
		else
			rx_state <= 11'd0;
end

always@(posedge clk125) begin
	if(sys_rst) begin
		eth_type		<= 16'h0;
		ip_ver		<= 8'h0;
		ipv4_proto	<= 8'h0;
		ipv4_src		<= 32'h0;
		ipv4_dst		<= 32'h0;
		src_port		<= 16'h0;
		dst_port		<= 16'h0;
		packet_dv	<= 1'b0;
		x_info		<= 16'b0;
		y_info		<= 16'b0;
		pre_en		<= 1'b0;
		invalid 		<= 1'b0;
	end else begin
		if(rx_dv)begin
			case(rx_state)
				11'h14: eth_type[15:8]	<= rxd;
				11'h15: eth_type[7:0]	<= rxd;
				11'h16: ip_ver[7:0]		<= rxd;
				11'h1f: ipv4_proto[7:0]	<= rxd;
				11'h22: ipv4_src[31:24]	<= rxd;
				11'h23: ipv4_src[23:16]	<= rxd;
				11'h24: ipv4_src[15:8]	<= rxd;
				11'h25: ipv4_src[7:0]	<= rxd;
				11'h26: ipv4_dst[31:24]	<= rxd;
				11'h27: ipv4_dst[23:16]	<= rxd;
				11'h28: ipv4_dst[15:8]	<= rxd;
				11'h29: ipv4_dst[7:0]	<= rxd;
				11'h2a: src_port[15:8]	<= rxd;
				11'h2b: src_port[7:0]	<= rxd;
				11'h2c: dst_port[15:8]	<= rxd;
				11'h2d: dst_port[7:0]	<= rxd;
				11'h32: begin
							if(eth_type[15:0] == ethernet_type &&
								ip_ver[7:0] 	== ip_version	  &&
								ipv4_proto[7:0]== ip_protcol	  &&
								ipv4_dst[31:0] == ipv4_dst_rec  &&
								dst_port[15:0] == dst_port_rec) begin
										packet_dv 		<= 1'b1;
										y_info[7:0]		<= rxd;
							end
						  end
				11'h33: if(packet_dv) y_info[15:8]		<= rxd;
				11'h34: if(packet_dv) x_info[7:0] 		<= rxd;
				11'h35: begin
							if(packet_dv)begin
								x_info[15:8]	<= rxd;
								pre_en			<= 1'b1;
							end
						  end
				11'd1013: begin // before 11'd1005
								packet_dv <= 1'b0;
								invalid <= 1'b1;
								pre_en <= 1'b0;
							 end
			endcase
		end else begin
			eth_type		<= 16'h0;
			ip_ver		<= 8'h0;
			ipv4_proto	<= 8'h0;
			ipv4_src		<= 32'h0;
			ipv4_dst		<= 32'h0;
			src_port		<= 16'h0;
			dst_port		<= 16'h0;
			packet_dv 	<= 1'b0;
			pre_en		<= 1'b0;
			invalid		<= 1'b0;
		end
	end
end

//----------------------------------------------------------
//
//		Output Data for FIFO
//
//----------------------------------------------------------

reg [1:0]state_data = 0;
reg [10:0]d_cnt;

//parameter PRE		= 2'b00;   // rx_state = 35̂Ƃ
parameter DATA_B 	= 2'b01;   // DATA1 ~ 3݂
parameter DATA_G 	= 2'b10;
parameter DATA_R 	= 2'b11;

parameter YUV_1 	= 2'b01;
parameter YUV_2 	= 2'b10;


always@(posedge clk125)begin
	if(sys_rst)begin
	   state_data 	<= 2'd0;
		datain 		<= 48'd0;
		recv_en 		<= 1'd0;
		d_cnt			<= 11'd0;
	end else if(packet_dv && pre_en)begin
/*`ifdef YUV_MODE
		casex(state_data)
			YUV_1:	begin
					datain[35:24] 	<= x_info[11:0] + d_cnt;
					datain[47:36] 	<= y_info[11:0];
					datain[15:8] 	<= rxd;
					state_data 	<= YUV_2;
					recv_en 	<= 1'b0;
				end
			YUV_2:  begin
					recv_en 	<= 1'b1;
					state_data 	<= YUV_1;
					datain[7:0] 	<= rxd;
					d_cnt		<= d_cnt + 11'd1;
				end			
		endcase
`else*/
		casex(state_data)
			DATA_B: begin
					recv_en 	<= 1'b0;
					datain[35:24] 	<= x_info[11:0] + {1'b0,d_cnt};
					datain[47:36] 	<= y_info[11:0];
					datain[23:16] 	<= rxd;
					state_data 	<= DATA_G;
					recv_en 	<= 1'b0;
				end
			DATA_G: begin
					recv_en 	<= 1'b0;
					datain[15:8] 	<= rxd;
					state_data 	<= DATA_R;
				end
			DATA_R: begin
					recv_en 	<= 1'b1;
					state_data 	<= DATA_B;
					datain[7:0] 	<= rxd;
					d_cnt		<= d_cnt + 11'd1;
				end
		endcase
//`endif
	end else if(invalid)begin
		datain 		<= 48'd0;
		recv_en 	<= 1'b0;
		state_data	<= 2'b00;
		d_cnt		<= 11'd0;
	end else begin
		recv_en 	<= 1'b0;
/*`ifdef YUV_MODE
		state_data 	<= YUV_1;
`else*/
		state_data 	<= DATA_B;
//`endif		
		//datain[35:24] 	<= x_info[11:0];
		//datain[47:36] 	<= y_info[11:0];
	end
end

//------------------------------------------------------------
//
//  Send Arp Packet
//
//------------------------------------------------------------

/*
// Ethernet FCS generator
reg crc_rd;
wire        crc_init = (txcounter == 12'h08);
reg [31:0] crc_out;
wire        crc_data_en = ~crc_rd;
*/

/*crc_gen crc_inst (
    .Reset(sys_rst)
  , .Clk(tx_clk)
  , .Init(crc_init)
  , .Frame_data(txd)
  , .Data_en(crc_data_en)
  , .CRC_rd(crc_rd)
  , .CRC_end()
  , .CRC_out(crc_out)
);
*/
//      CRC32 generator function

/*
integer i;
function [31:0] crcgen;
input   [7:0] datain;
input   [31:0] crcregi;
begin
        for(i=0;i<8;i = i + 1)
        begin
//       X^32 + X^26 + X^23 + X^22 + X^16 + X^12 + X^11 + X^10 + X^8 + X^7 + X^5 + X^4 + X^2 + X^1 + 1
//      33'h100000000 | 32'h04c11db7
                crcregi = {32'h04c11db7 & {32{crcregi[31] ^ datain[i]}}} ^ {crcregi[30:0],1'b0};
        end
        crcgen = crcregi;
end
endfunction*/
/*
always@(posedge clk125) begin
	if(sys_rst)begin
		crc_out <= 32'hFFFFFFFF;
	end
		else begin
			if(rxcrc_Init) crc_out <= 32'hFFFFFFFF;
      else
			if(crc_Data_en) crc_out <= crcgen(txd,crc_out);
   end
end
*/
/*
always@(posedge tx_clk) begin
	if(sys_rst) begin
		crc_out <= 32'hFFFFFFFF;
	end
		else begin
			if(crc_init) crc_out <= 32'hFFFFFFFF;
      else 
			if(crc_data_en) crc_out <= crcgen(txd,crc_out);
   end
end

always @(posedge tx_clk) begin
  if (sys_rst) begin
    tx_en  <= 1'b0;
    crc_rd <= 1'b0;
    txd    <= 8'h0;
  end else begin
    case (txcounter)
      12'h00: begin
        tx_en <= 1'b1;
        txd   <= 8'h55;
      end
      12'h01: txd <= 8'h55;  // Preamble
      12'h02: txd <= 8'h55;
      12'h03: txd <= 8'h55;
      12'h04: txd <= 8'h55;
      12'h05: txd <= 8'h55;
      12'h06: txd <= 8'h55;
      12'h07: txd <= 8'hd5;  // Preable + Start Frame Delimiter
      12'h08: txd <= 8'hff;  // Destination MAC address = FF-FF-FF-FF-FF-FF-FF
      12'h09: txd <= 8'hff;
      12'h0a: txd <= 8'hff;
      12'h0b: txd <= 8'hff;
      12'h0c: txd <= 8'hff;
      12'h0d: txd <= 8'hff;
      12'h0e: txd <= 8'h00;  // Source MAC address = 00-30-1b-a0-a4-88
      12'h0f: txd <= 8'h30;
      12'h10: txd <= 8'h1b;
      12'h11: txd <= 8'ha0;
      12'h12: txd <= 8'ha4;
      12'h13: txd <= 8'h88;
      12'h14: txd <= 8'h08;  // Protocol Type = ARP (0x0806)
      12'h15: txd <= 8'h06;
      12'h16: txd <= 8'h00;  // Harware Type = Ethernet (1)
      12'h17: txd <= 8'h01;
      12'h18: txd <= 8'h08;  // Protocol Type = IP (0x0800)
      12'h19: txd <= 8'h00;
      12'h1a: txd <= 8'h06;  // Hardware size = 6
      12'h1b: txd <= 8'h04;  // Protocol size = 4
      12'h1c: txd <= 8'h00;  // Opcode = request (1)
      12'h1d: txd <= 8'h01;
      12'h1e: txd <= 8'h00;  // Sender MAC address = 00-30-1b-a0-a4-88
      12'h1f: txd <= 8'h30;
      12'h20: txd <= 8'h1b;
      12'h21: txd <= 8'ha0;
      12'h22: txd <= 8'ha4;
      12'h23: txd <= 8'h88;
      12'h24: txd <= 8'd10;  // Sender IP address = 10.0.21.10
      12'h25: txd <= 8'd00;
      12'h26: txd <= 8'd21;
      12'h27: txd <= 8'd10;
      12'h28: txd <= 8'h00;  // Target MAC address = 00-00-00-00-00-00
      12'h29: txd <= 8'h00;
      12'h2a: txd <= 8'h00;
      12'h2b: txd <= 8'h00;
      12'h2c: txd <= 8'h00;
      12'h2d: txd <= 8'h00;
      12'h2e: txd <= 8'hcb;  // Target IP address = 10.0.21.99
      12'h2f: txd <= 8'hb2;  // 203.178.143.234 = cb:b2:8f:ea
      12'h30: txd <= 8'h8f;
      12'h31: txd <= 8'hea;
      12'h32: txd <= 8'hde;  // Padding Area
      12'h33: txd <= 8'had;
      12'h34: txd <= 8'hbe;
      12'h35: txd <= 8'hef;
      12'h36: txd <= 8'h00;
      12'h37: txd <= 8'h00;
      12'h38: txd <= 8'h00;
      12'h39: txd <= 8'h00;
      12'h3a: txd <= 8'h00;
      12'h3b: txd <= 8'h00;
      12'h3c: txd <= 8'h00;
      12'h3d: txd <= 8'h00;
      12'h3e: txd <= 8'h00;
      12'h3f: txd <= 8'h00;
      12'h40: txd <= 8'h00;
      12'h41: txd <= 8'h00;
      12'h42: txd <= 8'h00;
      12'h43: txd <= 8'h00;
      12'h44: begin        // Frame Check Sequence
        crc_rd  <= 1'b1;
        txd <= crc_out[31:24];
      end
      12'h45: txd <= crc_out[23:16];
      12'h46: txd <= crc_out[15: 8];
      12'h47: txd <= crc_out[ 7: 0];
      12'h48: begin
        tx_en  <= 1'b0;
        txd    <= 8'h0;
        crc_rd <= 1'b0;
      end
      default: txd <= 8'h0;
    endcase
  end
end
*/
endmodule
