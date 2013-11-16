`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:00:44 08/25/2013 
// Design Name: 
// Module Name:    asfifo 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module asfifo(
	rst,
	wr_clk,
	rd_clk,
	din,
	wr_en,
	rd_en,
	dout,
	full,
	empty);


input rst;
input wr_clk;
input rd_clk;
input [47 : 0] din;
input wr_en;
input rd_en;
output [47 : 0] dout;
output full;
output empty;

//
// Internal Connections & variables
//

reg [47:0] 	Mem [15:0];
wire [3:0] 	NextWordToWrite, pNextWordToRead;
wire			EqualAddress;
wire			NextWriteAddressEn, NextReadAddressEn;
wire			Set_Status, Rst_Status;
reg			Status;
wire			PresetFull, PresetEmptyl;

//
// Code
//

assign dout = Mem[pNextWordToRead];


always @ (posedge wr_clk)
	if(wr_en & !full)
		Mem[pNextWordToWrite] <= din;
		
		
assign NextWriteAddressEn 	= wr_en & ~full;
assign NextReadAddressEn 	= rd_en & ~empty;


assign EqualAddress = (pNextWordToWrite == pNextWordToRead);

assign Set_Status = (pNextWordToWrite[2] ~^ pNextWordToWrite[3]) & (pNextWordToRead[3] ^ pNextWordToRead[2]);

assign Rst_Status = (pNextWordToWrite[2] ^ pNextWordToWrite[3]) & (pNextWordToRead[3] ~^ pNextWordToRead[2]);


always @ (Set_Status, Rst_Status, rst)
	if(Rst_Status | rst)
		Status = 0;
	else if(Set_Status)
		Status = 1;
		

assign PresetFull = Status & EqualAddress;

always @ (posedge wr_clk, posedge PresetFull)
	if(PresetFull)
		full <= 1;
	else
		full <= 0;
		
assign PresetEmpty = ~Status & EqualAddress;

always @ (posedge rd_clk, posedge PresetEmpty)
	if(PresetEmpty)
		empty <= 1;
	else 
		empty <= 0;

endmodule
