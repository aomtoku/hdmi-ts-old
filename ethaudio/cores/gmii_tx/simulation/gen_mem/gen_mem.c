/***************************************
 *
 *  Generate FIFO memory
 *
 *   Yuta Tokusashi
 * ************************************/

#include <stdio.h>

int main(){
	int h,v;
	int a = 0;
  for(v = 0; v < 720; v++){
	  for(h = 0; h < 1280; h++){
			//printf ("v:%d, h:%d  ",v,h); //Debug code
		  printf("%03x_%03x_%06x\n",v,h,a);
			a++;
	  }
	}
	printf("\n");
	

	return 0;
}
