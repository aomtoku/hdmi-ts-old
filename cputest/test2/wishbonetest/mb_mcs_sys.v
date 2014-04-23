`timescale 1ns / 1ps
//*****************************************************************************
// File Name            : mb.v
//-----------------------------------------------------------------------------
// Function             : MicroBlaze MAC system 
//                        
//-----------------------------------------------------------------------------
// Designer             : yokomizo 
//-----------------------------------------------------------------------------
// History
// -.-- 2013/02/26
//*****************************************************************************

module mb_mcs_sys(  Clk, Reset, UART_Rx, UART_Tx,led,dip_sw
    );
  input  Clk;            //input clock 100MHz
  input  Reset;          //reset Hi=reset
  input  UART_Rx;        //UART rx 115200bps
  output UART_Tx;        //UART tx 115200bps
  output [3 : 0] led;    //led Hi=on
  input  [3 : 0] dip_sw; //input dip_sw
  //IO Bus
  wire IO_Addr_Strobe;
  wire IO_Read_Strobe;
  wire IO_Write_Strobe;
  wire [31 : 0] IO_Read_Data;
  wire [31 : 0] IO_Address;
  wire [3 : 0]  IO_Byte_Enable;
  wire [31 : 0] IO_Write_Data;
  wire IO_Ready;
  //timmer
  wire FIT1_Interrupt;
  wire FIT1_Toggle;    
  wire PIT1_Interrupt; 
  wire PIT1_Toggle; 
  //GPO   
  wire [31 : 0] GPO1;
  wire [31 : 0] GPI1;
  //GPI
  wire GPI1_Interrupt;
  //Interrupt controller
  wire INTC_Interrupt;
  wire INTC_IRQ;          
  //LED
  assign led =GPO1[3:0];

  //MCS͐M
  assign GPI1 = {28'h0000000,dip_sw};
  assign INTC_Interrupt = 1'b0;
  assign IO_Ready = 1'b0;
   
  //Microblaze MCSCX^X   
  mb_mcs mcs_0 (
  .Clk(Clk), // input Clk
  .Reset(~Reset), // input Reset
  .IO_Addr_Strobe(IO_Addr_Strobe), // output IO_Addr_Strobe
  .IO_Read_Strobe(IO_Read_Strobe), // output IO_Read_Strobe
  .IO_Write_Strobe(IO_Write_Strobe), // output IO_Write_Strobe
  .IO_Address(IO_Address), // output [31 : 0] IO_Address
  .IO_Byte_Enable(IO_Byte_Enable), // output [3 : 0] IO_Byte_Enable
  .IO_Write_Data(IO_Write_Data), // output [31 : 0] IO_Write_Data
  .IO_Read_Data(IO_Read_Data), // input [31 : 0] IO_Read_Data
  .IO_Ready(IO_Ready), // input IO_Ready
  .UART_Rx(UART_Rx), // input UART_Rx
  .UART_Tx(UART_Tx), // output UART_Tx
  .FIT1_Interrupt(FIT1_Interrupt), // output FIT1_Interrupt
  .FIT1_Toggle(FIT1_Toggle), // output FIT1_Toggle
  .PIT1_Interrupt(PIT1_Interrupt), // output PIT1_Interrupt
  .PIT1_Toggle(PIT1_Toggle), // output PIT1_Toggle
  .GPO1(GPO1), // output [31 : 0] GPO1
  .GPI1(GPI1), // input [31 : 0] GPI1
  .GPI1_Interrupt(GPI1_Interrupt), // output GPI1_Interrupt
  .INTC_Interrupt(INTC_Interrupt), // input [0 : 0] INTC_Interrupt
  .INTC_IRQ(INTC_IRQ) // output INTC_IRQ
);

endmodule
