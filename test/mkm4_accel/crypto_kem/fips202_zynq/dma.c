#include "dma.h"


static XAxiDma axidma; //XAxiDma 实例
static XScuGic intc; //中断控制器的实例
volatile int tx_done; //发送完成标志
volatile int rx_done; //接收完成标志
volatile int error; //传输出错标志
volatile int hash_done;


//DMA TX 中断处理函数
static void tx_intr_handler(void *callback)
{
    int timeout;
    u32 irq_status;
    XAxiDma *axidma_inst = (XAxiDma *) callback;

    //读取待处理的中断
    irq_status = XAxiDma_IntrGetIrq(axidma_inst, XAXIDMA_DMA_TO_DEVICE);
    //确认待处理的中断
    XAxiDma_IntrAckIrq(axidma_inst, irq_status, XAXIDMA_DMA_TO_DEVICE);

    //Tx 出错
    if ((irq_status & XAXIDMA_IRQ_ERROR_MASK)) {
        error = 1;
        XAxiDma_Reset(axidma_inst);
        timeout = RESET_TIMEOUT_COUNTER;
        while (timeout) {
            if (XAxiDma_ResetIsDone(axidma_inst))
            break;
            timeout -= 1;
        }
        if (timeout == 0) xil_printf("tx_intr_handler : DMA reset fail.\n\r");
        return;
    }

    //Tx 完成
    if ((irq_status & XAXIDMA_IRQ_IOC_MASK))
    tx_done = 1;
}

//DMA RX 中断处理函数
static void rx_intr_handler(void *callback)
{
    u32 irq_status;
    int timeout;
    XAxiDma *axidma_inst = (XAxiDma *) callback;

    irq_status = XAxiDma_IntrGetIrq(axidma_inst, XAXIDMA_DEVICE_TO_DMA);
    XAxiDma_IntrAckIrq(axidma_inst, irq_status, XAXIDMA_DEVICE_TO_DMA);

    //Rx 出错
    if ((irq_status & XAXIDMA_IRQ_ERROR_MASK)) {
        error = 1;
        XAxiDma_Reset(axidma_inst);
        timeout = RESET_TIMEOUT_COUNTER;
        while (timeout) {
            if (XAxiDma_ResetIsDone(axidma_inst))
            break;
            timeout -= 1;
        }
        if (timeout == 0) xil_printf("rx_intr_handler : DMA reset fail.\n\r");
        return;
    }

    //Rx 完成
    if ((irq_status & XAXIDMA_IRQ_IOC_MASK))
    rx_done = 1;
}


static void hs_intr_handler(void* param) {
	hash_done = 1;
}

//建立 DMA 中断系统
// @param int_ins_ptr 是指向 XScuGic 实例的指针
// @param AxiDmaPtr 是指向 DMA 引擎实例的指针
// @param tx_intr_id 是 TX 通道中断 ID
// @param rx_intr_id 是 RX 通道中断 ID
// @return：成功返回 XST_SUCCESS，否则返回 XST_FAILURE
static int setup_intr_system(XScuGic * int_ins_ptr, XAxiDma * axidma_ptr, u16 tx_intr_id, u16 rx_intr_id, u16 hs_intr_id)
{
    int status;
    XScuGic_Config *intc_config;

    //初始化中断控制器驱动
    intc_config = XScuGic_LookupConfig(INTC_DEVICE_ID);
    if (NULL == intc_config) {
        return XST_FAILURE;
    }
    status = XScuGic_CfgInitialize(int_ins_ptr, intc_config, intc_config->CpuBaseAddress);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    //设置优先级和触发类型
    XScuGic_SetPriorityTriggerType(int_ins_ptr, tx_intr_id, 0xA0, 0x3);
    XScuGic_SetPriorityTriggerType(int_ins_ptr, rx_intr_id, 0xA0, 0x3);
    XScuGic_SetPriorityTriggerType(int_ins_ptr, hs_intr_id, 0xA0, 0x3);

    //为中断设置中断处理函数
    status = XScuGic_Connect(int_ins_ptr, tx_intr_id, (Xil_InterruptHandler) tx_intr_handler, axidma_ptr);
    if (status != XST_SUCCESS) {
        return status;
    }

    status = XScuGic_Connect(int_ins_ptr, rx_intr_id, (Xil_InterruptHandler) rx_intr_handler, axidma_ptr);
    if (status != XST_SUCCESS) {
    return status;
    }

    status = XScuGic_Connect(int_ins_ptr, hs_intr_id, (Xil_InterruptHandler) hs_intr_handler, (void*)0);
    if (status != XST_SUCCESS) {
    return status;
    }

    XScuGic_Enable(int_ins_ptr, tx_intr_id);
    XScuGic_Enable(int_ins_ptr, rx_intr_id);
    XScuGic_Enable(int_ins_ptr, hs_intr_id);

    //启用来自硬件的中断
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler) XScuGic_InterruptHandler, (void *) int_ins_ptr);
    Xil_ExceptionEnable();

    //使能 DMA 中断
    XAxiDma_IntrEnable(&axidma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);
    XAxiDma_IntrEnable(&axidma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);

    return XST_SUCCESS;
}

//此函数禁用 DMA 引擎的中断
static void disable_intr_system(XScuGic * int_ins_ptr, u16 tx_intr_id, u16 rx_intr_id, u16 hs_intr_id)
{
    XScuGic_Disconnect(int_ins_ptr, tx_intr_id);
    XScuGic_Disconnect(int_ins_ptr, rx_intr_id);
    XScuGic_Disconnect(int_ins_ptr, hs_intr_id);
}

static int wait_tx_done() {
	int timeout = RESET_TIMEOUT_COUNTER;
    while (!tx_done && !error) {
    	timeout = timeout - 1;
    	if (timeout == 0) {
    		xil_printf("wait_tx_done failed.\n\r");
    		break;
    	}
    }
    //传输出错
    if (error) {
        xil_printf("Failed test : transmit not done.\n\r");
        return XST_FAILURE;
    }
    return XST_SUCCESS;
}

static int wait_rx_done() {
	int timeout = RESET_TIMEOUT_COUNTER;
    while (!rx_done && !error){
    	timeout = timeout - 1;
    	if (timeout == 0) {
    		xil_printf("wait_rx_done failed.\n\r");
    		break;
    	}
    }
    
    //传输出错
    if (error) {
        xil_printf("Failed test : receive not done.\r\n");
        return XST_FAILURE;
    }
    return XST_SUCCESS;
}

int dma_init() {
    int status;
    XAxiDma_Config *config;

    config = XAxiDma_LookupConfig(DMA_DEV_ID);
    if (!config) {
        xil_printf("No config found for %d\r\n", DMA_DEV_ID);
        return XST_FAILURE;
    }

    //初始化 DMA 引擎
    status = XAxiDma_CfgInitialize(&axidma, config);
    if (status != XST_SUCCESS) {
        xil_printf("Initialization failed %d\r\n", status);
        return XST_FAILURE;
    }

    if (XAxiDma_HasSg(&axidma)) {
        xil_printf("Device configured as SG mode \r\n");
        return XST_FAILURE;
    }

    //建立中断系统
    status = setup_intr_system(&intc, &axidma, TX_INTR_ID, RX_INTR_ID, HASH_INTR_ID);
    if (status != XST_SUCCESS) {
        xil_printf("Failed intr setup\r\n");
        return XST_FAILURE;
    }
    return XST_SUCCESS;

}

void dma_cleanup() {
    disable_intr_system(&intc, TX_INTR_ID, RX_INTR_ID, HASH_INTR_ID);
}

int dma_write_1(const uint8_t* in, int inlen) {
    int status, length, tmp;
    uint8_t* tx_buffer_ptr;
    uint32_t* tx_array;
    tx_array = (uint32_t *) TX_BUFFER_BASE;
    tx_buffer_ptr = (uint8_t *) TX_BUFFER_BASE;
    tx_done = 0;
    error = 0;
    // re-caculate inlen
    if (inlen & 0x3) {
        tmp = inlen >> 2;
        tx_array[tmp] = 0;
        tmp = tmp+1;
        length = (tmp << 2);
    } else {
        length = inlen;
    }

    Xil_DCacheFlushRange((UINTPTR) tx_buffer_ptr, length); //刷新 Data Cache
    memcpy(tx_buffer_ptr, in, inlen);

    status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) tx_buffer_ptr, length, XAXIDMA_DMA_TO_DEVICE);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    status = wait_tx_done();
    return status;
}

int dma_write_2(const uint8_t* in0, const uint8_t* in1, int inlen) {
    int status, length, tmp, length_x2;
    uint8_t* tx_buffer_ptr;
    uint32_t* tx_array;
    tx_array = (uint32_t *) TX_BUFFER_BASE;
    tx_buffer_ptr = (uint8_t *) TX_BUFFER_BASE;
    tx_done = 0;
    error = 0;

    // re-caculate inlen
    if (inlen & 0x3) {
        tmp = inlen >> 2;
        tx_array[tmp] = 0;
        tx_array[tmp*2+1] = 0;
        tmp = tmp+1;
        length = (tmp << 2);
    } else {
        length = inlen;
    }
    length_x2 = length * 2;

    memcpy(tx_buffer_ptr, in0, inlen);
    memcpy(tx_buffer_ptr+length, in1, inlen);
    Xil_DCacheFlushRange((UINTPTR) tx_buffer_ptr, length_x2); //刷新 Data Cache
    status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) tx_buffer_ptr, length_x2, XAXIDMA_DMA_TO_DEVICE);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    status = wait_tx_done();
    return status;
}

int dma_read_2(uint8_t* dout0, uint8_t* dout1, int outlen) {
    int status;
    rx_done = 0;
    error = 0;
    uint8_t *rx_buffer_ptr;
    rx_buffer_ptr = (uint8_t *) RX_BUFFER_BASE;

    status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) rx_buffer_ptr, MAX_REC_PKT_LEN, XAXIDMA_DEVICE_TO_DMA);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    Xil_DCacheInvalidateRange((UINTPTR) rx_buffer_ptr, MAX_REC_PKT_LEN); //刷新 Data Cache
    status = wait_rx_done();
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }
    memcpy(dout0, rx_buffer_ptr, outlen);
    memcpy(dout1, rx_buffer_ptr+200, outlen);
    return XST_SUCCESS;
}

int dma_read_1(uint8_t* dout, int outlen) {
    int status, i;
    rx_done = 0;
    error = 0;
    uint8_t *rx_buffer_ptr;
    uint32_t *rx_array;
    uint32_t output[50] = {0};
    rx_array = (uint32_t*) RX_BUFFER_BASE;
    rx_buffer_ptr = (uint8_t *) RX_BUFFER_BASE;
    status = XAxiDma_SimpleTransfer(&axidma, (UINTPTR) rx_buffer_ptr, MAX_REC_PKT_LEN, XAXIDMA_DEVICE_TO_DMA);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    Xil_DCacheFlushRange((UINTPTR) rx_buffer_ptr, MAX_REC_PKT_LEN); //刷新 Data Cache
    status = wait_rx_done();
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    for (i = 0; i < 50; i++) {
        output[i] = rx_array[i] ^ rx_array[i+50];
    }
    memcpy(dout, (uint8_t*)output, outlen);
    return XST_SUCCESS;
}
