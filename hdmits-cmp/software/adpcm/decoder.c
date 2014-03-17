#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>

#define CLIP(X) ( (X) > 255 ? 255 : (X) < 0 ? 0 : X)
#define DCAD(X,Y,Z) ( (Y) ?  Z + CLIP( (127 * (2 * X + 1)) / 8) :  Z - CLIP( (127 * (2 * X + 1)) / 8))
#define ENAD(X,Y,Z) ( (Y) ?  Z + CLIP( (127 * (2 * X + 1)) / 8) :  Z - CLIP( (127 * (2 * X + 1)) / 8))


int main(int argc, char *argv[]){
	int fd,size;
	int frame = 1280*720*2;
	char *bf;
	bf = (char *)malloc(frame);

	if(argc < 1){
		printf("usage: ./decoder <input file>\n");
		return 0;
	}

	if((fd = open(argv[1], O_RDONLY)) < 0){
		printf("Error: Cannot open %s\n",argv[1]);
		return 1;
	} 
	
	unsigned int cnt = 0, line = 0;
	unsigned long buf;
	unsigned int fp;
	int y0,y1,zp;
	while((size = read(fd,&buf, 3)) > 0){
		//printf("%d,%d: %#08x\n",line,cnt, (unsigned int)buf);
		fp = (unsigned int)buf;
		y0 = ((fp & 0xff));
		cb = ((fp & 0xff00)) >> 8;
		zp = ((fp & 0xff0000)) >> 16;
		
		yz = ((zp & 0x7));
		cz = ((zp & 0x70)) >> 4;

		yz = DCAD(yz,(zp & 0x8),y0);
		cz = DCAD(cz,(((zp & 0x80)) >> 7),y0);
		
		char a,b,c,d;
		a = ((y0 & 0xff));
		b = ((cb & 0xff));
		c = ((yz & 0xff));
		d = ((cz & 0xff));
		printf("%c%c%c%c",a,b,c,d);
	}
	return 0;
}
