#ifndef SECHASH_H
#define SECHASH_H

#include <stdint.h>
#include "xparameters.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "xtime_l.h"

#define SHA3_256 0
#define SHA3_512 1
#define SHAKE128 2
#define SHAKE256 3
#define SHA3_224 4
#define SHA3_384 5

#define SHA3_256_MASK 8
#define SHA3_512_MASK 9
#define SHAKE128_MASK 10
#define SHAKE256_MASK 11
#define SHA3_224_MASK 12
#define SHA3_384_MASK 13

#define SHAKE128_RATE 168
#define SHAKE256_RATE 136
#define SHA3_256_RATE 136
#define SHA3_384_RATE 104
#define SHA3_512_RATE 72

#define MAX_ABSORB_LEN 512

#define CMD_BASEADDR XPAR_HASH_AXIS_0_S00_AXI_BASEADDR
//#define DMA_BASEADDR XPAR_AXI_DMA_0_BASEADDR
#define SLV_REG0 0
#define SLV_REG1 4
#define TIMEOUT 10000
/*
SHA3-256
SHA3-512
SHAKE-128
SHAKE-256

sha3_512_masked  *
shake256_nonce_masked *
shake256_masked  *

shake128_inc

*/
void unmk_sha3(uint8_t *output, size_t outlen, const uint8_t *input, size_t inlen, int h_mode, int rate);
void unmk_sha3_inc_init(int h_mode);
void unmk_sha3_inc_absorb(const uint8_t* input, size_t inlen, int h_mode);
void unmk_sha3_inc_padding(int h_mode);
void unmk_sha3_inc_squeeze(uint8_t* output, int outlen, int h_mode, int rate);
void unmk_sha3_512(uint8_t *output, const uint8_t *input, size_t inlen);
void unmk_sha3_256(uint8_t *output, const uint8_t *input, size_t inlen);
void unmk_shake256(uint8_t *output, int outlen, const uint8_t *input, size_t inlen);
void unmk_shake128(uint8_t *output, int outlen, const uint8_t *input, size_t inlen);


void mask_sha3(uint8_t *output1, uint8_t *output2, size_t outlen, const uint8_t *input1, const uint8_t *input2, size_t inlen, int h_mode, int rate);
void mask_sha3_inc_init(int h_mode);
void mask_sha3_inc_absorb(const uint8_t* input1, const uint8_t* input2, size_t inlen, int h_mode);
void mask_sha3_inc_padding(int h_mode);
void mask_sha3_inc_squeeze(uint8_t* output1, uint8_t* output2, int outlen, int h_mode, int rate);
void mask_sha3_512(uint8_t *output1, uint8_t *output2, const uint8_t *input1, const uint8_t *input2, size_t inlen);
void mask_sha3_256(uint8_t *output1, uint8_t *output2, const uint8_t *input1, const uint8_t *input2, size_t inlen);
void mask_shake256(uint8_t *output1, uint8_t *output2, size_t outlen, const uint8_t *input1, const uint8_t *input2, size_t inlen);



#endif
