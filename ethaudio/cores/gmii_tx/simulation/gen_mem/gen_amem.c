/***************************************
 *
 *  Generate Audio FIFO memory
 *
 *    Yuta Tokusashi
 * ************************************/

#include <stdio.h>

void adata(int clk){
	int a,h;
	a = 0;
	/* Clock Cycle of Start Audio Data Enable */
	printf("%06x\n",clk);
	/* Auido Data 32clock cycles */
	for(h = 0; h < 32; h++){
	  printf("%06x\n",a);
	  a++;
	}
}

int main(){
	int h,v;
	int a = 0;
  for(v = 0; v < 720; v++){
	  //printf ("v:%d, h:%d  ",v,h); //Debug code
		adata(1579);
	}
  for(v = 0; v < 30; v++){
		if(v == 1){
			adata(20);
			adata(60);
			adata(92);
			adata(122);
			adata(154);
			adata(186);
			adata(280);
			adata(312);
			adata(400);
			adata(500);
			adata(600);
		} else {
		  /* Clock Cycle of Start Audio Data Enable */
			adata(1579);
		}
	}
	
	return 0;
}
