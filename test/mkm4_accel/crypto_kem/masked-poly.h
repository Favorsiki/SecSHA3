#ifndef MASKED_POLY_H
#define MASKED_POLY_H

#include "masked.h"

#define masked_poly_getnoise(p, seed, nonce) masked_poly_noise(p, seed, nonce, 0)
#define masked_poly_addnoise(p, seed, nonce) masked_poly_noise(p, seed, nonce, 1)

void masked_poly_tobytes(unsigned char *r, masked_poly *a);

void masked_poly_frommsg(masked_poly *r, const masked_u8_msgbytes *msg);
void masked_A2B_Transform(int16_t* z, int16_t y1, int16_t y2);
void masked_poly_tomsg(masked_u8_msgbytes *msg, masked_poly *a);

void masked_poly_noise(masked_poly *r, const masked_u8_symbytes *seed, unsigned char nonce, int add);

void masked_poly_ntt(masked_poly *r);
void masked_poly_invntt(masked_poly *r);
void masked_poly_basemul(masked_poly *r, const poly *a, const masked_poly *b);
void masked_poly_basemul_acc(masked_poly *r, const poly *a, const masked_poly *b);

void masked_poly_add2(masked_poly *r, const masked_poly *a);
void masked_poly_sub(masked_poly *r, const poly *a, const masked_poly *b);
void masked_poly_reduce(masked_poly *r);

void masked_poly_compress(masked_poly *r, const masked_poly *a);

#endif
