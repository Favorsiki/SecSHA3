#include "masked-cbd.h"
#include "params.h"
#include "randombytes.h"
#include <stdint.h>

extern int16_t asm_barrett_reduce32(int32_t a);
extern void secbit_add_sub_constadd(masked_lambda_bs32 *z, const masked_eta_bs32 *x, const masked_eta_bs32 *y, const uint32_t *randptr);
extern void secadd_coef(masked_coef_bs32 *z, const masked_coef_bs32 *x, const masked_coef_bs32 *y, const uint32_t *randptr);
extern void secadd_lambda(masked_coef_bs32 *z, const masked_lambda_bs32 *x, const masked_coef_bs32 *y, const uint32_t *randptr);
extern void secaddq_lambda(masked_coef_bs32 *z, const masked_lambda_bs32 *x, const masked_coef_bs32 *y, const uint32_t *randptr);
extern void pack_bitslices(uint32_t *z1, uint32_t *z2, const uint8_t *x);

static int16_t randomintq(void)
{
#if KYBER_Q != 3329
#error "unsupported q"
#endif
  uint32_t r,tmp;
  int i = 0;
  
  do {
    if (i == 0)
      tmp = randomint();
    r = tmp & 0xfff;
    tmp >>= 12;
    if (++i == 32/12)
      i = 0;
  } while (r >= KYBER_Q);
  return r;
}

/*************************************************
* Name:        pack_bitslices
*
* Description: pack masked bitslices from masked byte array
*
* Arguments:    - masked_eta_bs32 *z1: pointer to masked bitslice output
*               - masked_eta_bs32 *z2: pointer to masked bitslice output
*               - const masked_u8_sampling *x: pointer to masked input byte array of size KYBER_N * KYBER_ETA / 4
*               - size_t offset: offset in x
**************************************************/
// #if KYBER_ETA == 2
// void pack_bitslices(masked_eta_bs32 *z1, masked_eta_bs32 *z2, const masked_u8_sampling *x, size_t n, size_t offset)
// {
//   size_t i;
//   for (i = 0; i < 32; i += 2, offset += 1)
//   {
//     z1->bs[0].u32[n] >>= 2;
//     z1->bs[1].u32[n] >>= 2;
//     z2->bs[0].u32[n] >>= 2;
//     z2->bs[1].u32[n] >>= 2;
//     z1->bs[0].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 30) & 0x40000000;
//     z1->bs[1].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 29) & 0x40000000;
//     z2->bs[0].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 28) & 0x40000000;
//     z2->bs[1].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 27) & 0x40000000;
//     z1->bs[0].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 27) & 0x80000000;
//     z1->bs[1].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 26) & 0x80000000;
//     z2->bs[0].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 25) & 0x80000000;
//     z2->bs[1].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 24) & 0x80000000;
//   }
// }
// #else
// #error "unsupported eta"
// #endif

/*************************************************
* Name:        masked_cbd
*
* Description: Given an array of uniformly random bytes, compute
*              polynomial with coefficients distributed according to
*              a centered binomial distribution with parameter KYBER_ETA
*              specialized for KYBER_ETA=2
*
* Arguments:   - masked_poly *r: pointer to masked output polynomial
*              - const masked_u8_sampling *buf: pointer to masked input byte array
*              - int add:        boolean to indicate to accumulate into r
**************************************************/
void masked_cbd(masked_poly *r, const masked_u8_sampling *buf, int add) 
{
  size_t i = 0, j, k, n;
  int16_t A0[32], tmp;
  uint32_t randbuf[100]; // randomness needed for sampling and conversion
  
  for (i = 0; i < KYBER_N/32; i++)
  {
    masked_eta_bs32 x = {0}, y = {0};
    masked_lambda_bs32 z = {0};
    masked_coef_bs32 B1 = {0}, B2 = {0};
    
    for (n = 0; n < COEF_BS_LEN; n++)
    {
#if MASKING_N != 2
#error
#endif
      uint32_t ri = randomint();
      B1.bs[n].u32[0] = ri;
      B1.bs[n].u32[1] = ri;
    }
    for (j = 0; j < 32; j++)
    {
      A0[j] = randomintq();
      tmp = (1<<COEF_BS_LEN) - A0[j];
      for (n = 0; n < COEF_BS_LEN; n++)
      {
        B1.bs[n].u32[0] ^= ((tmp >> n) & 1) << j;
      }
    }
    for (j = 0; j < 100; j++)
    {
      randbuf[j] = randomint();
    }
    
    pack_bitslices(&x.bs[0].u32[0], &y.bs[0].u32[0], &buf->share[0].u8[i*16]); // first shares
    pack_bitslices(&x.bs[0].u32[1], &y.bs[0].u32[1], &buf->share[1].u8[i*16]); // second shares
    
    secbit_add_sub_constadd(&z, &x, &y, randbuf); // z = HW(x) - HW(y) + KYBER_ETA
    secaddq_lambda(&B2, &z, &B1, randbuf+14); // B2Aq
    
    for (k = 0; k < COEF_BS_LEN-1; k++)
    {
      B2.bs[k].u32[0] ^= B2.bs[k].u32[1];
    }
    
    // first shares
    for (j = 0; j < 32; j++)
    {
      if (add == 0)
      {
        r->polys[0].coeffs[i*32+j] = 0;
      }
      r->polys[0].coeffs[i*32+j] += A0[j];
      r->polys[0].coeffs[i*32+j] -= KYBER_ETA;
    }
    
    // second shares
    for (j = 0; j < 32; j++)
    {
      if (add == 0)
      {
        r->polys[1].coeffs[i*32+j] = 0;
      }
      tmp = 0;
      for (k = 0; k < COEF_BS_LEN-1; k++)
      {
        tmp <<= 1;
        tmp |= B2.bs[COEF_BS_LEN-2-k].u32[0] & 1;
        B2.bs[COEF_BS_LEN-2-k].u32[0] >>= 1;
      }
      r->polys[1].coeffs[i*32+j] += tmp;
    }
  }
}
