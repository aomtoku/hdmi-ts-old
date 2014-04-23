`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   06:12:43 03/02/2013
// Design Name:   mb_mcs_sys
// Module Name:   D:/home/design/mb_mcs_sys/test_mb_mcs_sys.v
// Project Name:  mb_mcs_sys
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: mb_mcs_sys
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test_mb_mcs_sys;

        // Inputs
        reg Clk;
        reg Reset;
        reg UART_Rx;
        reg [3:0] dip_sw;

        // Outputs
        wire UART_Tx;
        wire [3:0] led;

        // Instantiate the Unit Under Test (UUT)
        mb_mcs_sys uut (
                .Clk(Clk), 
                .Reset(Reset), 
                .UART_Rx(UART_Rx), 
                .UART_Tx(UART_Tx), 
                .led(led), 
                .dip_sw(dip_sw)
        );

        initial begin
                repeat(100000)begin
                  Clk = 0;
                  #5;
                  Clk = 1;
                  #5;
                  end
                $stop;
        end 
 
        initial begin
                Reset = 1;
                UART_Rx = 0;
                dip_sw = 0;
                #100;
                Reset = 0;        
        end
endmodule

