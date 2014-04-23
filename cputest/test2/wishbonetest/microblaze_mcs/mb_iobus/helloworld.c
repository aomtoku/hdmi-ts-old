//*****************************************************************************
// File Name            : helloworld.c
//-----------------------------------------------------------------------------
// Function             : for MicroBlaze MCS & IO bus 
//                        
//-----------------------------------------------------------------------------
// Designer             : yokomizo 
//-----------------------------------------------------------------------------
// History
// -.-- 2013/03/11
//*****************************************************************************
#include <stdio.h>
#include "platform.h"
#include "xbasic_types.h"
#include "XIOModule.h"

#define IOBUS_REG_OFFSET    0x0
#define IOBUS_BRAM_OFFSET   0x1000

int main()
{
    u32 uDevId = XPAR_IOMODULE_0_DEVICE_ID;
    XIOModule mcsIOMdule;
    u8 read_data_8;
    u32 read_data_32;
    init_platform();
    //MicroBlaze MCS IOModule Initialize
    XIOModule_Initialize(&mcsIOMdule, uDevId);
    //write iobus_reg
    XIOModule_IoWriteByte(&mcsIOMdule,(IOBUS_REG_OFFSET + 0x0), 0x31);
    read_data_8 = XIOModule_IoReadByte(&mcsIOMdule,(IOBUS_REG_OFFSET + 0));
    //read_data_8-> UART
    XIOModule_Send(&mcsIOMdule, &read_data_8,1);
    //read BRAM
    read_data_32= XIOModule_IoReadWord(&mcsIOMdule,(IOBUS_BRAM_OFFSET + 0));
    XIOModule_IoWriteWord(&mcsIOMdule,(IOBUS_BRAM_OFFSET + 0x0), 0x0);

    return 0;
}
