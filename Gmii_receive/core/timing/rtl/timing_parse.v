`timescale 1 ns / 1 ps

module timing_parse
  (
  input  wire        clk,
  input  wire        reset,
  input	wire			hvsync_polarity,
  input  wire        fifo_wr_en,
  
  output wire [10:0] hcount,
  output wire        hsync,
  
  output wire [10:0] vcount,
  output wire        vsync,
  output wire			de
  );
  //
  // Detect VYSNC
  //
  // 10 line is 27778 Clock Cycle on 125MHz
  // 50 line is 138888 clk cycle
  // if detected more than 10 line Vacant Period,
  // determined VBLNK Period
  //
  wire en = (cnt >= 16500);
  reg init,chk;

  reg [16:0]cnt, vacant;
  always@(posedge clk)begin
  	if(reset)begin
	   cnt    	<= 17'd0;
      vacant 	<= 17'd0;
		init		<= 1'b0;
		chk		<= 1'b0;
	end else begin
	    //
		 // Counting Vacant Period
		 //   Register cnt
		 if(~fifo_wr_en)
			cnt <= cnt + 17'd1;
	    else
			cnt <= 17'd0;
       // Register vacant is determined value
	    if(en && ~fifo_wr_en && ~init)
			vacant <= cnt;
		 
		 chk <= en;
		 if({en,chk}==2'b10)
			init <= 1'b1;
	end
  end
   //
   // Detect HSYNC
   //
   // Hsync recognize by fifo_wr_en signal
   // The Vacant is when more than 40 clk cycle
   //
   reg [15:0]h_cnt, h_vac; // vacant period 
	wire h_sml = (h_cnt >= 4);
   wire h_rec = (h_cnt >= 55); // detect 1 line vacant, which is including 2 packets
   wire no_data = (h_cnt >= 2500); // detect Packet Loss or NO DATA Period
   
   always@(posedge clk)begin
      if(reset)begin
	     h_cnt <= 16'd0;
	     h_vac <= 16'd0;
		end else begin
            if(~fifo_wr_en)
                 h_cnt <= h_cnt + 16'd1;
            else
                 h_cnt <= 16'd0;
      
            if(h_rec && fifo_wr_en && ~no_data)
                 h_vac <= h_cnt;
		end
   end

   reg h_sync,hactive;
   reg [1:0]hstate,hstate_q;
	reg [10:0]hcnt,hcnt_buf; //count Horizontal pixel
	parameter NO 	= 2'b00;
	parameter DATA = 2'b11;
	parameter SML 	= 2'b10;
	parameter MDM 	= 2'b01;
   always@(posedge clk)begin
   	if(reset)begin
	    h_sync 	<= 1'b0;
	    hcnt 	<= 11'd0;
	    hcnt_buf<= 11'd0;
		 hstate	<= 2'd0;
		 hstate_q <= 2'd0;
		end else begin
			hcnt <= hcnt + 11'd1;
			//
			// when PACKT LOSS happens
			//    using learned time before interval
			//
			if(~fifo_wr_en && h_cnt == h_vac )begin
				h_sync 	<= 1'b1;
				hcnt		<= 11'd0;
				hcnt_buf <= hcnt;
			end 
	   
			//
			// PACKET coming        
			//                      SML                   MDM
			//	     ________________    ________________       ______
			//  ___|  DATA1(0~639)  |__| DATA2(640~1279)|_____|  DATA1(
			//
			hstate_q <= hstate;
			if({hstate,hstate_q} == {DATA,MDM})begin
				h_sync <= 1'b1;
				hcnt <= 11'd0;
			end
			//
			// STATE MACHINE
			//
			if(no_data && ~fifo_wr_en)
				hstate <= NO;
			else if(h_rec && ~fifo_wr_en)
				hstate <= MDM;
			else if(h_sml && ~fifo_wr_en)
				hstate <= SML;
			else if(fifo_wr_en)
				hstate <= DATA;
		
			if(hcnt == 11'd40)
				h_sync <= 1'b0;
			if(hcnt == 11'd260)
				hactive <= 1'd1;
			if(hcnt == 11'd1540)
				hactive <= 1'd0;

			//
			// Packet loss and Data invalid Period
			// if()320
			//
			if(no_data)begin
				if(hcnt == hcnt_buf)
					hcnt <= 11'd0;
			end
		end
   end

  wire [16:0]frnt_prch_s = vacant - 17'd16500;
  wire [16:0]frnt_prch_f = vacant - 17'd8250;
  parameter bck_prch_f 	= 17'd33000;

  reg vactive,bck_prch,v_sync;
  reg [10:0]hsync_cnt;
  always@(posedge clk)begin
  	if(reset)begin
	    v_sync 		<= 1'b0;
	    bck_prch 	<= 1'b0;
	    hsync_cnt 	<= 10'd0;
	    vactive 	<= 1'b0;
	end else begin
	    //
		 // Counting HYSNC 
		 //
		 if({h_sync,hsync_buf} == 2'b10)
			hsync_cnt <= hsync_cnt + 10'd1;
		
		 if(v_sync && fifo_wr_en)begin
			//v_sync 		<= 1'b0;
			hsync_cnt	<= 10'd0;
		 end 
	    
		 if(hsync_cnt == 10'd19)begin
			//bck_prch 	<= 1'b0;
			vactive 		<= 1'b1;
		 end
		 if(hsync_cnt == 10'd720)begin
			vactive 	<= 1'b0;
			//v_sync 	<= 1'b1;
	    end
		 
		 if(hstate == NO)
			v_sync <= 1'd1;
		 else 
			v_sync <= 1'd0;
	end 
  end
  //
  //
  // Generat V-H Counter
  //
  //
  reg active_q,hsync_buf,hactive_q;
  reg [10:0]h_counter,v_counter;
  
 always@(posedge clk)
	if(reset)begin
		h_counter <= 11'd0;
		v_counter <= 11'd0;
		active_q <= 1'b0;
		hactive_q <= 1'b0;
		hsync_buf <= 1'b0;
	end else begin
	   hactive_q <= hactive;
		active_q <= vactive;
		hsync_buf <= h_sync;
		if({vactive,active_q} == 2'b10)begin
			h_counter <= 11'd0;
			v_counter <= 11'd0;
		end
		
		if({hactive,hactive_q} == 2'b10)
		    h_counter <= 11'd0;
		else
		    h_counter <= h_counter + 11'd1;

		if({h_sync,hsync_buf} == 2'b10)
		    v_counter <= v_counter + 11'd1;
	end
	
  wire h_blnk = (h_counter >= 1280);
  wire v_blnk = (v_counter >= 720);
  wire de_active = !h_blnk && !v_blnk;
  //wire h_sync = (h_counter >= 1390 && h_counter < 1430);
	

  reg VGA_HSYNC, VGA_VSYNC;
  reg de_q,hsync_q,vsync_q;
  reg active_qq;
  always @ (posedge clk)
   begin
    hsync_q <= h_sync ^ hvsync_polarity ;
    vsync_q <= v_sync ^ hvsync_polarity ;
    VGA_HSYNC <= hsync_q;
    VGA_VSYNC <= vsync_q;
    active_qq <= de_active;
    de_q <= active_qq;
   end
	
	assign vsync	= VGA_VSYNC;
	assign hsync	= VGA_HSYNC;
	assign hcount	= h_counter;
	assign vcount 	= v_counter;
	assign de 		= de_q;	

endmodule
