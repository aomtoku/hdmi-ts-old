#include "xbasic_types.h"
#include "xio.h"
#include "mb_interface.h"
#include "xparameters.h"

// MICROBLAZE_INTC define
#define MICROBLAZE_0_INTC_ISR        XPAR_MICROBLAZE_0_INTC_BASEADDR        // Interrupt Status Register
#define MICROBLAZE_0_INTC_IPR        XPAR_MICROBLAZE_0_INTC_BASEADDR+0x4    // Interrupt Pending Register
#define MICROBLAZE_0_INTC_IER        XPAR_MICROBLAZE_0_INTC_BASEADDR+0x8    // Interrupt Enable Register
#define MICROBLAZE_0_INTC_IAR        XPAR_MICROBLAZE_0_INTC_BASEADDR+0xC    // Interrupt Acknowledge Register
#define MICROBLAZE_0_INTC_SIE        XPAR_MICROBLAZE_0_INTC_BASEADDR+0x10    // Set Interrupt Enable Bits
#define MICROBLAZE_0_INTC_CIE        XPAR_MICROBLAZE_0_INTC_BASEADDR+0x14    // Clear Interrupt Enable Bits
#define MICROBLAZE_0_INTC_IVR        XPAR_MICROBLAZE_0_INTC_BASEADDR+0x18    // Interrupt Vector Register
#define MICROBLAZE_0_INTC_MER        XPAR_MICROBLAZE_0_INTC_BASEADDR+0x1C    // Master Enable Register

// LED 8bits
#define XPAR_LEDS_8BITS_DATA    XPAR_LEDS_8BITS_BASEADDR
#define XPAR_LEDS_8BITS_TRI        XPAR_LEDS_8BITS_BASEADDR+0x4

// AXI_TIMER define
#define AXI_TIMER_0_TCSR0    XPAR_AXI_TIMER_0_BASEADDR    // Control/Status Register 0
#define AXI_TIMER_0_TLR0    XPAR_AXI_TIMER_0_BASEADDR+0x4    // Load Register 0
#define AXI_TIMER_0_TCR0    XPAR_AXI_TIMER_0_BASEADDR+0x8    // Timer/Counter Register 0
#define AXI_TIMER_0_TCSR1    XPAR_AXI_TIMER_0_BASEADDR+0x10    // Control/Status Register 1
#define AXI_TIMER_0_TLR1    XPAR_AXI_TIMER_0_BASEADDR+0x14    // Load Register 1
#define AXI_TIMER_0_TCR1    XPAR_AXI_TIMER_0_BASEADDR+0x18    // Timer/Counter Register 1

#define ENABLE_ALL_TIMERS                (0x1<<10)
#define ENABLE_PULSE_WIDTH_MODULATION    (0x1<<9)
#define    TIMER_INTERRUPT                    (0x1<<8)
#define ENABLE_TIMER                    (0x1<<7)
#define ENABLE_INTERRUPT                (0x1<<6)
#define LOAD_TIMER                        (0x1<<5)
#define AUTO_RELOAD_HOLD_TIMER            (0x1<<4)
#define ENABLE_EXT_CAPTURE_TRIG            (0x1<<3)
#define ENABLE_EXT_GENERATE_SIG            (0x1<<2)
#define DOWN_UP_COUNT_TIMER                (0x1<<1)
#define TIMER_MODE_CAP_GENE                (0x1)

int interrupt = 0;

void axi_intc_init() {
    *(volatile unsigned int *)(MICROBLAZE_0_INTC_IER) = 0x1;    // int0 enable
    *(volatile unsigned int *)(MICROBLAZE_0_INTC_MER) = 0x3;    // IRQ Enable
}

void axi_timer_init(){
    *(volatile unsigned int *)(AXI_TIMER_0_TLR0) = 100000000; // 100MHzで1秒
    *(volatile unsigned int *)(AXI_TIMER_0_TCSR0) = ENABLE_ALL_TIMERS | LOAD_TIMER; // TLR0へロード
    *(volatile unsigned int *)(AXI_TIMER_0_TCSR0) = ENABLE_ALL_TIMERS | ENABLE_TIMER | ENABLE_INTERRUPT | DOWN_UP_COUNT_TIMER; // GenerateモードでDWONカウント、割り込みあり
}

void timer_int_handler(void * arg) {
    interrupt = 1;
}

int main()
{
    unsigned int data;

    *(volatile unsigned int *)(XPAR_LEDS_8BITS_TRI) = 0;    // 出力設定
    *(volatile unsigned int *)(XPAR_LEDS_8BITS_DATA) = 1;

    axi_timer_init();    // axi_timerの初期化
    axi_intc_init();     // axi_intcの初期化

    // 割り込みハンドラ登録、割り込み許可
    microblaze_register_handler(timer_int_handler, (void *) 0);
    microblaze_enable_interrupts();

    for(data=0; data>=0; data++){
        *(volatile unsigned int *)(XPAR_LEDS_8BITS_DATA) = data;
        // axi_timter割り込み待ち
        interrupt = 0;
        while(interrupt==0);
        *(volatile unsigned int *)(AXI_TIMER_0_TCSR0) = ENABLE_ALL_TIMERS | ENABLE_TIMER | ENABLE_INTERRUPT | DOWN_UP_COUNT_TIMER | TIMER_INTERRUPT;    // 割り込みクリア
        *(volatile unsigned int *)(MICROBLAZE_0_INTC_IAR) = 0x1;    // int0 clear

        *(volatile unsigned int *)(AXI_TIMER_0_TLR0) = 100000000; // 1秒 1000,000,000ns/10ns = 100,000,000
        *(volatile unsigned int *)(AXI_TIMER_0_TCSR0) = ENABLE_ALL_TIMERS | LOAD_TIMER; // TLR0へロード、割り込みクリア
        *(volatile unsigned int *)(AXI_TIMER_0_TCSR0) = ENABLE_ALL_TIMERS | ENABLE_TIMER | ENABLE_INTERRUPT | DOWN_UP_COUNT_TIMER; // GenerateモードでDWONカウント、割り込みあり
    }

    return 0;
}
