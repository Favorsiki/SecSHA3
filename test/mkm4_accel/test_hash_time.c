#include <stdint.h>
#include <stdbool.h>
//#include <stdio.h>
#include <string.h>
#include <sleep.h>

#include "api.h"
#include "pqm4-hal.h"
#include "xparameters.h"
#include "xil_io.h"
#include "sechash.h"
#include "dma.h"

unsigned long long hash_cycles;
unsigned long long ntt_cycles, intt_cycles, poly_arith_cycles;

unsigned long long cbd_cycles;
unsigned long long xof_cycles;
unsigned long long enc_cycles;
unsigned long long dec_cycles;
unsigned long long g_cycles;
unsigned long long A2A_10_1_cycles;
unsigned long long A2A_13_10_cycles;
unsigned long long A2A_10_4_cycles;
unsigned long long gen_A_cycles;
unsigned long long mask_comp_cycles;
unsigned long long poly_enc_cycles;
unsigned long long poly_dec_cycles;
unsigned long long rng_cycles;
unsigned long long rng_calls = 0;

bool trigger = false;
uint8_t en_rand = 1;

#define UART0_DEVICE_ID XPAR_UARTLITE_0_DEVICE_ID
#define UART1_DEVICE_ID XPAR_UARTLITE_1_DEVICE_ID
#define UART0_BAUD_RATE 115200
#define UART1_BAUD_RATE 115200

uint8_t buf_1[1280]={0}, buf_2[1280]={0};
uint8_t out_1[600], out_2[600];

int main () { // 559310 cycles(50MHZ)  375354 cycles(100MHZ)
    uint64_t t0, t1;
    uint32_t h1;
	dma_init();

	t0 = hal_get_time();
    // [1] : h_mode=0 , len =0x20 (hash_h)
    unmk_sha3(out_1, 32, buf_1, 0x20, SHA3_256, SHA3_256_RATE);

    // [2] : h_mode=B , len =0x21 (cbd_s)
    mask_sha3(out_1, out_2, SHAKE256_RATE, buf_1, buf_2, 0x21, SHAKE256_MASK, SHAKE256_RATE);

    // [3] : h_mode=B , len =0x21 (cbd_s)
    mask_sha3(out_1, out_2, SHAKE256_RATE, buf_1, buf_2, 0x21, SHAKE256_MASK, SHAKE256_RATE);

    // [4] : h_mode=B , len =0x21 (cbd_s)
    mask_sha3(out_1, out_2, SHAKE256_RATE, buf_1, buf_2, 0x21, SHAKE256_MASK, SHAKE256_RATE);

    // [5] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [6] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [7] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [8] : h_mode=B , len =0x21 (cbd_e)
    mask_sha3(out_1, out_2, SHAKE256_RATE, buf_1, buf_2, 0x21, SHAKE256_MASK, SHAKE256_RATE);

    // [9] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [10] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [11] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [12] : h_mode=B , len =0x21 (cbd_e)
    mask_sha3(out_1, out_2, SHAKE256_RATE, buf_1, buf_2, 0x21, SHAKE256_MASK, SHAKE256_RATE);

    // [13] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [14] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [15] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [16] : h_mode=B , len =0x21 (cbd_e)
    mask_sha3(out_1, out_2, SHAKE256_RATE, buf_1, buf_2, 0x21, SHAKE256_MASK, SHAKE256_RATE);

    // [17] : h_mode=0 , len =0x4a0 (h_pk)
    unmk_sha3(out_1, 32, buf_1, 0x4a0, SHA3_256, SHA3_256_RATE);

    // [18] : h_mode=0 , len =0x20 (h_m)
    unmk_sha3(out_1, 32, buf_1, 0x20, SHA3_256, SHA3_256_RATE);

    // [19] : h_mode=0 , len =0x4a0 (h_pk)
    unmk_sha3(out_1, 32, buf_1, 0x4a0, SHA3_256, SHA3_256_RATE);

    // [20] : h_mode=1 , len =0x40 (g)
    unmk_sha3(out_1, 64, buf_1, 0x40, SHA3_512, SHA3_512_RATE);

    // [21] : h_mode=3 , len =0x21 (cbd_r)
    unmk_sha3(out_1, SHAKE256_RATE, buf_1, 0x21, SHAKE256, SHAKE256_RATE);

    // [22] : h_mode=3 , len =0x21 (cbd_r)
    unmk_sha3(out_1, SHAKE256_RATE, buf_1, 0x21, SHAKE256, SHAKE256_RATE);

    // [23] : h_mode=3 , len =0x21 (cbd_r)
    unmk_sha3(out_1, SHAKE256_RATE, buf_1, 0x21, SHAKE256, SHAKE256_RATE);

    // [24] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [25] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [26] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [27] : h_mode=3 , len =0x21 (cbd_e1)
    unmk_sha3(out_1, SHAKE256_RATE, buf_1, 0x21, SHAKE256, SHAKE256_RATE);

    // [28] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [29] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [30] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [31] : h_mode=3 , len =0x21 (cbd_e1)
    unmk_sha3(out_1, SHAKE256_RATE, buf_1, 0x21, SHAKE256, SHAKE256_RATE);

    // [32] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [33] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [34] : h_mode=2 , len =0x22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [35] : h_mode=3 , len =0x21 (cbd_e1)
    unmk_sha3(out_1, SHAKE256_RATE, buf_1, 0x21, SHAKE256, SHAKE256_RATE);

    // [36] : h_mode=3 , len =0x21 (cbd_e2)
    unmk_sha3(out_1, SHAKE256_RATE, buf_1, 0x21, SHAKE256, SHAKE256_RATE);

    // [37] : h_mode=0 , len =0x4a0 (h_pk)
    unmk_sha3(out_1, 32, buf_1, 0x4a0, SHA3_256, SHA3_256_RATE);

    // [38] : h_mode=3 , len =0x40 (kdf)
    unmk_sha3(out_1, 32, buf_1, 0x40, SHAKE256, SHAKE256_RATE);

    // [39] : h_mode=9 , len =0x40 (g_mask)
    mask_sha3(out_1, out_2, SHA3_512_RATE, buf_1, buf_2, 0x40, SHA3_512_MASK, SHA3_512_RATE);

    // [40] : h_mode=B , len =0x21 (cbd_r)
    mask_sha3(out_1, out_2, SHAKE256_RATE, buf_1, buf_2, 0x21, SHAKE256_MASK, SHAKE256_RATE);

    // [41] : h_mode=B , len =0x21 (cbd_r)
    mask_sha3(out_1, out_2, SHAKE256_RATE, buf_1, buf_2, 0x21, SHAKE256_MASK, SHAKE256_RATE);

    // [42] : h_mode=B , len =0x21 (cbd_r)
    mask_sha3(out_1, out_2, SHAKE256_RATE, buf_1, buf_2, 0x21, SHAKE256_MASK, SHAKE256_RATE);

    // [43] : h_mode=2 , len =0X22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [44] : h_mode=2 , len =0X22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [45] : h_mode=2 , len =0X22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [46] : h_mode=B , len =0x21 (cbd_e1)
    mask_sha3(out_1, out_2, SHAKE256_RATE, buf_1, buf_2, 0x21, SHAKE256_MASK, SHAKE256_RATE);

    // [47] : h_mode=2 , len =0X22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [48] : h_mode=2 , len =0X22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [49] : h_mode=2 , len =0X22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [50] : h_mode=B , len =0x21 (cbd_e1)
    mask_sha3(out_1, out_2, SHAKE256_RATE, buf_1, buf_2, 0x21, SHAKE256_MASK, SHAKE256_RATE);

    // [51] : h_mode=2 , len =0X22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [52] : h_mode=2 , len =0X22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [53] : h_mode=2 , len =0X22 (xof_absorb)
    unmk_sha3(out_1, 3*SHAKE128_RATE, buf_1, 0x22, SHAKE128, SHAKE128_RATE);

    // [54] : h_mode=B , len =0x21 (cbd_e1)
    mask_sha3(out_1, out_2, SHAKE256_RATE, buf_1, buf_2, 0x21, SHAKE256_MASK, SHAKE256_RATE);

    // [55] : h_mode=B , len =0x21 (cbd_e2)
    mask_sha3(out_1, out_2, SHAKE256_RATE, buf_1, buf_2, 0x21, SHAKE256_MASK, SHAKE256_RATE);

    // [56] : h_mode=0 , len =0x440 (h_c)
    unmk_sha3(out_1, 32, buf_1, 0x440, SHA3_256, SHA3_256_RATE);

    // [57] : h_mode=B , len =0x40 (kdf)
    mask_sha3(out_1, out_2, 32, buf_1, buf_2, 0x40, SHAKE256_MASK, SHAKE256_RATE);

	t1 = hal_get_time();
	t1 = t1 - t0;
	h1 = t1&0xffffffff;
	xil_printf("over : %lu\n\r", h1);

    dma_cleanup();
    return 0;
}
