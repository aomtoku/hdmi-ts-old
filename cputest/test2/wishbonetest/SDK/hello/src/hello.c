/*
 * hello.c
 *
 *  Created on: 2014/04/23
 *      Author: aom
 */

#include <stdio.h>
#include "platform.h"
#include "xbasic_types.h"
#include "xiomodule.h"

int main()
{
    u32 uDevId = XPAR_IOMODULE_0_DEVICE_ID;
    XIOModule mcsIOMdule;
    init_platform();
    //MicroBlaze MCS IOModule Initialize
    XIOModule_Initialize(&mcsIOMdule, uDevId);
    //set GPO1
    XIOModule_DiscreteWrite(&mcsIOMdule, 1,2);
    //UART
    print("Hello World\n\r");
    cleanup_platform();
    return 0;
}
