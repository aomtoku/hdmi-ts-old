#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>

int main(int argc, char *argv[]){
	int fd,size;
	int frame = 1280*720*2;
	char *bf;
	bf = (char *)malloc(frame);

	if((fd = open(argv[1], O_RDONLY)) < 0){
		printf("Error: Cannot open %s\n",argv[1]);
		return 1;
	} 
	
	unsigned int cnt = 0, line = 0;
	unsigned long buf;
	unsigned int fp;
	unsigned short ff;
	while((size = read(fd,&buf,sizeof(unsigned int))) > 0){
		//printf("%d,%d: %#08x\n",line,cnt, (unsigned int)buf);
		fp = (unsigned int)buf;
		if(cnt < 1280 & line < 720){
			ff = ((fp & 0xffff00)) >> 8;
			//printf("%d,%d : %x\n",line,cnt,ff);
			char a,b;
			a = ((ff & 0xff));
			b = ((ff & 0xff00)) >> 8;
			printf("%c%c",a,b);
			//printf("%x\n",ff);
			*bf = ((fp & 0xffff));
			bf += 2;
		}
		
		if(cnt == 1919){
			cnt = 0;
			line++;
		} else {
			cnt++;
		}
		
	}
	return 0;
}
