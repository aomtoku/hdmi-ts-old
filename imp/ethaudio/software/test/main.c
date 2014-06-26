/*****************************************************
 *						     *
 *						     *
 *						     *
 *
 *  ### CHECK FIREWALLs on your system               *
 ****************************************************/		


/* incldue file for Standard Linbrary for C */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

/* include file for socket communication */
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

/* include file for FrameBuffer */
#include <linux/fb.h>
#include <linux/fs.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

/* DEFINE the Parameter */
#define DEVICE_NAME "/dev/fb0"


#define BIT 8
#define YUVMODE
#define DATA_YUV

#ifdef DATA_YUV

#define DATA_SIZE 1280
#define PIXEL_PER_PACKET 640
#define RGB_BYTE 2
#define DISPLAY_XRES 1280
#define DISPLAY_YRES 1440

#else

#define DATA_SIZE 960
#define PIXEL_PER_PACKET 320
#define RGB_BYTE 3
#define DISPLAY_XRES 1280
#define DISPLAY_YRES 720


#endif

#define CLIP(X) ( (X) > 255 ? 255 : (X) < 0 ? 0 : X)

// YCbCr -> RGB
#define CYCbCr2R(Y, Cb, Cr) CLIP( Y + ( 91881 * Cr >> 16 ) - 179 )
#define CYCbCr2G(Y, Cb, Cr) CLIP( Y - (( 22544 * Cb + 46793 * Cr ) >> 16) + 135)
#define CYCbCr2B(Y, Cb, Cr) CLIP( Y + (116129 * Cb >> 16 ) - 226 )

#define AUXSIZE 36
#define ID 2


struct packet{
		unsigned char packetinfo;
		unsigned char data[1500];
};

struct msg {
	uint8_t type;
	uint8_t value;
	uint16_t packet_size;
	char data[1024];       // 固定長にする
};
/*
struct video {
    unsigned short int xyres_screen;
    unsigned char color[DATA_SIZE];
		unsigned short int auxid;
		unsigned char aux[AUXSIZE];
};

struct vidad {
    unsigned short int xyres_screen;
    unsigned char color[DATA_SIZE];
		unsigned char *auxd;
}

struct audio {
		unsigned short int auxid;
		unsigned char aux[AUXSIZE];
		char *next;
};*/

int BindUDPconnect(int sock, struct sockaddr_in addr, struct sockaddr_in recv, int port){
     sock = socket(AF_INET, SOCK_DGRAM, 0);
     
     addr.sin_family = AF_INET;
     addr.sin_port = htons(port);
     addr.sin_addr.s_addr = INADDR_ANY;
    
     if(bind(sock, (struct sockaddr *)&addr, sizeof(addr)) == -1){
	     fprintf(stderr,"cannot bind\n");
       exit(1);
     }
    return sock;
}

int OpenFrameBuffer(int fd){
     fd = open(DEVICE_NAME, O_RDWR);
     if(!fd){
	 fprintf(stderr,"cannot open the FrameBuffer '%s'\n",DEVICE_NAME);
	 exit(1);
     }

     return fd;
}


#define DEBUG

void LoopRecvPacket(int sock, struct sockaddr_in recv, char *buf, struct fb_var_screeninfo vinfo, int line_len, int bpp){
     struct packet rec_packet;
printf("%d at %s\n",__LINE__,__FILE__);
     int rec;
     int xres_screen, yres_screen;
		 unsigned int aux_clk;
     socklen_t sin_size = sizeof(struct sockaddr_in);
		 int acnt;
		 int pcktnum = 0;
		 int i;
     while(1){
	     if((rec = recvfrom(sock, &rec_packet, sizeof(struct packet), 0,(struct sockaddr *)&recv, &sin_size)) == -1){
	       fprintf(stderr, "cannot receive a packet \n");
	       exit(1);
	     }
			 printf("pcknum[%d] ",pcktnum);
			 if(rec_packet.packetinfo == 2){
         acnt = (rec - 1283) / 38;
				 yres_screen = ((rec_packet.data[0] & 0xff) | ((rec_packet.data[1] & 0x0f) << 8));
         xres_screen = (((rec_packet.data[1] & 0xf0) >> 4) & 1) * 640;
				 printf("Resol: %d %d ",yres_screen,xres_screen);
         i = 1;
				 for(;acnt == 1; acnt--){
					 aux_clk = ((rec_packet.data[1284+(38*i)] & 0x0f) << 8);
					 aux_clk = (aux_clk | rec_packet.data[1283+(38*i)]);
				   i++;
					 printf("Clock: %d ",aux_clk);
				 }
				 i = 1;
				 printf("\n");
			 } else if(rec_packet.packetinfo == 0){
				 yres_screen = ((rec_packet.data[0] & 0xff) | ((rec_packet.data[1] & 0x0f) << 8));
         xres_screen = (((rec_packet.data[1] & 0xf0) >> 4) & 1) * 640;
				 printf("Resol: %d %d \n",yres_screen,xres_screen);
			 } else { // Audio Packet 
			   acnt = (rec - 1) / 38;
				 i = 1;
				 for(;acnt == 1; acnt--){
					 aux_clk = ((rec_packet.data[1+(38*i)] & 0x0f) << 8);
					 aux_clk = (aux_clk | rec_packet.data[0+(38*i)]);
				   i++;
					 printf("Clock: %d ",aux_clk);
				 }
				 i = 1;
				 printf("\n");
			 }
   	 pcktnum++;
     }
//printf("%04d %04d\n",xres_screen,yres_screen);
}

int main(int argc, char **argv)
{
    /* Check the Augments*/
    if(argc < 2){
	fprintf(stderr,"usage : ./a.out <port>");
	exit(1);
    }
    /* open network socket for UDP */
     int sock = 0;
     struct sockaddr_in addr;
     struct sockaddr_in recv;
     int port = atoi(argv[1]);


     sock = BindUDPconnect(sock,addr,recv,port);
     
     /* Open a DeviceFile of FrameBuffer */
     int fd = 0; 
     int screensize;
     fd = OpenFrameBuffer(fd);
     
     struct fb_var_screeninfo vinfo;
     struct fb_fix_screeninfo finfo;

     if(ioctl(fd,FBIOGET_FSCREENINFO, &finfo)){
	 fprintf(stderr, "cannot open fix info\n");
	 exit(1);
     }
     if(ioctl(fd,FBIOGET_VSCREENINFO, &vinfo)){
	 fprintf(stderr, "cannot open variable info\n");
	 exit(1);
     }
     
     int xres,yres,bpp,line_len;
     xres = vinfo.xres; yres = vinfo.yres; bpp = vinfo.bits_per_pixel;
     line_len = finfo.line_length;

     screensize = xres * yres * bpp / BIT;
     printf("RECVFRAM Atlys Ver0.1\n%d(pixel)x%d(line), %d(bit per pixel), %d(line length)\n",xres,yres,bpp,line_len);
     /* Handler if socket get a packet, it will be mapped on memory */ 
     
     char *buf =0;
     //buf = InitMemeoryMap(buf,screensize,fd);

     buf = (char *)mmap(0, screensize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
     if(buf < 0){
	 fprintf(stderr, "cannot get framebuffer");
	 exit(1);
     }
     
     /* Loop for Recvfrom SOCKET UDP */
     LoopRecvPacket(sock, recv, buf, vinfo, line_len, bpp);
     
     munmap(buf,screensize);

     close(fd);
     close(sock);

     return 0;
}
