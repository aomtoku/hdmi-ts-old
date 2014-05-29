/*************************************************************
 *
 *   Uart Module for Atlys
 *      30th May, 2014
 *      Developed by Yuta TOKUSAHI
 * 
 * **********************************************************/

module uart_tx()
  input  wire clk,
	input  wire rst,
	input  wire [7:0] data,
	input  wire we,
	output reg  tx,
	output reg  wr
);

 reg [3:0] cnt;
 reg dclk;
 always @ (posedge clk)begin
	 if(rst)begin
		 cnt16 <= 4'd0;
		 dclk  <= 1'b0;
	 end else begin
	   if(cnt == 4'd15)begin
			 cnt  <= 4'd0;
			 dclk <= ~dclk;
		 end else
			 cnt <= cnt + 4'd1;
   end
 end
	 
 /* FSM */
 reg [1:0]state;
 reg [7:0] sfd;
 reg [2:0]dcnt;

 parameter IDLE  = 2'b00;
 parameter START = 2'b01;
 parameter DATA  = 2'b10;
 parameter STOP  = 2'b11;

 always @ (posedge dclk) begin
   if(rst) begin
		 wr    <= 1'b0;
		 tx    <= 1'b0;
		 state <= 2'd0;
		 sfd   <= 8'd0;
		 dcnt  <= 3'd0;
	 end else begin
		 case(state)
		   IDLE  : begin
                 tx   <= 1'b1;
								 dcnt <= 3'd0;
								 wr   <= 1'b0;
								 if(we)begin
									 state <= START;
									 sfd   <= data;
								 end
               end
			 START : begin
                 tx    <= 1'b0;
								 dcnt  <= 3'd0;
								 state <= DATA;
								 wr    <= 1'b1;
               end
			 DATA  : begin
                 tx <= sfd[0]; 
                 sfd <= {1'b0, sfd[7:1]};
								 if(dcnt == 3'd7)
									 state <= DATA;
								 else
									 dcnt <= dcnt + 3'd1;
							 end
			 STOP  : begin
                 tx <= 1'b1;
								 state <= IDLE;
								 wr <= 1'b0;
               end
     endcase
 end

endmodule

