#ifndef MASKED_POLYVEC_H
#define MASKED_POLYVEC_H

#include "masked.h"


void masked_polyvec_ntt(masked_polyvec *r);
void masked_polyvec_compress(masked_polyvec *r, const masked_polyvec *a);

#endif