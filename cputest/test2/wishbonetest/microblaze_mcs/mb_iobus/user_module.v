//*****************************************************************************
// File Name            : user_module.v
//-----------------------------------------------------------------------------
// Function             : user_module 
//                        
//-----------------------------------------------------------------------------
// Designer             : yokomizo 
//-----------------------------------------------------------------------------
// History
// -.-- 2013/02/28
//*****************************************************************************
module user_module (
Clk,Reset,
chk_data,
//ram
clk,we,addr,dout,
//
);
//io_bus
input Clk;
input Reset;
input [7:0]chk_data;
//block 
output clk;
output [3:0]we;
output [8 : 0] addr;
output [31 : 0] dout;
//
reg  [23:0]  cnt_a;   //count
//   
reg  [8:0]  addr;   // ram Address
reg  [31:0] dout;   // ram write data
reg  [3:0]we;           // ram write enable  
//
reg  [7:0]  chk_data_d;   // ram Address
//
wire     trigger;
   
//
always @ (posedge Clk or posedge Reset )
  if (Reset==1'b1)
    cnt_a <= 24'h0;
  else
    if (cnt_a==24'hffffff)
      cnt_a <= 24'h0;
    else
      cnt_a <= cnt_a + 24'h1 ;

always @ (posedge Clk or posedge Reset )
  if (Reset==1'b1)
    chk_data_d <= 8'h00;
  else
    chk_data_d <= chk_data;

assign clk = Clk;
  
assign trigger = (chk_data!=chk_data_d)?1'b1:1'b0;
   
always @ (posedge Clk or posedge Reset )
  if (Reset==1'b1)
    addr <= 9'h000;
  else 
    if (we ==4'b1111)
      addr <=  addr + 9'd1;
    else
      addr <= addr;
   
always @ (posedge Clk or posedge Reset )
  if (Reset==1'b1)
    dout <= 32'h00000000;
  else 
    if (trigger==1'b1)
      dout <=  {cnt_a,chk_data};
    else
      dout <= dout;

always @ (posedge Clk or posedge Reset )
  if (Reset==1'b1)
    we <= 4'b0000;
  else 
    if (trigger==1'b1)
      we <= 4'b1111;
    else
      we <= 4'b0000;
       
endmodule