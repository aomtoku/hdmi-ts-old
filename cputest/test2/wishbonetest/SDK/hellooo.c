/*
 * hello.c
 *
 *  Created on: 2014/04/23
 *      Author: aom
 */

#include <stdio.h>
#include "platform.h"
#include "xbasic_types.h"
#include "XIOModule.h"

int main(){
	u32 uDevID = XPAR_IOMODULE_0_DEVICE_ID;
	XIOModule mcsIOModule;
	init_platform();

	// Initialize
	XIOModule_Initialize(&mcsIOModule, uDevID);

	// Set GPO1
	XIOModule_DiscreteWrite(&mcsIOModule, 1, 2);

	// UART
	print("Hello World! aom! \n\r");
	cleanup_platform();
	return 0;
}

