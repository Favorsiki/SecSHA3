#ifndef A2B_H
#define A2B_H

#include <stdint.h>
#include <stdio.h>

// Pick one

// #define k 4
// #define k 8

// #define nk 32
// #define nk 64

// Don't touch
#include "def.h"

#define pow2(x) ((uint64_t)1 << (x))
#define mod2(x) ((uint32_t)(pow2(x) - 1))
#define index(i, beta, A) ((i << (1 + k)) | (beta << k) | A)

uint32_t A2B_convert(uint32_t A, uint32_t R);
void A2B_reset(void);

static inline uint32_t gen_GAMMA(uint32_t gamma)
{
    size_t i;
    uint32_t GAMMA = 0;

    for (i = 1; i < a2bn; i++) {
        GAMMA = (GAMMA + (gamma << (i * k)));
    }
    return GAMMA;
}

static inline uint32_t gen_rrr(uint8_t r)
{
    size_t i;
    uint32_t rrr = 0;

    for (i = 0; i < a2bn; i++)
    {
        rrr |= ((uint32_t)r << (i * k));
    }
    return rrr;
}



#endif
