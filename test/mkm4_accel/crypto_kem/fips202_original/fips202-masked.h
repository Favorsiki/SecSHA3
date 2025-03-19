#include "masked.h"

#ifndef FIPS202_MASKED_H
#define FIPS202_MASKED_H

void sha3_512_masked(unsigned char *out1, unsigned char *out2, const unsigned char *in1, const unsigned char *in2, unsigned long long inlen);

void shake256_nonce_masked(unsigned char *output1, unsigned char *output2, unsigned long long outlen, const unsigned char *input1, const unsigned char *input2, unsigned char nonce);

void shake256_masked(unsigned char *output1, unsigned char *output2, unsigned long long outlen, const unsigned char *input1, const unsigned char *input2);

#endif
