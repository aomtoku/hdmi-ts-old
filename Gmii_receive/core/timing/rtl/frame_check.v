`timescale 1 ns / 1 ps

module frame_check(
	input wire clk100m,
	input wire clk125m,
	input wire reset,
	input wire fifo_wr_en,
	input wire [11:0]y_din,
	input wire [1:0]sw,
	input wire [7:0]dipsw,
	output wire [7:0]signal,
	output wire frame
);


reg [11:0]y_din_q,y_din_qq;
reg [7:0]frame_cnt,frame_cnt_q;
reg over,over_q;
assign frame = frame_cnt[0];

always@(posedge clk125m)begin
	if(reset)begin
	    //frame_cnt 	<= 8'd0;
	    //frame_cnt_q <= 8'd0;
	    //over	<= 1'b0;
	    //over_q 	<= 1'b0;
	    y_din_q 	<= 12'b0;
	    y_din_qq 	<= 12'b0;
	end else begin
		y_din_qq <= y_din_q;
		if(fifo_wr_en)
			y_din_q 	<= y_din; 
	
		/*if(sec)begin
			//frame_cnt 	<= 8'd0;
			over 		<= 1'b0;
		end else begin
			frame_cnt_q 	<= frame_cnt;
			over_q 		<= over;*/
			if(y_din_q < y_din_qq)begin
				frame_cnt  <= frame_cnt + 8'd1;
        		/*if (frame_cnt == dipsw) begin
            		if (sw[0]) 
                		signal <= sw[1] ? y_din_qq[11:8] : y_din_qq[7:0];
            		else
                		signal <= sw[1] ? y_din_q[11:8] : y_din_q[7:0];
        		end*/
			end
			/*if(frame_cnt == 8'd255)
					over 	<= 1'b1;*/
		//end
	end
end

assign signal[7:0] = frame_cnt_q[7:0];
/*
reg [26:0]s_cnt;
reg sec;

assign signal[7:0] = (sec) ? {over_q,frame_cnt_q[6:0]} : 8'd0;

always@(posedge clk100m)begin
	if(reset)begin
	    s_cnt <= 27'd0;
	    sec	  <= 1'b0;
	end else begin
	    if(s_cnt == 27'd100000000)begin
		s_cnt 	<= 27'd0;
		sec 	<= ~sec;
	    end else begin
		s_cnt 	<= s_cnt + 27'd1;
	    end
   end
end
*/
endmodule
