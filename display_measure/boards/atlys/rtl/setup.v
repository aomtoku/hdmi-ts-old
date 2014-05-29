///////////////////////////////////////////////////////////////////////////
// Video Timing Parameters
///////////////////////////////////////////////////////////////////////////
  //1280x1024@60HZ
  parameter HPIXELS_SXGA = 11'd1280; //Horizontal Live Pixels
  parameter  VLINES_SXGA = 11'd1024;  //Vertical Live ines
  parameter HSYNCPW_SXGA = 11'd112;  //HSYNC Pulse Width
  parameter VSYNCPW_SXGA = 11'd3;    //VSYNC Pulse Width
  parameter HFNPRCH_SXGA = 11'd48;   //Horizontal Front Portch
  parameter VFNPRCH_SXGA = 11'd1;    //Vertical Front Portch
  parameter HBKPRCH_SXGA = 11'd248;  //Horizontal Front Portch
  parameter VBKPRCH_SXGA = 11'd38;   //Vertical Front Portch

  //1280x720@60HZ
  /*
  parameter HPIXELS_HDTV720P = 11'd1280; //Horizontal Live Pixels
  parameter VLINES_HDTV720P  = 11'd720;  //Vertical Live ines
  parameter HSYNCPW_HDTV720P = 11'd80;  //HSYNC Pulse Width
  parameter VSYNCPW_HDTV720P = 11'd5;    //VSYNC Pulse Width
  parameter HFNPRCH_HDTV720P = 11'd72;   //Horizontal Front Portch hotoha72
  parameter VFNPRCH_HDTV720P = 11'd3;    //Vertical Front Portch
  parameter HBKPRCH_HDTV720P = 11'd216;  //Horizontal Front Portch
  parameter VBKPRCH_HDTV720P = 11'd22;   //Vertical Front Portch
*/
  parameter HPIXELS_HDTV720P = 11'd1280; //Horizontal Live Pixels
  parameter VLINES_HDTV720P  = 11'd720;  //Vertical Live ines
  parameter HSYNCPW_HDTV720P = 11'd40;  //HSYNC Pulse Width
  parameter VSYNCPW_HDTV720P = 11'd5;    //VSYNC Pulse Width
  parameter HFNPRCH_HDTV720P = 11'd110;   //Horizontal Front Portch hotoha72
  parameter VFNPRCH_HDTV720P = 11'd5;    //Vertical Front Portch
  parameter HBKPRCH_HDTV720P = 11'd220;  //Horizontal Front Portch
  parameter VBKPRCH_HDTV720P = 11'd25;   //Vertical Front Portch

  //1024x768@60HZ
  parameter HPIXELS_XGA = 11'd1024; //Horizontal Live Pixels
  parameter VLINES_XGA  = 11'd768;  //Vertical Live ines
  parameter HSYNCPW_XGA = 11'd136;  //HSYNC Pulse Width
  parameter VSYNCPW_XGA = 11'd6;    //VSYNC Pulse Width
  parameter HFNPRCH_XGA = 11'd24;   //Horizontal Front Portch
  parameter VFNPRCH_XGA = 11'd3;    //Vertical Front Portch
  parameter HBKPRCH_XGA = 11'd160;  //Horizontal Front Portch
  parameter VBKPRCH_XGA = 11'd29;   //Vertical Front Portch

  //800x600@60HZ
  parameter HPIXELS_SVGA = 11'd800; //Horizontal Live Pixels
  parameter VLINES_SVGA  = 11'd600; //Vertical Live ines
  parameter HSYNCPW_SVGA = 11'd128; //HSYNC Pulse Width
  parameter VSYNCPW_SVGA = 11'd4;   //VSYNC Pulse Width
  parameter HFNPRCH_SVGA = 11'd40;  //Horizontal Front Portch
  parameter VFNPRCH_SVGA = 11'd1;   //Vertical Front Portch
  parameter HBKPRCH_SVGA = 11'd88;  //Horizontal Front Portch
  parameter VBKPRCH_SVGA = 11'd23;  //Vertical Front Portch

  //640x480@60HZ
  parameter HPIXELS_VGA = 11'd640; //Horizontal Live Pixels
  parameter VLINES_VGA  = 11'd480; //Vertical Live ines
  parameter HSYNCPW_VGA = 11'd96;  //HSYNC Pulse Width
  parameter VSYNCPW_VGA = 11'd2;   //VSYNC Pulse Width
  parameter HFNPRCH_VGA = 11'd16;  //Horizontal Front Portch
  parameter VFNPRCH_VGA = 11'd11;  //Vertical Front Portch
  parameter HBKPRCH_VGA = 11'd48;  //Horizontal Front Portch
  parameter VBKPRCH_VGA = 11'd31;  //Vertical Front Portch
