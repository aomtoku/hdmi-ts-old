#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>

#define CLIP(X) ( (X) > 7 ? 7 : (X) < 0 ? 0 : X)
#define DCAD(X,Y,Z) ( (Y) ?  Z + CLIP( (127 * (2 * X + 1)) / 8) :  Z - CLIP( (127 * (2 * X + 1)) / 8))
#define ENAD(X,Y,Z) ( (Y) ?  Z + CLIP( (127 * (2 * X + 1)) / 8) :  Z - CLIP( (127 * (2 * X + 1)) / 8))


int main(int argc, char *argv[]){
	int fd,size;
	int frame = 1280*720*2;
	char *bf;
	bf = (char *)malloc(frame);

	if(argc < 1){
		printf("usage : ./encoder <input file> \n");
		return 0;
	}

	if((fd = open(argv[1], O_RDONLY)) < 0){
		printf("Error: Cannot open %s\n",argv[1]);
		return 1;
	} 
	
	unsigned int cnt = 0, line = 0;
	unsigned long buf;
	unsigned int fp;
	int y0,y1,cb,cr;
	int dfy, dfc;
	while((size = read(fd,&buf,sizeof(unsigned int))) > 0){
		//printf("%d,%d: %#08x\n",line,cnt, (unsigned int)buf);
		fp = (unsigned int)buf;
		y0 = ((fp & 0xff));
		cb = ((fp & 0xff00)) >> 8;
		y1 = ((fp & 0xff0000)) >> 16;
		cr = ((fp & 0xff000000)) >> 24;
		
		char a,b,c;
		a = ((y0 & 0xff));
		b = ((cb & 0xff));
		//c = ((y1 & 0xf)) | ((cr & 0xf)) << 4;
		
		dfy = y0 - y1;
		dfc = cb - cr;
		if(dfy > 0){
			dfy = (dfy * 8 + 127)/254;
			dfy = CLIP(dfy);
			dfy = ((dfy | 0x8));
		} else {
			dfy = y1 - y0;
			dfy = (dfy * 8 + 127)/254;
			dfy = CLIP(dfy);
		}
		if(dfc > 0){
			dfc = (dfc * 8 + 127)/254;
			dfc = CLIP(dfc);
			dfc = ((dfc | 0x8));
		} else {
			dfc = cr -cb;
			dfc = (dfc * 8 + 127)/254;
			dfc = CLIP(dfc);
		}
		
		c = ((dfy & 0xff)) | ((dfc & 0xff)) << 8;

		printf("%c%c%c",a,b,c);
	}
	return 0;
}
