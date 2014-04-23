//*****************************************************************************
// File Name            : iobus_reg.v
//-----------------------------------------------------------------------------
// Function             : MicroBlaze_MAC Iobus Reg 
//                        
//-----------------------------------------------------------------------------
// Designer             : yokomizo 
//-----------------------------------------------------------------------------
// History
// -.-- 2013/02/28
//*****************************************************************************
module iobus_reg (
//iobus                 
Clk, Reset, IO_Ready, IO_Addr_Strobe, IO_Read_Strobe, IO_Write_Strobe,  IO_Read_Data, IO_Address, IO_Byte_Enable, IO_Write_Data,
//data
data_in,data_in_en,
data_out,data_out_en
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
//
input [31:0] data_in;
input [3:0]  data_in_en;
//
output [31:0] data_out;
output [3:0] data_out_en;
//
parameter p_reg_addr_low = 32'hC0000000;
parameter p_reg_addr_hi  = 32'hC0000007;
//
parameter p_data_out_offset = 0;
parameter p_data_in_offaet = 4;
//    
reg [31:0] IO_Read_Data;
reg IO_Ready;
//      
reg  [31:0]  data_in_hold;   // input data
//   
reg  [31:0]  data_out;       // output data
reg  [3:0]   data_out_en;    // enable data_out 
//
wire hit_addr;

//アドレスの確認   
assign hit_addr = ((IO_Addr_Strobe==1'b1)&&(IO_Address>=p_reg_addr_low)&&( IO_Address<=p_reg_addr_hi))?1'b1:1'b0;

//書込みデータの保持
always @ (posedge Clk or posedge Reset )
  if (Reset==1'b1)
    data_out <= 32'h00000000;
  else 
    if ((hit_addr==1'b1)&&(IO_Write_Strobe==1'b1)&&(IO_Address[2:0]==p_data_out_offset))
      begin
        if(IO_Byte_Enable[0]==1'b1) //bit7_0
          data_out[7:0] <= IO_Write_Data[7:0] ;
        else
          data_out[7:0] <=  data_out[7:0] ;
        if(IO_Byte_Enable[1]==1'b1) //bit15_8
          data_out[15:8] <= IO_Write_Data[15:8] ;
        else
          data_out[15:8] <=  data_out[15:8] ;
        if(IO_Byte_Enable[2]==1'b1) //bit23-16
          data_out[23:16] <= IO_Write_Data[23:16] ;
        else
          data_out[23:16] <=  data_out[23:16] ;
        if(IO_Byte_Enable[3]==1'b1) //bit31_24
          data_out[31:24] <= IO_Write_Data[31:24] ;
        else
          data_out[31:24] <=  data_out[31:24] ;
      end 
    else
      data_out <= data_out;

//データイネーブル生成
always @ (posedge Clk or posedge Reset )
  if (Reset==1'b1)
    data_out_en <= 4'b0000;
  else 
    if ((hit_addr==1'b1)&&(IO_Write_Strobe==1'b1))
      data_out_en <= IO_Byte_Enable;
    else
      data_out_en <= 4'b0000;

//Ready通知      
always @ (posedge Clk or posedge Reset )
  if (Reset==1'b1)
    IO_Ready <= 1'b1;
  else
    if  ((hit_addr==1'b1)&&((IO_Read_Strobe==1'b1)||(IO_Write_Strobe==1'b1)))
      IO_Ready <= 1'b1;
    else 
      IO_Ready <=  1'b0 ;

//読出しデータ    
always @ (posedge Clk or posedge Reset )
  if (Reset==1'b1)
    IO_Read_Data <= 32'h00000000;
  else 
    if ((hit_addr==1'b1)&&(IO_Read_Strobe==1'b1))
      if (IO_Address[2:0]==p_data_out_offset)
        IO_Read_Data <= data_out;
      else if (IO_Address[2:0]==p_data_out_offset)
        IO_Read_Data <= data_in_hold;
      else
        IO_Read_Data <= 32'h00000000;
    else
      IO_Read_Data <= IO_Read_Data ;

//入力データ保持              
always @ (posedge Clk or posedge Reset )
  if (Reset==1'b1)
    data_in_hold <= 32'h00000000;
  else 
    if (data_in_en==1'b1)
      data_in_hold <= data_in;
    else
      data_in_hold <= data_in_hold;
        
endmodule