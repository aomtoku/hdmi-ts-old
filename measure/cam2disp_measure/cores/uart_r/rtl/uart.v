`define SERIAL_WCNT 'd100

module uart (
  input wire clk,
	input wire rst_,
	input wire we,
	input wire [7:0] data,
	output reg tx,
	output reg ready
);

  reg [8:0] cmd;
	reg [11:0] waitnum;
	reg [3:0] cnt;

	always @ (posedge clk or negedge rst_)begin
		if(~rst_)begin
			tx      <= 1'b1;
			ready   <= 1'b1;
			cmd     <= 9'h1ff;
			waitnum <= 12'd0;
			cnt     <= 4'd0;
		end else if(ready) begin
		  tx <= 1'b1;
			waitnum <= 12'd0;
			if(we) begin
			  ready <= 1'b0;
				cmd <= {data,1'b0};
				cnt <= 4'd10;
			end
		end else if(waitnum >= `SERIAL_WCNT)begin
		  tx      <= cmd[0];
			ready   <= (cnt == 4'd1);
			cmd     <= {1'b1, cmd[8:1]};
			waitnum <= 12'd1;
			cnt     <= cnt - 4'd1;
		end else begin
		  waitnum <= waitnum + 12'd1;
		end
	end
endmodule
