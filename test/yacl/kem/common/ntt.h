#ifndef PQCLEAN_MLKEM512_CLEAN_NTT_H
#define PQCLEAN_MLKEM512_CLEAN_NTT_H
#ifdef __cplusplus
extern "C" {
#endif

#include "params.h"
#include <stdint.h>
extern const int16_t PQCLEAN_MLKEM512_CLEAN_zetas[128];

void PQCLEAN_MLKEM512_CLEAN_ntt(int16_t r[256]);

void PQCLEAN_MLKEM512_CLEAN_invntt(int16_t r[256]);

void PQCLEAN_MLKEM512_CLEAN_basemul(int16_t r[2], const int16_t a[2], const int16_t b[2], int16_t zeta);
#ifdef __cplusplus
}
#endif
#endif
