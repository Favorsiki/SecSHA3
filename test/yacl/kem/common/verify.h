#ifndef PQCLEAN_MLKEM512_CLEAN_VERIFY_H
#define PQCLEAN_MLKEM512_CLEAN_VERIFY_H
#ifdef __cplusplus
extern "C" {
#endif

#include "params.h"
#include <stddef.h>
#include <stdint.h>
int PQCLEAN_MLKEM512_CLEAN_verify(const uint8_t *a, const uint8_t *b, size_t len);

void PQCLEAN_MLKEM512_CLEAN_cmov(uint8_t *r, const uint8_t *x, size_t len, uint8_t b);

void PQCLEAN_MLKEM512_CLEAN_cmov_int16(int16_t *r, int16_t v, uint16_t b);
#ifdef __cplusplus
}
#endif
#endif
