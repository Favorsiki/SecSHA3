#ifndef CBD_H
#define CBD_H
#include "params.h"
#include "poly.h"
#include <stdint.h>

void poly_cbd_eta1(poly *r, const uint8_t buf[KYBER_ETA1 * KYBER_N / 4]);

void poly_cbd_eta2(poly *r, const uint8_t buf[KYBER_ETA2 * KYBER_N / 4]);

#endif
