/* Based on the public domain implementation in
 * crypto_hash/keccakc512/simple/ from http://bench.cr.yp.to/supercop.html
 * by Ronny Van Keer
 * and the public domain "TweetFips202" implementation
 * from https://twitter.com/tweetfips202
 * by Gilles Van Assche, Daniel J. Bernstein, and Peter Schwabe */

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "fips202.h"
#include "keccakf1600.h"

#define PROFILE_HASHING

#ifdef PROFILE_HASHING
#include "pqm4-hal.h"
extern unsigned long long hash_cycles;
#endif

extern unsigned long long hash_cycles;
/*************************************************
 * Name:        keccak_absorb
 *
 * Description: Absorb step of Keccak;
 *              non-incremental, starts by zeroeing the state.
 *
 * Arguments:   - uint64_t *s:       pointer to (uninitialized) output Keccak state
 *              - uint32_t r:        rate in bytes (e.g., 168 for SHAKE128)
 *              - const uint8_t *m:  pointer to input to be absorbed into s
 *              - size_t mlen:       length of input in bytes
 *              - uint8_t p:         domain-separation byte for different Keccak-derived functions
 **************************************************/
static void keccak_absorb(uint64_t *s,
    uint32_t r,
    const uint8_t *m, size_t mlen,
    uint8_t p)
{
  size_t i;
  uint8_t t[200];

  while (mlen >= r)
  {
    KeccakF1600_StateXORBytes(s, m, 0, r);
    KeccakF1600_StatePermute(s);
    mlen -= r;
    m += r;
  }

  for (i = 0; i < r; ++i)
    t[i] = 0;
  for (i = 0; i < mlen; ++i)
    t[i] = m[i];
  t[i] = p;
  t[r - 1] |= 128;

  KeccakF1600_StateXORBytes(s, t, 0, r);
}


/*************************************************
 * Name:        keccak_squeezeblocks
 *
 * Description: Squeeze step of Keccak. Squeezes full blocks of r bytes each.
 *              Modifies the state. Can be called multiple times to keep squeezing,
 *              i.e., is incremental.
 *
 * Arguments:   - uint8_t *h:     pointer to output blocks
 *              - size_t nblocks: number of blocks to be squeezed (written to h)
 *              - uint64_t *s:    pointer to in/output Keccak state
 *              - uint32_t r:     rate in bytes (e.g., 168 for SHAKE128)
 **************************************************/
static void keccak_squeezeblocks(uint8_t *h, size_t nblocks,
    uint64_t *s,
    uint32_t r)
{
  while(nblocks > 0)
  {
    KeccakF1600_StatePermute(s);
    KeccakF1600_StateExtractBytes(s, h, 0, r);
    h += r;
    nblocks--;
  }
}

/*************************************************
 * Name:        keccak_inc_init
 *
 * Description: Initializes the incremental Keccak state to zero.
 *
 * Arguments:   - uint64_t *s_inc: pointer to input/output incremental state
 *                First 25 values represent Keccak state.
 *                26th value represents either the number of absorbed bytes
 *                that have not been permuted, or not-yet-squeezed bytes.
 **************************************************/
static void keccak_inc_init(uint64_t *s_inc) {
    size_t i;

    for (i = 0; i < 25; ++i) {
        s_inc[i] = 0;
    }
    s_inc[25] = 0;
}
/*************************************************
 * Name:        keccak_inc_absorb
 *
 * Description: Incremental keccak absorb
 *              Preceded by keccak_inc_init, succeeded by keccak_inc_finalize
 *
 * Arguments:   - uint64_t *s_inc: pointer to input/output incremental state
 *                First 25 values represent Keccak state.
 *                26th value represents either the number of absorbed bytes
 *                that have not been permuted, or not-yet-squeezed bytes.
 *              - uint32_t r: rate in bytes (e.g., 168 for SHAKE128)
 *              - const uint8_t *m: pointer to input to be absorbed into s_inc
 *              - size_t mlen: length of input in bytes
 **************************************************/
static void keccak_inc_absorb(uint64_t *s_inc, uint32_t r, const uint8_t *m,
                              size_t mlen) {
    /* Recall that s_inc[25] is the non-absorbed bytes xored into the state */
    while (mlen + s_inc[25] >= r) {

        KeccakF1600_StateXORBytes(s_inc, m, s_inc[25], r-s_inc[25]);
        mlen -= (size_t)(r - s_inc[25]);
        m += r - s_inc[25];
        s_inc[25] = 0;

        KeccakF1600_StatePermute(s_inc);
    }

    KeccakF1600_StateXORBytes(s_inc, m, s_inc[25], mlen);
    s_inc[25] += mlen;
}

/*************************************************
 * Name:        keccak_inc_finalize
 *
 * Description: Finalizes Keccak absorb phase, prepares for squeezing
 *
 * Arguments:   - uint64_t *s_inc: pointer to input/output incremental state
 *                First 25 values represent Keccak state.
 *                26th value represents either the number of absorbed bytes
 *                that have not been permuted, or not-yet-squeezed bytes.
 *              - uint32_t r: rate in bytes (e.g., 168 for SHAKE128)
 *              - uint8_t p: domain-separation byte for different
 *                                 Keccak-derived functions
 **************************************************/
static void keccak_inc_finalize(uint64_t *s_inc, uint32_t r, uint8_t p) {
    /* After keccak_inc_absorb, we are guaranteed that s_inc[25] < r,
       so we can always use one more byte for p in the current state. */
    size_t i;
    uint8_t t[200];
    for (i = 0; i < r; ++i)
      t[i] = 0;
    t[s_inc[25]] = p;
    t[r - 1] |= 128;

    KeccakF1600_StateXORBytes(s_inc, t, 0, r);
    s_inc[25] = 0;
}

/*************************************************
 * Name:        keccak_inc_squeeze
 *
 * Description: Incremental Keccak squeeze; can be called on byte-level
 *
 * Arguments:   - uint8_t *h: pointer to output bytes
 *              - size_t outlen: number of bytes to be squeezed
 *              - uint64_t *s_inc: pointer to input/output incremental state
 *                First 25 values represent Keccak state.
 *                26th value represents either the number of absorbed bytes
 *                that have not been permuted, or not-yet-squeezed bytes.
 *              - uint32_t r: rate in bytes (e.g., 168 for SHAKE128)
 **************************************************/
static void keccak_inc_squeeze(uint8_t *h, size_t outlen,
                               uint64_t *s_inc, uint32_t r) {
    size_t len;
    if(outlen < s_inc[25])
    {
        len = outlen;
    }
    else
    {
        len = s_inc[25];
    }

    KeccakF1600_StateExtractBytes(s_inc, h, r-s_inc[25], len);
    h += len;
    outlen -= len;
    s_inc[25] -= len;

    /* Then squeeze the remaining necessary blocks */
    while (outlen > 0) {
        KeccakF1600_StatePermute(s_inc);

        if(outlen < r)
        {
            len = outlen;
        }
        else
        {
            len = r;
        }
        KeccakF1600_StateExtractBytes(s_inc, h, 0, len);
        h += len;
        outlen -= len;
        s_inc[25] = r - len;
    }
}

void shake128_inc_init(shake128incctx *state) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    keccak_inc_init(state->ctx);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void shake128_inc_absorb(shake128incctx *state, const uint8_t *input, size_t inlen) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    keccak_inc_absorb(state->ctx, SHAKE128_RATE, input, inlen);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void shake128_inc_finalize(shake128incctx *state) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    keccak_inc_finalize(state->ctx, SHAKE128_RATE, 0x1F);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void shake128_inc_squeeze(uint8_t *output, size_t outlen, shake128incctx *state) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    keccak_inc_squeeze(output, outlen, state->ctx, SHAKE128_RATE);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void shake128_inc_ctx_clone(shake128incctx* dest, const shake128incctx *src) {
    memcpy(dest, src, sizeof(shake128incctx));
}

void shake128_inc_ctx_release(shake128incctx *state) {
    (void) state;
}

void shake256_inc_init(shake256incctx *state) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    keccak_inc_init(state->ctx);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void shake256_inc_absorb(shake256incctx *state, const uint8_t *input, size_t inlen) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    keccak_inc_absorb(state->ctx, SHAKE256_RATE, input, inlen);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void shake256_inc_finalize(shake256incctx *state) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    keccak_inc_finalize(state->ctx, SHAKE256_RATE, 0x1F);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void shake256_inc_squeeze(uint8_t *output, size_t outlen, shake256incctx *state) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    keccak_inc_squeeze(output, outlen, state->ctx, SHAKE256_RATE);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void shake256_inc_ctx_clone(shake256incctx* dest, const shake256incctx *src) {
    memcpy(dest, src, sizeof(shake256incctx));
}

void shake256_inc_ctx_release(shake256incctx *state) {
    (void) state;
}

/********** cSHAKE128 ***********/

void cshake128_simple_absorb(shake128ctx *state, uint16_t cstm, const uint8_t *in, size_t inlen)
{
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif


  uint8_t sep[8];
  size_t i;

  for (i = 0; i < 25; i++)
    state->ctx[i] = 0;

  /* Absorb customization (domain-separation) string */
  sep[0] = 0x01;
  sep[1] = 0xa8;
  sep[2] = 0x01;
  sep[3] = 0x00;
  sep[4] = 0x01;
  sep[5] = 16; // fixed bitlen of cstm
  sep[6] = cstm & 0xff;
  sep[7] = cstm >> 8;

  KeccakF1600_StateXORBytes(state->ctx, sep, 0, 8);
  KeccakF1600_StatePermute(state->ctx);

  /* Absorb input */
  keccak_absorb(state->ctx, SHAKE128_RATE, in, inlen, 0x04);

#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif

}


void cshake128_simple_squeezeblocks(uint8_t *output, size_t nblocks, shake128ctx *state)
{
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
  keccak_squeezeblocks(output, nblocks, state->ctx, SHAKE128_RATE);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}


void cshake128_simple(uint8_t *output, size_t outlen, uint16_t cstm, const uint8_t *in, size_t inlen)
{
  shake128ctx state;
  uint8_t t[SHAKE128_RATE];
  size_t i;

  cshake128_simple_absorb(&state, cstm, in, inlen);

#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif

  /* Squeeze output */
  keccak_squeezeblocks(output, outlen/SHAKE128_RATE, state.ctx, SHAKE128_RATE);
  output += (outlen/SHAKE128_RATE)*SHAKE128_RATE;

  if (outlen%SHAKE128_RATE)
  {
    keccak_squeezeblocks(t, 1, state.ctx, SHAKE128_RATE);
    for (i = 0; i < outlen%SHAKE128_RATE; i++)
      output[i] = t[i];
  }
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}



/*************************************************
 * Name:        shake128_absorb
 *
 * Description: Absorb step of the SHAKE128 XOF.
 *              non-incremental, starts by zeroeing the state.
 *
 * Arguments:   - uint64_t *state:      pointer to (uninitialized) output Keccak state
 *              - const uint8_t *input: pointer to input to be absorbed into state
 *              - size_t inlen:         length of input in bytes
 **************************************************/
void shake128_absorb(shake128ctx *state, const uint8_t *input, size_t inlen)
{
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
  int i;
  for (i = 0; i < 25; i++)
    state->ctx[i] = 0;

  keccak_absorb(state->ctx, SHAKE128_RATE, input, inlen, 0x1F);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

/*************************************************
 * Name:        shake128_squeezeblocks
 *
 * Description: Squeeze step of SHAKE128 XOF. Squeezes full blocks of SHAKE128_RATE bytes each.
 *              Modifies the state. Can be called multiple times to keep squeezing,
 *              i.e., is incremental.
 *
 * Arguments:   - uint8_t *output:     pointer to output blocks
 *              - size_t nblocks:      number of blocks to be squeezed (written to output)
 *              - shake128ctx *state:  pointer to in/output Keccak state
 **************************************************/
void shake128_squeezeblocks(uint8_t *output, size_t nblocks, shake128ctx *state)
{
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
  keccak_squeezeblocks(output, nblocks, state->ctx, SHAKE128_RATE);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void shake128(uint8_t *output, size_t outlen, const uint8_t *input, size_t inlen)
{
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
  shake128ctx state;
  uint8_t t[SHAKE128_RATE];
  size_t nblocks = outlen/SHAKE128_RATE;
  size_t i;

  for (i = 0; i < 25; ++i) {
    state.ctx[i] = 0;
  }

  /* Absorb input */
  keccak_absorb((uint64_t*)state.ctx, SHAKE128_RATE, input, inlen, 0x1F);

  /* Squeeze output */
  keccak_squeezeblocks(output, nblocks, (uint64_t*)state.ctx, SHAKE128_RATE);

  output += nblocks*SHAKE128_RATE;
  outlen -= nblocks*SHAKE128_RATE;

  if (outlen)
  {
    keccak_squeezeblocks(t, 1, (uint64_t*)state.ctx, SHAKE128_RATE);
    for (i = 0; i < outlen; i++)
      output[i] = t[i];
  }
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void shake128_ctx_release(shake128ctx *state) {
    (void) state;
}
void shake128_ctx_clone(shake128ctx *dest, const shake128ctx *src) {
    memcpy(dest, src, sizeof(shake128ctx));
}

void shake256_absorb(shake256ctx *state, const uint8_t *input, size_t inlen)
{
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
  int i;
  for (i = 0; i < 25; i++)
    state->ctx[i] = 0;

  keccak_absorb(state->ctx, SHAKE256_RATE, input, inlen, 0x1F);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}


void shake256_squeezeblocks(uint8_t *output, size_t nblocks, shake256ctx *state)
{
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
  keccak_squeezeblocks(output, nblocks, state->ctx, SHAKE256_RATE);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

/*************************************************
 * Name:        shake256
 *
 * Description: SHAKE256 XOF with non-incremental API
 *
 * Arguments:   - uint8_t *output:      pointer to output
 *              - size_t outlen:        requested output length in bytes
 *              - const uint8_t *input: pointer to input
 *              - size_t inlen:         length of input in bytes
 **************************************************/
void shake256(uint8_t *output, size_t outlen,
    const uint8_t *input, size_t inlen)
{
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
  shake256ctx state;
  uint8_t t[SHAKE256_RATE];
  size_t nblocks = outlen/SHAKE256_RATE;
  size_t i;

  for (i = 0; i < 25; ++i) {
    state.ctx[i] = 0;
  }

  /* Absorb input */
  keccak_absorb((uint64_t*)state.ctx, SHAKE256_RATE, input, inlen, 0x1F);

  /* Squeeze output */
  keccak_squeezeblocks(output, nblocks, (uint64_t*)state.ctx, SHAKE256_RATE);

  output+=nblocks*SHAKE256_RATE;
  outlen-=nblocks*SHAKE256_RATE;

  if(outlen)
  {
    keccak_squeezeblocks(t, 1, (uint64_t*)state.ctx, SHAKE256_RATE);
    for(i=0;i<outlen;i++)
      output[i] = t[i];
  }
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void shake256_ctx_release(shake256ctx *state) {
    (void) state;
}

void shake256_ctx_clone(shake256ctx *dest, const shake256ctx *src) {
    memcpy(dest, src, sizeof(shake256ctx));
}


/*************************************************
 * Name:        sha3_256
 *
 * Description: SHA3-256 with non-incremental API
 *
 * Arguments:   - uint8_t *output:      pointer to output
 *              - const uint8_t *input: pointer to input
 *              - size_t inlen:         length of input in bytes
 **************************************************/
void sha3_256(uint8_t *output, const uint8_t *input, size_t inlen)
{
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
  uint64_t s[25] = {0};
  uint8_t t[SHA3_256_RATE];
  size_t i;

  /* Absorb input */
  keccak_absorb(s, SHA3_256_RATE, input, inlen, 0x06);

  /* Squeeze output */
  keccak_squeezeblocks(t, 1, s, SHA3_256_RATE);

  for(i=0;i<32;i++)
    output[i] = t[i];
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}
void sha3_256_inc_init(sha3_256incctx *state) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    keccak_inc_init(state->ctx);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void sha3_256_inc_absorb(sha3_256incctx *state, const uint8_t *input, size_t inlen) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    keccak_inc_absorb(state->ctx, SHA3_256_RATE, input, inlen);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void sha3_256_inc_finalize(uint8_t *output, sha3_256incctx *state) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    uint8_t t[SHA3_256_RATE];
    keccak_inc_finalize(state->ctx, SHA3_256_RATE, 0x06);

    keccak_squeezeblocks(t, 1, state->ctx, SHA3_256_RATE);

    for (size_t i = 0; i < 32; i++) {
        output[i] = t[i];
    }
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void sha3_256_inc_ctx_clone(sha3_256incctx *dest, const sha3_256incctx *src) {
    memcpy(dest, src, sizeof(sha3_256incctx));
}

void sha3_256_inc_ctx_release(sha3_256incctx *state) {
    (void) state;
}

void sha3_384_inc_init(sha3_384incctx *state) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    keccak_inc_init(state->ctx);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void sha3_384_inc_absorb(sha3_384incctx *state, const uint8_t *input, size_t inlen) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    keccak_inc_absorb(state->ctx, SHA3_384_RATE, input, inlen);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void sha3_384_inc_finalize(uint8_t *output, sha3_384incctx *state) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    uint8_t t[SHA3_384_RATE];
    keccak_inc_finalize(state->ctx, SHA3_384_RATE, 0x06);

    keccak_squeezeblocks(t, 1, state->ctx, SHA3_384_RATE);

    for (size_t i = 0; i < 48; i++) {
        output[i] = t[i];
    }
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void sha3_384_inc_ctx_clone(sha3_384incctx *dest, const sha3_384incctx *src) {
    memcpy(dest, src, sizeof(sha3_384incctx));
}

void sha3_384_inc_ctx_release(sha3_384incctx *state) {
    (void) state;
}

/*************************************************
 * Name:        sha3_384
 *
 * Description: SHA3-256 with non-incremental API
 *
 * Arguments:   - uint8_t *output:      pointer to output
 *              - const uint8_t *input: pointer to input
 *              - size_t inlen:   length of input in bytes
 **************************************************/
void sha3_384(uint8_t *output, const uint8_t *input, size_t inlen) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    uint64_t s[25];
    uint8_t t[SHA3_384_RATE];

    /* Absorb input */
    keccak_absorb(s, SHA3_384_RATE, input, inlen, 0x06);

    /* Squeeze output */
    keccak_squeezeblocks(t, 1, s, SHA3_384_RATE);

    for (size_t i = 0; i < 48; i++) {
        output[i] = t[i];
    }
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}
/*************************************************
 * Name:        sha3_512
 *
 * Description: SHA3-512 with non-incremental API
 *
 * Arguments:   - uint8_t *output:      pointer to output
 *              - const uint8_t *input: pointer to input
 *              - size_t inlen:         length of input in bytes
 **************************************************/
void sha3_512(uint8_t *output, const uint8_t *input, size_t inlen)
{
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
  uint64_t s[25] = {0};
  uint8_t t[SHA3_512_RATE];
  size_t i;

  /* Absorb input */
  keccak_absorb(s, SHA3_512_RATE, input, inlen, 0x06);

  /* Squeeze output */
  keccak_squeezeblocks(t, 1, s, SHA3_512_RATE);

  for(i=0;i<64;i++)
    output[i] = t[i];
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}
void sha3_512_inc_init(sha3_512incctx *state) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    keccak_inc_init(state->ctx);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void sha3_512_inc_absorb(sha3_512incctx *state, const uint8_t *input, size_t inlen) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    keccak_inc_absorb(state->ctx, SHA3_512_RATE, input, inlen);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void sha3_512_inc_finalize(uint8_t *output, sha3_512incctx *state) {
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
    uint8_t t[SHA3_512_RATE];
    keccak_inc_finalize(state->ctx, SHA3_512_RATE, 0x06);

    keccak_squeezeblocks(t, 1, state->ctx, SHA3_512_RATE);

    for (size_t i = 0; i < 64; i++) {
        output[i] = t[i];
    }
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}

void sha3_512_inc_ctx_clone(sha3_512incctx *dest, const sha3_512incctx *src) {
    memcpy(dest, src, sizeof(sha3_512incctx));
}

void sha3_512_inc_ctx_release(sha3_512incctx *state) {
    (void) state;
}

/********** cSHAKE256 ***********/

void cshake256_simple_absorb(shake256ctx *state, uint16_t cstm, const uint8_t *in, size_t inlen)
{
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
  uint8_t sep[8];
  size_t i;

  for (i = 0; i < 25; i++)
    state->ctx[i] = 0;

  /* Absorb customization (domain-separation) string */
  sep[0] = 0x01;
  sep[1] = 0x88;
  sep[2] = 0x01;
  sep[3] = 0x00;
  sep[4] = 0x01;
  sep[5] = 16; // fixed bitlen of cstm
  sep[6] = cstm & 0xff;
  sep[7] = cstm >> 8;

  KeccakF1600_StateXORBytes(state->ctx, sep, 0, 8);
  KeccakF1600_StatePermute(state->ctx);

  /* Absorb input */
  keccak_absorb(state->ctx, SHAKE256_RATE, in, inlen, 0x04);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}


void cshake256_simple_squeezeblocks(uint8_t *output, size_t nblocks, shake256ctx *state)
{
#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif
  keccak_squeezeblocks(output, nblocks, state->ctx, SHAKE256_RATE);
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}


void cshake256_simple(uint8_t *output, size_t outlen, uint16_t cstm, const uint8_t *in, size_t inlen)
{
  shake256ctx state;
  uint8_t t[SHAKE256_RATE];
  size_t i;

  cshake256_simple_absorb(&state, cstm, in, inlen);

#ifdef PROFILE_HASHING
  uint64_t t0 = hal_get_time();
#endif

  /* Squeeze output */
  keccak_squeezeblocks(output, outlen/SHAKE256_RATE, state.ctx, SHAKE256_RATE);
  output += (outlen/SHAKE256_RATE)*SHAKE256_RATE;

  if(outlen%SHAKE256_RATE)
  {
    keccak_squeezeblocks(t, 1, state.ctx, SHAKE256_RATE);
    for (i = 0; i < outlen%SHAKE256_RATE; i++)
      output[i] = t[i];
  }
#ifdef PROFILE_HASHING
  uint64_t t1 = hal_get_time();
  hash_cycles += (t1-t0);
#endif
}
