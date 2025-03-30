#include "indcpa.h"
#include "masked.h"
#include "masked-poly.h"
#include "masked-polyvec.h"
#include "ntt.h"
#include "poly.h"
#include "polyvec.h"
#include "randombytes.h"
#include "symmetric.h"
#include "masked-comparison.h"
#include "api.h"
#include "pqm4-hal.h"

#include <string.h>
#include <stdio.h>
#include <stdint.h>

extern void doublebasemul_asm_acc(int16_t *r, const int16_t *a, const int16_t *b, int16_t zeta);
/*************************************************
* Name:        matacc
*
* Description: Multiplies a row of A or A^T, generated on-the-fly,
*              with a vector of polynomials and accumulates into the result.
*
* Arguments:   - poly *r:                    pointer to output polynomial to accumulate in
*              - polyvec *b:                 pointer to input vector of polynomials to multiply with
*              - unsigned char i:            byte to indicate the index < KYBER_K of the row of A or A^T
*              - const unsigned char *seed:  pointer to the public seed used to generate A
*              - int transposed:             boolean indicatin whether A or A^T is generated
**************************************************/
static void matacc(poly* r, polyvec *b, unsigned char i, const unsigned char *seed, int transposed) {
  unsigned char buf[XOF_BLOCKBYTES+2];
  unsigned int buflen, off;
  xof_state state;
  unsigned int ctr, pos, k, l;
  uint16_t val0, val1;
  int16_t c[4];

  poly_zeroize(r);

  for(int j=0;j<KYBER_K;j++) {
    ctr = pos = 0;
    if (transposed)
      xof_absorb(&state, seed, i, j);
    else
      xof_absorb(&state, seed, j, i);

    xof_squeezeblocks(buf, 1, &state);
    buflen = XOF_BLOCKBYTES;

    k = 0;
    while (ctr < KYBER_N/4)
    {
      val0 = ((buf[pos+0] >> 0) | ((uint16_t)buf[pos+1] << 8)) & 0xFFF;
      val1 = ((buf[pos+1] >> 4) | ((uint16_t)buf[pos+2] << 4)) & 0xFFF;
      pos += 3;

      if (val0 < KYBER_Q) {
        c[k++] = (int16_t) val0;
        if (k == 4) {
          doublebasemul_asm_acc(&r->coeffs[4*ctr], &b->vec[j].coeffs[4*ctr], c, zetas[ctr]);
          ctr++;
          k = 0;
        }
      }

      if (val1 < KYBER_Q && ctr < KYBER_Q/4) {
        c[k++] = (int16_t) val1;
        if (k == 4) {
          doublebasemul_asm_acc(&r->coeffs[4*ctr], &b->vec[j].coeffs[4*ctr], c, zetas[ctr]);
          ctr++;
          k = 0;
        }
      }

      if (pos + 3 > buflen && ctr < KYBER_Q/4) {
        off = buflen % 3;
        for(l = 0; l < off; l++)
          buf[l] = buf[buflen - off + l];
        xof_squeezeblocks(buf + off, 1, &state);
        buflen = off + XOF_BLOCKBYTES;
        pos = 0;
      }
    }
  }
}

static void masked_matacc(masked_poly* r, masked_polyvec* b, unsigned char i, const unsigned char* seed, int transposed) {

	unsigned char buf[XOF_BLOCKBYTES + 2];
	unsigned int buflen, off;
	xof_state state;
	unsigned int ctr, pos, j, k, l;
	uint16_t val0, val1;
	int16_t c[4];

	for (l = 0; l < MASKING_N; l++) {
		poly_zeroize(&r->polys[l]);
	}

	for (j = 0; j < KYBER_K; j++) {
		ctr = pos = 0;
		if (transposed)
			xof_absorb(&state, seed, i, j);
		else
			xof_absorb(&state, seed, j, i);

		xof_squeezeblocks(buf, 1, &state);
		buflen = XOF_BLOCKBYTES;

		k = 0;
		while (ctr < KYBER_N / 4)
		{
			val0 = ((buf[pos + 0] >> 0) | ((uint16_t)buf[pos + 1] << 8)) & 0xFFF;
			val1 = ((buf[pos + 1] >> 4) | ((uint16_t)buf[pos + 2] << 4)) & 0xFFF;
			pos += 3;

			if (val0 < KYBER_Q) {
				c[k++] = (int16_t)val0;
				if (k == 4) {
					for (l = 0; l < MASKING_N; l++) {
						doublebasemul_asm_acc(&r->polys[l].coeffs[4 * ctr], &b->vec[j].polys[l].coeffs[4 * ctr], c, zetas[ctr]);
					}
					ctr++;
					k = 0;
				}
			}

			if (val1 < KYBER_Q && ctr < KYBER_N / 4) {
				c[k++] = (int16_t)val1;
				if (k == 4) {
					for (l = 0; l < MASKING_N; l++) {
						doublebasemul_asm_acc(&r->polys[l].coeffs[4 * ctr], &b->vec[j].polys[l].coeffs[4 * ctr], c, zetas[ctr]);
					}
					ctr++;
					k = 0;
				}
			}

			if (pos + 3 > buflen && ctr < KYBER_N / 4) {
				off = buflen % 3;
				for (l = 0; l < off; l++)
					buf[l] = buf[buflen - off + l];
				xof_squeezeblocks(buf + off, 1, &state);
				buflen = off + XOF_BLOCKBYTES;
				pos = 0;
			}
		}
	}
}



/*************************************************
* Name:        indcpa_keypair
*
* Description: Generates public and private key for the CPA-secure
*              public-key encryption scheme underlying Kyber
*
* Arguments:   - unsigned char *pk: pointer to output public key (of length KYBER_INDCPA_PUBLICKEYBYTES bytes)
*              - unsigned char *sk: pointer to output private key (of length KYBER_INDCPA_SECRETKEYBYTES bytes)
**************************************************/
void indcpa_keypair(unsigned char *pk, masked_polyvec *sk) {
    masked_poly mpkp, mep;
    unsigned char publicseed[KYBER_SYMBYTES];
    masked_u8_symbytes noiseseed;
    int i;
    unsigned char nonce = 0;

    masked_randombytes(&noiseseed, KYBER_SYMBYTES);
    randombytes(publicseed, KYBER_SYMBYTES);

    hash_h(publicseed, publicseed, KYBER_SYMBYTES);             // Don't reveal output of system RNG

    for (i = 0; i < KYBER_K; i++)
        masked_poly_getnoise(sk->vec + i, &noiseseed, nonce++);

    masked_polyvec_ntt(sk);

    for (i = 0; i < KYBER_K; i++) {
        masked_matacc(&mpkp, sk, i, publicseed, 0);

    
        masked_poly_invntt(&mpkp);
        masked_poly_getnoise(&mep, &noiseseed, nonce++);
        masked_poly_add2(&mpkp, &mep);
        masked_poly_ntt(&mpkp);

        masked_poly_tobytes(pk+i*KYBER_POLYBYTES, &mpkp);        // Internally de-masks
    }

    memcpy(pk + KYBER_POLYVECBYTES, publicseed, KYBER_SYMBYTES);
}

/*************************************************
* Name:        indcpa_enc
*
* Description: Encryption function of the CPA-secure
*              public-key encryption scheme underlying Kyber.
*
* Arguments:   - unsigned char *c:          pointer to output ciphertext (of length KYBER_INDCPA_BYTES bytes)
*              - const unsigned char *m:    pointer to input message (of length KYBER_INDCPA_MSGBYTES bytes)
*              - const unsigned char *pk:   pointer to input public key (of length KYBER_INDCPA_PUBLICKEYBYTES bytes)
*              - const unsigned char *coin: pointer to input random coins used as seed (of length KYBER_SYMBYTES bytes)
*                                           to deterministically generate all randomness
**************************************************/
void indcpa_enc(unsigned char *c,
               const unsigned char *m,
               const unsigned char *pk,
               const unsigned char *coins) {
    polyvec sp;
    poly bp;
    poly *pkp = &bp;
    poly *k = &bp;
    poly *v = &sp.vec[0];
    const unsigned char *seed = pk+KYBER_POLYVECBYTES;
    int i;
    unsigned char nonce = 0;

    for (i = 0; i < KYBER_K; i++)
        poly_getnoise(sp.vec + i, coins, nonce++);

    polyvec_ntt(&sp);

    for (i = 0; i < KYBER_K; i++) {
        matacc(&bp, &sp, i, seed, 1);
        poly_invntt(&bp);

        poly_addnoise(&bp, coins, nonce++);
        poly_reduce(&bp);

        poly_packcompress(c, &bp, i);
    }

    poly_frombytes(pkp, pk);
    poly_basemul(v, pkp, &sp.vec[0]);
    for (i = 1; i < KYBER_K; i++) {
        poly_frombytes(pkp, pk + i*KYBER_POLYBYTES);
        poly_basemul_acc(v, pkp, &sp.vec[i]);
    }

    poly_invntt(v);

    poly_addnoise(v, coins, nonce++);

    poly_frommsg(k, m);
    poly_add(v, v, k);
    poly_reduce(v);

    poly_compress(c + KYBER_POLYVECCOMPRESSEDBYTES, v);
}

/*************************************************
* Name:        indcpa_enc_cmp
*
* Description: Re-encryption function.
*              Compares the re-encypted ciphertext with the original ciphertext byte per byte.
*              The comparison is performed in a constant time manner.
*
*
* Arguments:   - unsigned char *ct:         pointer to input ciphertext to compare the new ciphertext with (of length KYBER_INDCPA_BYTES bytes)
*              - const unsigned char *m:    pointer to input message (of length KYBER_INDCPA_MSGBYTES bytes)
*              - const unsigned char *pk:   pointer to input public key (of length KYBER_INDCPA_PUBLICKEYBYTES bytes)
*              - const unsigned char *coin: pointer to input random coins used as seed (of length KYBER_SYMBYTES bytes)
*                                           to deterministically generate all randomness
* Returns:     - boolean byte indicating that re-encrypted ciphertext is NOT equal to the original ciphertext
**************************************************/
#ifdef DETAILBENCHMARK
unsigned char indcpa_maskedenc_cmp(const unsigned char *c,
                                   const masked_u8_msgbytes *m,
                                   const unsigned char *pk,
                                   const masked_u8_symbytes *coins, struct decaps_measurements *details) {
    masked_polyvec sp;
    masked_polyvec mbpv;
    poly pkp;
    masked_poly v;
    const unsigned char *seed = pk+KYBER_POLYVECBYTES;
    int i;
    unsigned char nonce = 0;
    uint64_t t0, t1, baseline, Tenc;

    Tenc = hal_get_time();
    t1 = hal_get_time();
    baseline = t1 - Tenc;

    t0 = hal_get_time();
    for (i = 0; i < KYBER_K; i++)
        masked_poly_getnoise(sp.vec + i, coins, nonce++);
    
    t1 = hal_get_time();
    details->encsample += t1 - t0 - baseline;

    t0 = hal_get_time();
    masked_polyvec_ntt(&sp);
    t1 = hal_get_time();
    details->encarith += t1 - t0 - baseline;

    for (i = 0; i < KYBER_K; i++) {
        t0 = hal_get_time();
        masked_matacc(&mbpv.vec[i], &sp, i, seed, 1);
        t1 = hal_get_time();
        details->encmatacc += t1 - t0 - baseline;

        t0 = hal_get_time();
        masked_poly_invntt(&mbpv.vec[i]);
        t1 = hal_get_time();
        details->encarith += t1 - t0 - baseline;

        t0 = hal_get_time();
        masked_poly_addnoise(&mbpv.vec[i], coins, nonce++);
        t1 = hal_get_time();
        details->encsample += t1 - t0 - baseline;

        t0 = hal_get_time();
        masked_poly_reduce(&mbpv.vec[i]);
        t1 = hal_get_time();
        details->encarith += t1 - t0 - baseline;
    }

    t0 = hal_get_time();
    poly_frombytes(&pkp, pk);
    masked_poly_basemul(&v, &pkp, &sp.vec[0]);
    for (i = 1; i < KYBER_K; i++) {
        poly_frombytes(&pkp, pk + i*KYBER_POLYBYTES);

        masked_poly_basemul_acc(&v, &pkp, &sp.vec[i]);
       
    }

    t1 = hal_get_time();
    details->encarith += t1 - t0 - baseline;

    t0 = hal_get_time();
    masked_poly_invntt(&v);
    t1 = hal_get_time();
    details->encarith += t1 - t0 - baseline;

    t0 = hal_get_time();
    masked_poly_addnoise(&v, coins, nonce++);
    t1 = hal_get_time();
    details->encarith += t1 - t0 - baseline;

    t0 = hal_get_time();
    masked_poly_frommsg(&v, m);
    t1 = hal_get_time();
    details->decompress += t1 - t0 - baseline;

    t0 = hal_get_time();
    masked_poly_reduce(&v);
    t1 = hal_get_time();
    details->encarith += t1 - t0 - baseline;
    
    details->reenc += t1 - Tenc - baseline;

    t0 = hal_get_time();
    unsigned char ret = masked_decompressed_ct_cmp(c, &mbpv, &v);
    t1 = hal_get_time();
    details->comp += t1 - t0 - baseline;
    //return masked_ct_compare(c, &mbpv, &v);
    return ret;
}

void __attribute__ ((noinline)) indcpa_dec(masked_u8_msgbytes *m,
                                           const unsigned char *c,
                                           const masked_polyvec *sk, struct decaps_measurements *details) {
    poly mp, bp;
    poly *v = &bp;
    masked_poly mt;
    uint64_t t0, t1, baseline;

    t0 = hal_get_time();
    t1 = hal_get_time();
    baseline = t1 - t0;

    t0 = hal_get_time();
    poly_unpackdecompress(&mp, c, 0);
    t1 = hal_get_time();
    details->unpackdecomp += t1 - t0 - baseline;

    t0 = hal_get_time();
    poly_ntt(&mp);
    masked_poly_basemul(&mt, &mp, &sk->vec[0]);
    t1 = hal_get_time();
    details->decarith += t1 - t0 - baseline;

    for(int i = 1; i < KYBER_K; i++) {
        t0 = hal_get_time();
        poly_unpackdecompress(&bp, c, i);
        t1 = hal_get_time();
        details->unpackdecomp += t1 - t0 - baseline;

        t0 = hal_get_time();
        poly_ntt(&bp);
        masked_poly_basemul_acc(&mt, &bp, &sk->vec[i]);
        t1 = hal_get_time();
        details->decarith += t1 - t0 - baseline;
    }

    t0 = hal_get_time();
    masked_poly_invntt(&mt);
    t1 = hal_get_time();
    details->decarith += t1 - t0 - baseline;

    t0 = hal_get_time();
    poly_decompress(v, c+KYBER_POLYVECCOMPRESSEDBYTES);
    t1 = hal_get_time();
    details->unpackdecomp += t1 - t0 - baseline;

    t0 = hal_get_time();
    masked_poly_sub(&mt, v, &mt);
    masked_poly_reduce(&mt);
    t1 = hal_get_time();
    details->decarith += t1 - t0 - baseline;

    t0 = hal_get_time();
    masked_poly_tomsg(m, &mt);
    t1 = hal_get_time();
    details->compress += t1 - t0 - baseline;
}
#else
unsigned char indcpa_maskedenc_cmp(const unsigned char *c,
                                   const masked_u8_msgbytes *m,
                                   const unsigned char *pk,
                                   const masked_u8_symbytes *coins) {
    masked_polyvec sp;
    masked_polyvec mbpv;
    poly pkp;
    masked_poly v;
    const unsigned char *seed = pk+KYBER_POLYVECBYTES;
    int i;
    unsigned char nonce = 0;
    for (i = 0; i < KYBER_K; i++)
        masked_poly_getnoise(sp.vec + i, coins, nonce++);

    masked_polyvec_ntt(&sp);

    for (i = 0; i < KYBER_K; i++) {
        masked_matacc(&mbpv.vec[i], &sp, i, seed, 1);
        masked_poly_invntt(&mbpv.vec[i]);

        masked_poly_addnoise(&mbpv.vec[i], coins, nonce++);
        masked_poly_reduce(&mbpv.vec[i]);
    }

    poly_frombytes(&pkp, pk);
    masked_poly_basemul(&v, &pkp, &sp.vec[0]);
    for (i = 1; i < KYBER_K; i++) {
        poly_frombytes(&pkp, pk + i*KYBER_POLYBYTES);
        masked_poly_basemul_acc(&v, &pkp, &sp.vec[i]);
    }

    masked_poly_invntt(&v);

    masked_poly_addnoise(&v, coins, nonce++);
    masked_poly_frommsg(&v, m);
    masked_poly_reduce(&v);

    unsigned char ret = masked_decompressed_ct_cmp(c, &mbpv, &v);

    //return masked_ct_compare(c, &mbpv, &v);
    return ret;
}
/*************************************************
* Name:        indcpa_dec
*
* Description: Decryption function of the CPA-secure
*              public-key encryption scheme underlying Kyber.
*
* Arguments:   - unsigned char *m:        pointer to output decrypted message (of length KYBER_INDCPA_MSGBYTES)
*              - const unsigned char *c:  pointer to input ciphertext (of length KYBER_INDCPA_BYTES)
*              - const unsigned char *sk: pointer to input secret key (of length KYBER_INDCPA_SECRETKEYBYTES)
**************************************************/
void __attribute__ ((noinline)) indcpa_dec(masked_u8_msgbytes *m,
                                           const unsigned char *c,
                                           const masked_polyvec *sk) {
    poly mp, bp;
    poly *v = &bp;
    masked_poly mt;

    poly_unpackdecompress(&mp, c, 0);
    poly_ntt(&mp);
    masked_poly_basemul(&mt, &mp, &sk->vec[0]);
    for(int i = 1; i < KYBER_K; i++) {
        poly_unpackdecompress(&bp, c, i);
        poly_ntt(&bp);
        masked_poly_basemul_acc(&mt, &bp, &sk->vec[i]);
    }

    masked_poly_invntt(&mt);
    poly_decompress(v, c+KYBER_POLYVECCOMPRESSEDBYTES);
    masked_poly_sub(&mt, v, &mt);
    masked_poly_reduce(&mt);
    masked_poly_tomsg(m, &mt);
}
#endif
