#ifndef DMA_H
#define DMA_H

#include "xaxidma.h"
#include "xparameters.h"
#include "xil_exception.h"
#include "xscugic.h"
#include "xil_printf.h"

#define DMA_DEV_ID XPAR_AXIDMA_0_DEVICE_ID
#define RX_INTR_ID XPAR_FABRIC_AXIDMA_0_S2MM_INTROUT_VEC_ID
#define TX_INTR_ID XPAR_FABRIC_AXIDMA_0_MM2S_INTROUT_VEC_ID
#define HASH_INTR_ID 63U
#define INTC_DEVICE_ID XPAR_SCUGIC_SINGLE_DEVICE_ID
#define DDR_BASE_ADDR XPAR_PS7_DDR_0_S_AXI_BASEADDR     //0x00100000
#define MEM_BASE_ADDR (DDR_BASE_ADDR + 0x1000000)       //0x01100000
#define TX_BUFFER_BASE (MEM_BASE_ADDR + 0x00100000)     //0x01200000
#define RX_BUFFER_BASE (MEM_BASE_ADDR + 0x00300000)     //0x01400000
//#define TX_BUFFER_BASE 0x10000000
//#define RX_BUFFER_BASE 0x10100000
#define RESET_TIMEOUT_COUNTER 10000 //复位时间
//#define TEST_START_VALUE 0x0 //测试起始值
#define MAX_SEND_PKT_LEN 1024 // 一次最多发送1024B
#define MAX_REC_PKT_LEN   400 // 一次最多接收400B

int dma_init();
void dma_cleanup();
int  dma_write_1(const uint8_t* in, int inlen);
int  dma_write_2(const uint8_t* in0, const uint8_t* in1, int inlen);
int  dma_read_1(uint8_t* dout, int outlen);
int  dma_read_2(uint8_t* dout0, uint8_t* dout1, int outlen);

#endif
