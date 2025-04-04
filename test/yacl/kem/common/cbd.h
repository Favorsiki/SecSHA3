#ifndef PQCLEAN_MLKEM512_CLEAN_CBD_H
#define PQCLEAN_MLKEM512_CLEAN_CBD_H
#ifdef __cplusplus
extern "C" {
#endif
#include "params.h"
#include "poly.h"
#include <stdint.h>
void PQCLEAN_MLKEM512_CLEAN_poly_cbd_eta1(poly *r, const uint8_t buf[KYBER_ETA1 * KYBER_N / 4]);

void PQCLEAN_MLKEM512_CLEAN_poly_cbd_eta2(poly *r, const uint8_t buf[KYBER_ETA2 * KYBER_N / 4]);
#ifdef __cplusplus
}
#endif
#endif
