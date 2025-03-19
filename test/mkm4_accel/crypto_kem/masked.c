#include "masked.h"
#include "randombytes.h"
#include "symmetric.h"
#include "string.h"
#include "fips202.h"
#include "fips202-masked.h"
#include "verify.h"
#include "masked-polyvec.h"
#include "masked-poly.h"



// Fill masked buffer with random values
void masked_randombytes(void *buf, size_t length)
{
    memset((uint8_t*)buf + length, 0, sizeof(uint8_t) * length * (MASKING_N-1));
    randombytes((uint8_t*)buf, length);
}

void masked_randombytes_offset(void *buf, size_t offset, size_t length, size_t share_length)
{
    size_t n;
    for (n = 1; n < MASKING_N; n++)
    {
        memset((uint8_t*)buf + n*share_length + offset, 0, sizeof(uint8_t) * length);
    }
    randombytes((uint8_t*)buf + offset, length);
}


void masked_u8_mask(void *dest, const uint8_t *src, size_t length)
{
    memset((uint8_t*)dest + length, 0, length * (MASKING_N-1) * sizeof(uint8_t));
    memcpy((uint8_t*)dest, src, length);
}

void masked_u8_mask_offset(void *dest, const uint8_t *src, size_t offset, size_t length, size_t share_length)
{
    size_t n;
    for (n = 1; n < MASKING_N; n++)
    {
        memset((uint8_t*)dest + n*share_length + offset, 0, length * sizeof(uint8_t));
    }
    memcpy((uint8_t*)dest + offset, src, length);
}

void masked_u8_unmask(uint8_t *dest, const void *src, size_t length)
{
    size_t i,n;
    const uint8_t *s = (uint8_t*)src + length;
    memcpy(dest, (uint8_t*)src, length);
    for (n = 1; n < MASKING_N; n++)
    {
        for (i = 0; i < length; i++)
        {
            dest[i] ^= *s++;
        }
    }
}

// Mask a polynomial modulo q.
void masked_poly_mask(masked_poly *dest, const poly *src)
{
    uint16_t random_buf[KYBER_N * (MASKING_N - 1)];
    size_t random_buf_idx = 0;
    randombytes((uint8_t *)random_buf, sizeof(uint16_t)*KYBER_N * (MASKING_N - 1));
    for (size_t idx = 0; idx < KYBER_N; idx++) {
        int16_t acc = 0;
        for (size_t mask_idx = 0; mask_idx < MASKING_N - 1; mask_idx++) {
			int16_t tmp;
			do {
				tmp = (random_buf[random_buf_idx++] & 0x0FFF) - 0x0800;
			} while (tmp > KYBER_Q / 2 || tmp < -KYBER_Q / 2);
            dest->polys[mask_idx].coeffs[idx] = tmp;
            acc += tmp;
        }
        dest->polys[MASKING_N - 1].coeffs[idx] = -acc + src->coeffs[idx];
    }
}

// Unmask a polynomial modulo q.
void masked_poly_unmask(poly *dest, const masked_poly *src)
{
    for (size_t idx = 0; idx < KYBER_N; idx++) {
        dest->coeffs[idx] = 0;
        for (size_t mask_idx = 0; mask_idx < MASKING_N; mask_idx++) {
            dest->coeffs[idx] = dest->coeffs[idx] % KYBER_Q + src->polys[mask_idx].coeffs[idx] % KYBER_Q;
        }
    }
    poly_reduce(dest);
}

// Mask a polynomial vector modulo q.
void masked_polyvec_mask(masked_polyvec *dest, const polyvec *src)
{
    for (size_t idx = 0; idx < KYBER_K; idx++) {
        masked_poly_mask(&dest->vec[idx], &src->vec[idx]);
    }
}

// Unmask a polynomial vector modulo q.
void masked_polyvec_unmask(polyvec *dest, const masked_polyvec *src)
{
    for (size_t idx = 0; idx < KYBER_K; idx++) {
        masked_poly_unmask(&dest->vec[idx], &src->vec[idx]);
    }
}

// Unmask a shared secret ss.
void masked_ss_unmask(uint8_t *dest, const masked_ss *src) {
    masked_u8_unmask(dest, src->share[0].u8, KYBER_SSBYTES);
}

// Masked comparison from [OSPG18] https://tches.iacr.org/index.php/TCHES/article/view/836
uint8_t masked_ct_compare(const uint8_t *c, const masked_polyvec *u, const masked_poly *v) {
    #if MASKING_N != 2
        #error "Masked comparison only works for MASKING_N=2"
    #endif

    size_t i;
    shake128incctx state1;
    shake128incctx state2;

    // (u, v) from ciphertext c
    polyvec cu;
    poly cv;

    // compressed re-encryption u and v
    masked_polyvec uc;
    masked_poly vc;

    // hashes
    uint8_t d1[32];
    uint8_t d2[32];

    // compress u and v
    masked_polyvec_compress(&uc, u);
    masked_poly_compress(&vc, v);

    // decompress ciphertext
    polyvec_decompress(&cu, c);
    poly_decompress(&cv, c+KYBER_POLYVECCOMPRESSEDBYTES);

    // subtract first share of re-encryption from ciphertext
    // cu = cu - uc[0], cv = cv - vc[0]
    for(i=0;i<KYBER_K;i++){
        poly_sub(&cu.vec[i], &cu.vec[i], &uc.vec[i].polys[0]);
    }
    poly_sub(&cv, &cv, &vc.polys[0]);

    // it should hold that (uc[1], vc[1]) == (cu, cv) now; we verify that by comparing hashes
    // compute d1 = H(uc[1]||vc[1])
    shake128_inc_init(&state1);
    for(i=0;i<KYBER_K;i++){
        shake128_inc_absorb(&state1, (uint8_t *) &uc.vec[i].polys[1], sizeof(poly));
    }
    shake128_inc_absorb(&state1, (uint8_t *) &vc.polys[1], sizeof(poly));
    shake128_inc_finalize(&state1);
    shake128_inc_squeeze(d1, sizeof(d1), &state1);

    // compute d2 = H(cu, cv)
    shake128_inc_init(&state2);
    for(i=0;i<KYBER_K;i++){
        shake128_inc_absorb(&state2, (uint8_t *) &cu.vec[i], sizeof(poly));
    }
    shake128_inc_absorb(&state2, (uint8_t *) &cv, sizeof(poly));
    shake128_inc_finalize(&state2);
    shake128_inc_squeeze(d2, sizeof(d2), &state2);

    // verify d1 = d2
    return verify(d1, d2, sizeof(d1));
}

void masked_hash_g(masked_u8_64 *out, const masked_u8_64 *in) {
    #if MASKING_N != 2
        #error "Keccak only available for MASKING_N=2"
    #endif

    sha3_512_masked(out->share[0].u8, out->share[1].u8, in->share[0].u8, in->share[1].u8, 64);
}


void masked_prf(masked_u8_sampling *out, const masked_u8_symbytes *in, uint8_t nonce) {
    #if MASKING_N != 2
        #error "Keccak only available for MASKING_N=2"
    #endif

    shake256_nonce_masked(out->share[0].u8, out->share[1].u8, KYBER_N * KYBER_ETA * 2 / 8, in->share[0].u8, in->share[1].u8, nonce);
}

void masked_cmov(masked_u8_64 *out, masked_u8_symbytes *in, uint8_t b) {
    size_t i,j;
    b = -b;
    for(j = 0; j < MASKING_N; j++) {
        for (i = 0; i < KYBER_SYMBYTES; i++) {
            out->share[j].u8[i] ^= b & (in->share[j].u8[i] ^ out->share[j].u8[i]);
        }
    }
}

void masked_kdf(masked_ss *ss, masked_u8_64 *in) {
    #if MASKING_N != 2
        #error "Keccak only available for MASKING_N=2"
    #endif
  
    shake256_masked(ss->share[0].u8, ss->share[1].u8, 32, in->share[0].u8, in->share[1].u8);
}
