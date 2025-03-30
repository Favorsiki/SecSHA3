#ifndef MASKED_CBD_H
#define MASKED_CBD_H

#include "masked-poly.h"

#if KYBER_ETA == 2
#define LAMBDA 3 // ceil(log2(eta+1))+1
#else
#error "unsupported eta"
#endif

#define SAMPLING_BUFFER_SIZE LAMBDA * 2 * (((MASKING_N-1) * (MASKING_N-1)) + (MASKING_N-1)) / 2

#define SAMPLING_NO_ADD_SUB_MOD // when defined, sampling avoids add_mod and sub_mod functions

// type for masked, bitsliced, uniform random eta/lambda-bit samples
typedef struct {
  masked_u32 bs[KYBER_ETA];
} masked_eta_bs32;

typedef struct {
  masked_u32 bs[LAMBDA];
} masked_lambda_bs32;

void masked_cbd(masked_poly *r, const masked_u8_sampling *buf, int add);

#endif
