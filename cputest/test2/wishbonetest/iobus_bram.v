//*****************************************************************************
// File Name            : iobus_bram.v
//-----------------------------------------------------------------------------
// Function             : MicroBlaze_MAC Iobus to block RAM 
//                        
//-----------------------------------------------------------------------------
// Designer             : yokomizo 
//-----------------------------------------------------------------------------
// History
// -.-- 2013/02/28
//*****************************************************************************
module iobus_bram (
//iobus                 
Clk, Reset, IO_Ready, IO_Addr_Strobe, IO_Read_Strobe, IO_Write_Strobe,  IO_Read_Data, IO_Address, IO_Byte_Enable, IO_Write_Data,
//                
clkb,web,addrb,dinb,doutb
);
//io_bus
input Clk;
input Reset;
input IO_Addr_Strobe;
input IO_Read_Strobe;
input IO_Write_Strobe;
input [31 : 0] IO_Address;
input [3 : 0] IO_Byte_Enable;
input [31 : 0] IO_Write_Data;
output [31 : 0] IO_Read_Data;
output IO_Ready;
//block ram port-B
input clkb;
input [3 : 0] web;
input [8 : 0] addrb;
input [31 : 0] dinb;
output [31 : 0] doutb;
//
parameter p_bram_addr_low = 32'hC0001000;
parameter p_bram_addr_hi  = 32'hC00017FF;
//
reg IO_Ready;
//   
reg  [9:0]  addra;  // port-A Address
reg  [31:0] dina;   // port-A write data
reg  [3:0]  wea;    // port-A write enable  
wire [31:0] douta;  // port-A read data
//
wire hit_addr;

//アドレスの確認   
assign hit_addr = ((IO_Addr_Strobe==1'b1)&&(IO_Address>=p_bram_addr_low)&&( IO_Address<=p_bram_addr_hi))?1'b1:1'b0;

//IOバス側メモリポートのアドレス生成
always @ (posedge Clk or posedge Reset )
  if (Reset==1'b1)
    addra <= 10'h000;
  else 
    if (hit_addr==1'b1)
      addra <=  IO_Address[11:2];
    else
      addra <= addra;

//IOバス側メモリポート書込みデータ   
always @ (posedge Clk or posedge Reset )
  if (Reset==1'b1)
    dina <= 32'h00000000;
  else 
    if ((hit_addr==1'b1)&&(IO_Write_Strobe==1'b1))
      dina <=  IO_Write_Data;
    else
      dina <= dina;

//IOバス側メモリポート書込みイネーブル
always @ (posedge Clk or posedge Reset )
  if (Reset==1'b1)
    wea <= 4'b0000;
  else 
    if ((hit_addr==1'b1)&&(IO_Write_Strobe==1'b1))
      wea <= IO_Byte_Enable;
    else
      wea <= 4'b0000;
     
//Ready通知 
always @ (posedge Clk or posedge Reset )
  if (Reset==1'b1)
    IO_Ready <= 1'b1;
  else
    if  ((hit_addr==1'b1)&&((IO_Read_Strobe==1'b1)||(IO_Write_Strobe==1'b1)))
      IO_Ready <= 1'b1;
    else 
      IO_Ready <=  1'b0 ;

//IOバス読出しデータ        
assign  IO_Read_Data = douta ;

//ブロックRAM　32ビット×512　COREgeneratorで作成        
bram_32b_512w bram_32b_512w_u0 (
  .clka(Clk), // input clka
  .wea(wea), // input [0 : 0] wea
  .addra(addra), // input [8 : 0] addra
  .dina(dina), // input [31 : 0] dina
  .douta(douta), // output [31 : 0] douta
  .clkb(clkb), // input clkb
  .web(web), // input [0 : 0] web
  .addrb(addrb), // input [8 : 0] addrb
  .dinb(dinb), // input [31 : 0] dinb
  .doutb(doutb) // output [31 : 0] doutb
);
   
endmodule