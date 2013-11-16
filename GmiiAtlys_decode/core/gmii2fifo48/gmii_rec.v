`timescale 1ns / 1ps

module gmii2fifo24(
	input clk125,
	input sys_rst,
	input wire [7:0]rxd,
	input wire rx_dv,
	output reg [47:0] datain,
	output reg recv_en,
	//output reg [7:0]txd,
	//output reg tx_en,
	//input	wire tx_clk,
	output wire [7:0]LED,
	input wire	[3:0]SW
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

//reg [311:0]dummy;

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
	end else begin
		if(rx_dv)begin
			case(rx_state)
				/*11'h00: dummy[7:0]		<= rxd;
				11'h01: dummy[15:8]		<= rxd;				
				11'h02: dummy[23:16]		<= rxd;
				11'h03: dummy[31:24]		<= rxd;
				11'h04: dummy[39:32]		<= rxd;
				11'h05: dummy[47:40]		<= rxd;
				11'h06: dummy[55:48]		<= rxd;
				11'h07: dummy[63:56]		<= rxd;
				11'h08: dummy[71:64]		<= rxd;
				11'h09: dummy[79:72]		<= rxd;
				11'h0a: dummy[87:80]		<= rxd;
				11'h0b: dummy[95:88]		<= rxd;
				11'h0c: dummy[103:96]	<= rxd;
				11'h0d: dummy[111:104]	<= rxd;
				11'h0e: dummy[119:112]	<= rxd;
				11'h0f: dummy[127:120]	<= rxd;
				11'h10: dummy[135:128]	<= rxd;
				11'h11: dummy[143:136]	<= rxd;
				11'h12: dummy[151:144]	<= rxd;
				11'h13: dummy[159:152]	<= rxd;*/
				11'h14: eth_type[15:8]	<= rxd;
				11'h15: eth_type[7:0]	<= rxd;
				11'h16: ip_ver[7:0]		<= rxd;
				/*11'h17: ip_ver[15:8]		<= rxd;
				11'h18: dummy[167:160]	<= rxd;
				11'h19: dummy[175:168]	<= rxd;
				11'h1a: dummy[183:176]	<= rxd;
				11'h1b: dummy[191:184]	<= rxd;
				11'h1c: dummy[199:192]	<= rxd;
				11'h1d: dummy[207:200]	<= rxd;
				11'h1e: dummy[215:208]	<= rxd;*/
				11'h1f: ipv4_proto[7:0]	<= rxd;
				/*11'h20: dummy[223:216]	<= rxd;
				11'h21: dummy[231:224]	<= rxd;*/
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
				/*11'h2e: dummy[239:232]	<= rxd;
				11'h2f: dummy[247:240]	<= rxd;
				11'h30: dummy[255:248]	<= rxd;
				11'h31: dummy[263:256]	<= rxd;*/
				11'h32: x_info[7:0]		<= rxd;
				11'h33: x_info[15:8]		<= rxd;
				11'h34: y_info[7:0]		<= rxd;
				//11'h35: y_info[15:8]		<= rxd;
				//11'h36: dummy[271:264]	<= rxd;
				11'h35: begin
							y_info[15:8]		<= rxd;
							if(eth_type[15:0] == 16'h0800 &&
								ip_ver[7:0] 	== 8'h45		&&
								ipv4_proto[7:0]== 8'h11		&&
								//ipv4_dst[31:0] == 32'h0A00150A &&
								dst_port[15:0] == 16'h3039) begin
								packet_dv <= 1'b1;
							end
						 end
				/*11'h38: dummy[287:280]		<= rxd;
				11'h39: dummy[295:288]		<= rxd;
				11'h3a: dummy[303:296]		<= rxd;
				11'h3b: dummy[311:304]		<= rxd;*/
			endcase
		end else begin
			eth_type		<= 16'h0;
			ip_ver		<= 8'h0;
			ipv4_proto	<= 8'h0;
			ipv4_src		<= 32'h0;
			ipv4_dst		<= 32'h0;
			src_port		<= 16'h0;
			dst_port		<= 16'h0;
			packet_dv <= 1'b0;
		end
	end
end

//`define debug_header_1
`ifdef debug_header_1
assign LED[7:0] = sw_rx_count(.SW(SW), .dummy(dummy));
function [7:0]sw_rx_count;
input [3:0]SW;
input [311:0]dummy;
begin
	case(SW)
		4'b0000: sw_rx_count = dummy[7:0];  
		4'b0001: sw_rx_count = dummy[15:8];
		4'b0010: sw_rx_count = dummy[23:16];
		4'b0011: sw_rx_count = dummy[31:24];
		4'b0100: sw_rx_count = dummy[39:32];
		4'b0101: sw_rx_count = dummy[47:40];
		4'b0110:	sw_rx_count = dummy[55:48];
		4'b0111: sw_rx_count = dummy[63:56];
		4'b1000: sw_rx_count = dummy[71:64];
		4'b1001: sw_rx_count = dummy[79:72];
		4'b1010: sw_rx_count = dummy[87:80];
		4'b1011: sw_rx_count = dummy[95:88];
		4'b1100: sw_rx_count = dummy[103:96];
		4'b1101: sw_rx_count = dummy[111:104];
		4'b1110: sw_rx_count = dummy[119:112];
		4'b1111: sw_rx_count = dummy[127:120];
	endcase
end
endfunction
`endif


//`define debug_header_2
`ifdef debug_header_2
assign LED[7:0] = sw_rx_count(.SW(SW), .dummy(dummy), .eth_type(eth_type), .ip_ver(ip_ver), .ipv4_proto(ipv4_proto));

function [7:0]sw_rx_count;
input [3:0]SW;
input [311:0]dummy;
input [15:0]eth_type;
input [15:0]ip_ver;
input [7:0]ipv4_proto;
begin
	case(SW)
		4'b0000: sw_rx_count = dummy[135:128];  
		4'b0001: sw_rx_count = dummy[143:136];
		4'b0010: sw_rx_count = dummy[151:144];
		4'b0011: sw_rx_count = dummy[159:152];
		4'b0100: sw_rx_count = dummy[167:160];
		4'b0101: sw_rx_count = eth_type[15:8];
		4'b0110:	sw_rx_count = eth_type[7:0];
		4'b0111: sw_rx_count = ip_ver[15:8];
		4'b1000: sw_rx_count = ip_ver[7:0];
		4'b1001: sw_rx_count = dummy[175:168];
		4'b1010: sw_rx_count = dummy[183:176];
		4'b1011: sw_rx_count = dummy[191:184];
		4'b1100: sw_rx_count = dummy[199:192];
		4'b1101: sw_rx_count = dummy[207:200];
		4'b1110: sw_rx_count = dummy[215:208];
		4'b1111: sw_rx_count = dummy[223:216];
	endcase
end
endfunction
`endif

//`define debug_header_3
`ifdef debug_header_3
assign LED[7:0] = sw_rx_count(.SW(SW), .dummy(dummy), .ipv4_src(ipv4_src), .ipv4_dst(ipv4_dst), .src_port(src_port), .dst_port(dst_port));

function [7:0]sw_rx_count;
input [3:0]SW;
input [311:0]dummy;
input [31:0]ipv4_src;
input [31:0]ipv4_dst;
input [15:0]src_port;
input [15:0]dst_port;
begin
	case(SW)
		4'b0000: sw_rx_count = ipv4_proto[7:0];
		4'b0001: sw_rx_count = dummy[231:224];
		4'b0010: sw_rx_count = dummy[239:232];
		4'b0011: sw_rx_count = ipv4_src[31:24];
		4'b0100: sw_rx_count = ipv4_src[23:16];
		4'b0101: sw_rx_count = ipv4_src[15:8];
		4'b0110:	sw_rx_count = ipv4_src[7:0];
		4'b0111: sw_rx_count = ipv4_dst[31:24];
		4'b1000: sw_rx_count = ipv4_dst[23:16];
		4'b1001: sw_rx_count = ipv4_dst[15:8];
		4'b1010: sw_rx_count = ipv4_dst[7:0];
		4'b1011: sw_rx_count = src_port[15:8];
		4'b1100: sw_rx_count = src_port[7:0];
		4'b1101: sw_rx_count = dst_port[15:8];
		4'b1110: sw_rx_count = dst_port[7:0];
		4'b1111: sw_rx_count = dummy[247:240];
	endcase
end
endfunction
`endif

//`define debug_header_4
`ifdef debug_header_4
assign LED[7:0] = sw_rx_count(.SW(SW), .dummy(dummy), .x_info(x_info), .y_info(y_info));
function [7:0]sw_rx_count;
input [3:0]SW;
input [311:0]dummy;
input [15:0]x_info;
input [15:0]y_info;
begin
	case(SW)
		4'b0000: sw_rx_count = dummy[255:248];  
		4'b0001: sw_rx_count = dummy[263:256];
		4'b0010: sw_rx_count = dummy[271:264];
		4'b0011: sw_rx_count = dummy[279:272];
		4'b0100: sw_rx_count = x_info[15:8];
		4'b0101: sw_rx_count = x_info[7:0];
		4'b0110:	sw_rx_count = y_info[15:8];
		4'b0111: sw_rx_count = y_info[7:0];
		4'b1000: sw_rx_count = dummy[287:280];
		4'b1001: sw_rx_count = dummy[295:288];
		4'b1010: sw_rx_count = dummy[302:296];
		4'b1011: sw_rx_count = dummy[311:304];
		/*4'b1100: sw_rx_count = dummy[103:96];
		4'b1101: sw_rx_count = dummy[111:104];
		4'b1110: sw_rx_count = dummy[119:112];
		4'b1111: sw_rx_count = dummy[127:120];*/
	endcase
end
endfunction
`endif


//`define debug_head
`ifdef debug_head
assign LED[7:0] = sw_rx_count(.SW(SW), .eth_type(eth_type), .ip_ver(ip_ver), .ipv4_proto(ipv4_proto), .ipv4_src(ipv4_src), .ipv4_dst(ipv4_dst), .dst_port(dst_port));

function [7:0]sw_rx_count;
input [3:0]SW;
input [15:0]eth_type;
input [7:0]ip_ver;
input [7:0]ipv4_proto;
input [31:0]ipv4_src;
input [31:0]ipv4_dst;
input [15:0]dst_port;
begin
	case(SW)
		4'b0000: sw_rx_count = {rx_dv, packet_dv, 6'd0};
		4'b0001: sw_rx_count = eth_type[7:0];  
		4'b0010: sw_rx_count = eth_type[15:8];
		4'b0011: sw_rx_count = ip_ver[7:0];
		4'b0100: sw_rx_count = ipv4_proto[7:0];
		4'b0101: sw_rx_count = ipv4_src[7:0];
		4'b0110:	sw_rx_count = ipv4_src[15:8];
		4'b0111: sw_rx_count = ipv4_src[23:16];
		4'b1000: sw_rx_count = ipv4_src[31:24];
		4'b1001: sw_rx_count = ipv4_dst[7:0];
		4'b1010: sw_rx_count = ipv4_dst[15:8];
		4'b1011: sw_rx_count = ipv4_dst[23:16];
		4'b1100: sw_rx_count = ipv4_dst[31:24];
		4'b1101: sw_rx_count = dst_port[7:0];
		4'b1110: sw_rx_count = dst_port[15:8];
		4'b1111: sw_rx_count = 8'd0;
	endcase
end
endfunction
`endif


assign LED[7:0] = {SW,4'd0};
//`define debug_data
`ifdef debug_data
assign LED[7:0] = sw_rx_count(.SW(SW),.data_in(datain), .x_res(x_info), .y_res(y_info));

function [7:0]sw_rx_count;
input [3:0]SW;
input [47:0]data_in;
input [15:0]x_res;
input [15:0]y_res;
begin
	case(SW)
		4'b0001: sw_rx_count = data_in[7:0];  
		4'b0010: sw_rx_count = data_in[15:8];
		4'b0011: sw_rx_count = data_in[23:16];
		4'b0100: sw_rx_count = data_in[31:24];
		4'b0101: sw_rx_count = data_in[39:32];
		4'b0110:	sw_rx_count = data_in[47:40];
		4'b0111: sw_rx_count = x_res[7:0];  
		4'b1000: sw_rx_count = x_res[15:8];
		4'b1001: sw_rx_count = y_res[7:0];  
		4'b1010: sw_rx_count = y_res[15:8];
	endcase
end
endfunction
`endif

//----------------------------------------------------------
//
//		Output Data for FIFO
//
//----------------------------------------------------------

reg [1:0]data_no;

wire [15:0]xd_info;
wire [15:0]yd_info;
assign xd_info = x_info;
assign yd_info = y_info;

always@(posedge clk125)begin
	if(sys_rst)begin
		datain <= 48'd0;
		recv_en <= 1'd0;
	end else 
	    if(rx_state == 35) begin
				recv_en <= 1'b1;
				datain[35:24] <= xd_info[11:0];
		 end else
		 if(rx_state > 11'h35 &&rx_dv && packet_dv) begin
		   if((rx_state >= 11'h36) && data_no == 2'd0) begin
				if(rx_state == 11'h36) datain[47:36] <= yd_info[11:0];
					else  datain[35:24] <= datain[35:24] + 12'd1;
				datain[23:16] <= rxd;
				data_no <= 2'd1;
				recv_en <= 1'b1;
			end else if(rx_state >= 11'h36 && data_no == 2'd1)begin
				datain[35:24] <= datain[35:24] + 12'd1;
				datain[15:8]  <= rxd;
				data_no <= 2'd2;
			end else if(rx_state >= 11'h36 && data_no == 2'd2)begin
				recv_en <= 1'b1;
				datain[35:24] <= datain[35:24] + 12'd1;
				datain[7:0]   <= rxd;
				data_no <= 2'd0;
			end
       end else begin
			recv_en <= 1'b0;
			data_no <= 2'd0;
			datain <= 48'd0;
		 end
end

//------------------------------------------------------------
//
//  Send Arp Packet
//
//------------------------------------------------------------

/*

//`define led_debug
`ifdef led_debug
reg led_debug;
reg [26:0]txcounter_reg;
//assign LED = led_debug;
`endif
reg [11:0] txcounter;
always @(posedge tx_clk) begin
  if (sys_rst)
    txcounter <= 12'd0;
  else 
	`ifdef led_debug
	if(txcounter_reg == 125000000) begin
		txcounter_reg <= 12'd0;
		led_debug <= ~led_debug;
	end
  else begin
		txcounter_reg <= txcounter_reg + 27'd1;
		txcounter <= txcounter + 12'd1;
	end
	`endif
	`ifndef led_debug
		txcounter <= txcounter + 12'd1;
	`endif
end

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
