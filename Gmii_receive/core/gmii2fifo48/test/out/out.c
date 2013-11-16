#include<stdio.h>

int main(){
    int a;
    for(a=0;a<320;a++){
	printf("1_00 // DATA[%d] : Blue\n",a);
	printf("1_00 // DATA[%d] : Green\n",a);
	printf("1_e2 // DATA[%d] : Red\n",a);
    }
    return 0;
}
