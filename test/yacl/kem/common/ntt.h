#ifndef NTT_H
#define NTT_H
#include "params.h"
#include <stdint.h>

extern const int16_t zetas[128];

void ntt(int16_t r[256]);

void invntt(int16_t r[256]);

void basemul(int16_t r[2], const int16_t a[2], const int16_t b[2], int16_t zeta);

#endif
