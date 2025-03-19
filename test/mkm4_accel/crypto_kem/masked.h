#ifndef MASKED_H
#define MASKED_H

#include "poly.h"
#include "polyvec.h"
#include <stdint.h>
#include <stddef.h>

#ifndef MASKING_N
#define MASKING_N 2
#endif /* MASKING_N */

typedef struct {
  uint8_t share[MASKING_N];
} masked_u8;

// masked byte arrays
typedef struct {
  uint8_t u8[KYBER_SYMBYTES];
} u8_symbytes;

typedef struct {
  u8_symbytes share[MASKING_N];
} masked_u8_symbytes;


typedef struct {
  uint8_t u8[KYBER_INDCPA_MSGBYTES];
} u8_msgbytes;

typedef struct {
  u8_msgbytes share[MASKING_N];
} masked_u8_msgbytes;


typedef struct {
  uint8_t u8[KYBER_CIPHERTEXTBYTES];
} u8_ctbytes;

typedef struct {
  u8_ctbytes share[MASKING_N];
} masked_u8_ctbytes;


typedef struct {
  uint8_t u8[KYBER_N * KYBER_ETA * 2 / 8]; // for one cbd sample we need: 2 uniform samples, each 2 bits; 8 bits per byte
} u8_sampling;

typedef struct {
  u8_sampling share[MASKING_N];
} masked_u8_sampling;


typedef struct {
  uint8_t u8[32];
} u8_32;

typedef struct {
  u8_32 share[MASKING_N];
} masked_u8_32;


typedef struct {
  uint8_t u8[64];
} u8_64;

typedef struct {
  u8_64 share[MASKING_N];
} masked_u8_64;


typedef struct {
    uint32_t u32[MASKING_N];
} masked_u32;


typedef struct {
    poly polys[MASKING_N];
} masked_poly;

typedef struct {
    int16_t i16[MASKING_N];
} masked_coeff_q;

typedef struct {
    int16_t i16[MASKING_N];
} masked_coeff_pow2;

#define COEF_BS_LEN 13 // signed
typedef struct {
  masked_u32 bs[COEF_BS_LEN];
} masked_coef_bs32;

typedef struct {
    masked_poly vec[KYBER_K];
} masked_polyvec;

typedef struct {
    masked_polyvec indcpa_sk;
    uint8_t pk[KYBER_INDCPA_PUBLICKEYBYTES];
    uint8_t hpk[KYBER_PUBLICKEYBYTES];
    masked_u8_symbytes z;
} masked_sk;

typedef struct {
    uint8_t u8[KYBER_SSBYTES];
} u8_ss;

typedef struct {
    u8_ss share[MASKING_N];
} masked_ss;

// Fill masked buffer with random values
void masked_randombytes(void *buf, size_t length);
void masked_randombytes_offset(void *buf, size_t offset, size_t length, size_t share_length);

// Mask a buffer of bytes.
void masked_u8_mask(void *dest, const uint8_t *src, size_t length);
void masked_u8_mask_offset(void *dest, const uint8_t *src, size_t offset, size_t length, size_t share_length);

// Unmask a buffer of bytes.
void masked_u8_unmask(uint8_t *dest, const void *src, size_t length);

// Mask a polynomial modulo q.
void masked_poly_mask(masked_poly *dest, const poly *src);

// Unmask a polynomial modulo q.
void masked_poly_unmask(poly *dest, const masked_poly *src);

// Mask a polynomial modulo q.
void masked_polyvec_mask(masked_polyvec *dest, const polyvec *src);

// Unmask a polynomial modulo q.
void masked_polyvec_unmask(polyvec *dest, const masked_polyvec *src);

// Unmask a shared secret ss.
void masked_ss_unmask(uint8_t *dest, const masked_ss *src);


uint8_t masked_ct_compare(const uint8_t *c, const masked_polyvec *u, const masked_poly *v);


void masked_hash_g(masked_u8_64 *out, const masked_u8_64 *in);

void masked_prf(masked_u8_sampling *out, const masked_u8_symbytes *in, uint8_t nonce);

void masked_cmov(masked_u8_64 *out, masked_u8_symbytes *in, uint8_t b);

void masked_kdf(masked_ss *ss, masked_u8_64 *in);


#endif /* MASKED_H */
