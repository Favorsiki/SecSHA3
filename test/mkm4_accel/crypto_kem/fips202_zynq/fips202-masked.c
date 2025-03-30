// This file implementation is taken from https://eprint.iacr.org/2020/733
#include "fips202-masked.h"
#include "fips202.h"
#include "pqm4-hal.h"
#include <string.h>
#define NROUNDS 24


#ifdef SABER_MASKING_ASM
extern void sha3_chi_masked_nonlinear(uint64_t st1[25], uint64_t st2[25], uint64_t bc1[5], uint64_t bc2[5]);
#endif

#define PROFILE_HASHING
extern unsigned long long hash_cycles;
/*
#define ROL(a, offset) ((a << offset) ^ (a >> (64-offset)))
#define MIN(a, b) ((a) < (b) ? (a) : (b))

static void __attribute__ ((noinline)) memxor(void *dest, const void *src, size_t len)
{
  char *d = dest;
  const char *s = src;
  while(len--)
    *d++ ^= *s++;
}

const int keccakf_piln[24] = {
    10, 7,  11, 17, 18, 3, 5,  16, 8,  21, 24, 4,
    15, 23, 19, 13, 12, 2, 20, 14, 22, 9,  6,  1
};

const int keccakf_rotc[24] = {
    1,  3,  6,  10, 15, 21, 28, 36, 45, 55, 2,  14,
    27, 41, 56, 8,  25, 43, 62, 18, 39, 61, 20, 44
};

static void __attribute__ ((noinline)) sha3_theta_rho_pi(uint64_t st[25])
{
    int i, j;
    uint64_t t;
    uint64_t bc[5];

    for (i = 0; i < 5; i++)
        bc[i] = st[i] ^ st[i + 5] ^ st[i + 10] ^ st[i + 15] ^ st[i + 20];

    for (i = 0; i < 5; i++) {
            t = bc[(i + 4) % 5] ^ ROL(bc[(i + 1) % 5], 1);
            for (j = 0; j < 25; j += 5)
                st[j + i] ^= t;
    }

    t = st[1];
    for (i = 0; i < 24; i++) {
        j = keccakf_piln[i];
        bc[0] = st[j];
        st[j] = ROL(t, keccakf_rotc[i]);
        t = bc[0];
    }

}

static void __attribute__ ((noinline)) sha3_chi_masked(uint64_t st1[25], uint64_t st2[25], uint64_t bc1[5], uint64_t bc2[5])
{

    int j;

    for (j = 0; j < 25; j += 5) {

        memcpy(bc1, st1+j, 5*8);
        memcpy(bc2, st2+j, 5*8);

        #ifdef SABER_MASKING_ASM
          sha3_chi_masked_nonlinear(st1+j, st2+j, bc1, bc2);
        #else
          for (int i = 0; i < 5; i++)
          {
              st1[j + i] ^=  ((~bc1[(i + 1) % 5]) & bc1[(i + 2) % 5]);
              st1[j + i] ^=   ((bc1[(i + 1) % 5]) & bc2[(i + 2) % 5]);
              st2[j + i] ^=  ((~bc2[(i + 1) % 5]) & bc2[(i + 2) % 5]);
              st2[j + i] ^=   ((bc2[(i + 1) % 5]) & bc1[(i + 2) % 5]);
          }
        #endif

  }

}

static void __attribute__ ((noinline)) KeccakF1600_StatePermute_masked(uint64_t st1[25], uint64_t st2[25])
{

    // variables
    int r;
    uint64_t bc1[5], bc2[5];

    // constants
    const uint64_t keccakf_rndc[24] = {
        0x0000000000000001, 0x0000000000008082, 0x800000000000808a,
        0x8000000080008000, 0x000000000000808b, 0x0000000080000001,
        0x8000000080008081, 0x8000000000008009, 0x000000000000008a,
        0x0000000000000088, 0x0000000080008009, 0x000000008000000a,
        0x000000008000808b, 0x800000000000008b, 0x8000000000008089,
        0x8000000000008003, 0x8000000000008002, 0x8000000000000080,
        0x000000000000800a, 0x800000008000000a, 0x8000000080008081,
        0x8000000000008080, 0x0000000080000001, 0x8000000080008008
    };

    // actual iteration
    for (r = 0; r < NROUNDS; r++) {

        // Theta Rho Pi
        // Either ClearStack() or explicitely pass bc1, bc2 for memory-reuse leakage
        sha3_theta_rho_pi(st1);
        // ClearStack();
        sha3_theta_rho_pi(st2);

        //  Chi
        sha3_chi_masked(st1, st2, bc1, bc2);

        //  Iota
        st1[0] ^= keccakf_rndc[r];
    }

}

static void __attribute__ ((noinline)) keccak_absorb_masked(uint64_t *s1,
                          uint64_t *s2,
                          unsigned int r,
                          const unsigned char *m1,
                          const unsigned char *m2,
                          unsigned long long int mlen,
                          unsigned char p)
{

  while (mlen >= r)
  {

    memxor(s1, m1, r);
    memxor(s2, m2, r);
    KeccakF1600_StatePermute_masked(s1,s2);
    mlen -= r;
    m1 += r;
    m2 += r;

  }

  memxor(s1, m1, mlen);
  // padding
  ((char *) s1)[mlen] ^= p;
  ((char *) s1)[r-1] ^= 128;

  memxor(s2, m2, mlen);

}

static void __attribute__ ((noinline)) keccak_squeezeblocks_masked(unsigned char *h1, unsigned char *h2,
                                unsigned long long int nblocks,
                                uint64_t *s1, uint64_t *s2,
                                unsigned int r)
{

  while(nblocks > 0)
  {
    KeccakF1600_StatePermute_masked(s1,s2);
    // KeccakF1600_StateExtractBytes_sw(s1, h1, 0, r); //asm is different from sw in keccakf1600.c
    // KeccakF1600_StateExtractBytes_sw(s2, h2, 0, r); //asm is different from sw in keccakf1600.c

    memcpy(h1, s1, r);
    memcpy(h2, s2, r);

    h1 += r;
    h2 += r;
    nblocks--;

  }
}
*/
void sha3_512_masked(unsigned char *output1, unsigned char *output2,
                     const unsigned char *input1, const unsigned char *input2,
                     unsigned long long inlen)

{
#ifdef PROFILE_HASHING
    uint64_t time0 = hal_get_time();
#endif

    mask_sha3(output1, output2, 64, input1, input2, inlen, SHA3_512_MASK, SHA3_512_RATE);

#ifdef PROFILE_HASHING
    uint64_t time1 = hal_get_time();
    hash_cycles += (time1-time0);
#endif
}

void shake256_nonce_masked(unsigned char *output1, unsigned char *output2, unsigned long long outlen,
                     const unsigned char *input1, const unsigned char *input2, unsigned char nonce)
{
#ifdef PROFILE_HASHING
    uint64_t time0 = hal_get_time();
#endif
  uint8_t in1[32+1], in2[32+1];
  memcpy(in1, input1, 32);
  memcpy(in2, input2, 32);
  in1[32] = nonce;
  in2[32] = 0;
  mask_sha3(output1, output2, outlen, input1, input2, 33, SHAKE256_MASK, SHAKE256_RATE);

#ifdef PROFILE_HASHING
    uint64_t time1 = hal_get_time();
    hash_cycles += (time1-time0);
#endif
}

void shake256_masked(unsigned char *output1, unsigned char *output2, unsigned long long outlen,
                     const unsigned char *input1, const unsigned char *input2)
{
#ifdef PROFILE_HASHING
    uint64_t time0 = hal_get_time();
#endif
    mask_sha3(output1, output2, outlen, input1, input2, 64, SHAKE256_MASK, SHAKE256_RATE);
#ifdef PROFILE_HASHING
    uint64_t time1 = hal_get_time();
    hash_cycles += (time1-time0);
#endif
}
