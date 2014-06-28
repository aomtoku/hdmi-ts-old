module tmds_timing(
	input  wire       rx0_pclk,
	input  wire       rstbtn_n, 
	input  wire       rx0_hsync,
	input  wire       rx0_vsync,
	output wire       video_en,
	output reg [11:0] index,
	output reg [10:0] video_hcnt,
	output reg [10:0] video_vcnt,
  output reg [10:0] vcounter,
  output reg [10:0] hcounter
);

//reg [10:0] vcounter;
//reg [10:0] hcounter;
reg        vactive;
reg        hactive;
reg        hsync_buf,vsync_buf;
reg [5:0] hscnt;

assign video_en = (vactive & hactive);

always@(posedge rx0_pclk) begin
	if(rstbtn_n) begin
		index      <= 12'd0;
		hcounter   <= 11'd0;
		vcounter   <= 11'd0;
		video_hcnt <= 11'd0;
		video_vcnt <= 11'd0;
		vactive    <= 1'b0;
		hactive    <= 1'b0;
		hsync_buf  <= 1'b0;
		vsync_buf  <= 1'b0;
		hscnt  <= 6'd0;
	end else begin
		hsync_buf <= rx0_hsync;
		vsync_buf <= rx0_vsync;
		// Counts Hsync and Vsync 
		if({rx0_vsync,vsync_buf} == 2'b10)
			vcounter <= 11'd0;
		else if({rx0_hsync, hsync_buf} == 2'b10)
			vcounter <= vcounter + 11'd1;
		if(rx0_hsync)begin
			hscnt <= hscnt + 6'd1;
		end else
		  hscnt <= 6'd0;
		
		if(hscnt == 6'd39)
			hcounter <= 11'd0;
		else
			hcounter <= hcounter + 11'd1;

		// Active Verical line 
		if(vcounter == 11'd21)   vactive <= 1'b1;
		if(vcounter == 11'd741)  vactive <= 1'b0;

		// Active Horizontal line 
		if(hcounter == 11'd219)  hactive <= 1'b1;
		if(hcounter == 11'd1499) hactive <= 1'b0;

		// Counts Horizontal line for FIFO
		if(video_en)
		    video_hcnt <= video_hcnt + 11'd1;
		else
		    video_hcnt <= 11'd0;
			 
		if(vactive)begin
			if({rx0_hsync, hsync_buf} == 2'b10)
				video_vcnt <= video_vcnt + 11'd1;
		end else 
			video_vcnt <= 11'd0;
			
		if(video_vcnt == 11'd0 && hcounter == 11'd219)
			index <= 12'd0;
		else if(hcounter == 11'd219 || hcounter == 11'd819)
			index <= index + 12'd1;
	end
end

endmodule
