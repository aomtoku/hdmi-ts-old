#include <stdio.h>


void HBackPorch(int vsyn){
    int cnt;
    for(cnt=0;cnt<110;cnt++){
	printf("%d0\n",vsyn);
    }
}


void HPulseWidth(int vsyn){
    int cnt;
    for(cnt=0;cnt<40;cnt++){
	printf("%d1\n",vsyn);
    }
}


void HFrontPorch(int vsyn){
    int cnt;
    for(cnt=0;cnt<220;cnt++){
	printf("%d0\n",vsyn);
    }
}

void HActiveVideo(int on, int vsyn){
    int cnt;
    int color = 0;
    for(cnt=0;cnt<1280;cnt++){
	if(color == 256)
	    color = 0;
	if(on)
	    printf("00\n");
	else
	    printf("%d0\n",vsyn);
	color++;
    }
}


void VBackPorch(void){
    int cnt;
    int vsyn = 0;
    for(cnt=0;cnt<5;cnt++){
	HBackPorch(vsyn);
	HPulseWidth(vsyn);
	HFrontPorch(vsyn);
	HActiveVideo(0,vsyn);
    }
}


void VPulseWidth(void){
    int cnt;
    int vsyn = 1;
    for(cnt=0;cnt<5;cnt++){
	HBackPorch(vsyn);
	HPulseWidth(vsyn);
	HFrontPorch(vsyn);
	HActiveVideo(0,vsyn);
    }
}

void VFrontPorch(void){
    int cnt;
    int vsyn = 0;
    for(cnt=0;cnt<20;cnt++){
	HBackPorch(vsyn);
	HPulseWidth(vsyn);
	HFrontPorch(vsyn);
	HActiveVideo(0,vsyn);
    }
}


void VActiveLine(void){
    int cnt;
    int vsyn = 0;
    for(cnt=0;cnt<720;cnt++){
	HBackPorch(vsyn);
	HPulseWidth(vsyn);
	HFrontPorch(vsyn);
	HActiveVideo(1,vsyn);
    }
}

int main(){
    int i;
    for(i=0;i<2;i++){
    	VBackPorch();
    	VPulseWidth();
    	VFrontPorch();
    	VActiveLine();
    }
    return 0;
}
