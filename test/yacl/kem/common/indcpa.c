#include "indcpa.h"
#include "ntt.h"
#include "params.h"
#include "poly.h"
#include "polyvec.h"
#include "randombytes.h"
#include "symmetric.h"
#include "rng.h"
#include <stddef.h>
#include <stdint.h>
#include <string.h>

/*************************************************
* Name:        pack_pk
*
* Description: Serialize the public key as concatenation of the
*              serialized vector of polynomials pk
*              and the public seed used to generate the matrix A.
*
* Arguments:   uint8_t *r: pointer to the output serialized public key
*              polyvec *pk: pointer to the input public-key polyvec
*              const uint8_t *seed: pointer to the input public seed
**************************************************/
static void pack_pk(uint8_t r[KYBER_INDCPA_PUBLICKEYBYTES],
                    polyvec *pk,
                    const uint8_t seed[KYBER_SYMBYTES]) {
    polyvec_tobytes(r, pk);
    memcpy(r + KYBER_POLYVECBYTES, seed, KYBER_SYMBYTES);
}

/*************************************************
* Name:        unpack_pk
*
* Description: De-serialize public key from a byte array;
*              approximate inverse of pack_pk
*
* Arguments:   - polyvec *pk: pointer to output public-key polynomial vector
*              - uint8_t *seed: pointer to output seed to generate matrix A
*              - const uint8_t *packedpk: pointer to input serialized public key
**************************************************/
static void unpack_pk(polyvec *pk,
                      uint8_t seed[KYBER_SYMBYTES],
                      const uint8_t packedpk[KYBER_INDCPA_PUBLICKEYBYTES]) {
    polyvec_frombytes(pk, packedpk);
    memcpy(seed, packedpk + KYBER_POLYVECBYTES, KYBER_SYMBYTES);
}

/*************************************************
* Name:        pack_sk
*
* Description: Serialize the secret key
*
* Arguments:   - uint8_t *r: pointer to output serialized secret key
*              - polyvec *sk: pointer to input vector of polynomials (secret key)
**************************************************/
static void pack_sk(uint8_t r[KYBER_INDCPA_SECRETKEYBYTES], polyvec *sk) {
    polyvec_tobytes(r, sk);
}

/*************************************************
* Name:        unpack_sk
*
* Description: De-serialize the secret key; inverse of pack_sk
*
* Arguments:   - polyvec *sk: pointer to output vector of polynomials (secret key)
*              - const uint8_t *packedsk: pointer to input serialized secret key
**************************************************/
static void unpack_sk(polyvec *sk, const uint8_t packedsk[KYBER_INDCPA_SECRETKEYBYTES]) {
    polyvec_frombytes(sk, packedsk);
}

/*************************************************
* Name:        pack_ciphertext
*
* Description: Serialize the ciphertext as concatenation of the
*              compressed and serialized vector of polynomials b
*              and the compressed and serialized polynomial v
*
* Arguments:   uint8_t *r: pointer to the output serialized ciphertext
*              poly *pk: pointer to the input vector of polynomials b
*              poly *v: pointer to the input polynomial v
**************************************************/
static void pack_ciphertext(uint8_t r[KYBER_INDCPA_BYTES], polyvec *b, poly *v) {
    polyvec_compress(r, b);
    //--printBstr("CPA_c1", r, KYBER_POLYVECCOMPRESSEDBYTES);
    poly_compress(r + KYBER_POLYVECCOMPRESSEDBYTES, v);
    //--printBstr("CPA_c2", r+KYBER_POLYVECCOMPRESSEDBYTES, KYBER_POLYCOMPRESSEDBYTES);
}

/*************************************************
* Name:        unpack_ciphertext
*
* Description: De-serialize and decompress ciphertext from a byte array;
*              approximate inverse of pack_ciphertext
*
* Arguments:   - polyvec *b: pointer to the output vector of polynomials b
*              - poly *v: pointer to the output polynomial v
*              - const uint8_t *c: pointer to the input serialized ciphertext
**************************************************/
static void unpack_ciphertext(polyvec *b, poly *v, const uint8_t c[KYBER_INDCPA_BYTES]) {
    printf("unpack_ciphertext : \n");
    //--printBstr("CPA_c1", c, KYBER_POLYVECCOMPRESSEDBYTES);
    polyvec_decompress(b, c);
    //--printCoeff("[u0]", b->vec[0].coeffs);
    //--printBstr("CPA_c2", c+KYBER_POLYVECCOMPRESSEDBYTES, KYBER_POLYCOMPRESSEDBYTES);  
    poly_decompress(v, c + KYBER_POLYVECCOMPRESSEDBYTES);
    //--printCoeff("[v]", v->coeffs);    
}

/*************************************************
* Name:        rej_uniform
*
* Description: Run rejection sampling on uniform random bytes to generate
*              uniform random integers mod q
*
* Arguments:   - int16_t *r: pointer to output buffer
*              - unsigned int len: requested number of 16-bit integers (uniform mod q)
*              - const uint8_t *buf: pointer to input buffer (assumed to be uniformly random bytes)
*              - unsigned int buflen: length of input buffer in bytes
*
* Returns number of sampled 16-bit integers (at most len)
**************************************************/
static unsigned int rej_uniform(int16_t *r,
                                unsigned int len,
                                const uint8_t *buf,
                                unsigned int buflen) {
    unsigned int ctr, pos;
    uint16_t val0, val1;

    ctr = pos = 0;
    while (ctr < len && pos + 3 <= buflen) {
        val0 = ((buf[pos + 0] >> 0) | ((uint16_t)buf[pos + 1] << 8)) & 0xFFF;
        val1 = ((buf[pos + 1] >> 4) | ((uint16_t)buf[pos + 2] << 4)) & 0xFFF;
        pos += 3;

        if (val0 < KYBER_Q) {
            r[ctr++] = val0;
        }
        if (ctr < len && val1 < KYBER_Q) {
            r[ctr++] = val1;
        }
    }

    return ctr;
}

#define gen_a(A,B)  gen_matrix(A,B,0)
#define gen_at(A,B) gen_matrix(A,B,1)

/*************************************************
* Name:        gen_matrix
*
* Description: Deterministically generate matrix A (or the transpose of A)
*              from a seed. Entries of the matrix are polynomials that look
*              uniformly random. Performs rejection sampling on output of
*              a XOF
*
* Arguments:   - polyvec *a: pointer to ouptput matrix A
*              - const uint8_t *seed: pointer to input seed
*              - int transposed: boolean deciding whether A or A^T is generated
**************************************************/

#define GEN_MATRIX_NBLOCKS ((12*KYBER_N/8*(1 << 12)/KYBER_Q + XOF_BLOCKBYTES)/XOF_BLOCKBYTES)
// Not static for benchmarking
void gen_matrix(polyvec *a, const uint8_t seed[KYBER_SYMBYTES], int transposed) {
    unsigned int ctr, i, j;
    unsigned int buflen;
    uint8_t buf[GEN_MATRIX_NBLOCKS * XOF_BLOCKBYTES];
    xof_state state;

    for (i = 0; i < KYBER_K; i++) {
        for (j = 0; j < KYBER_K; j++) {
            if (transposed) {
                printf("CPA_AT[%d][%d]: \n", i, j);
                xof_absorb(&state, seed, (uint8_t)i, (uint8_t)j);
            } else {
                printf("CPA_A[%d][%d]: \n", i, j);
                xof_absorb(&state, seed, (uint8_t)j, (uint8_t)i);
            }

            xof_squeezeblocks(buf, GEN_MATRIX_NBLOCKS, &state);
            buflen = GEN_MATRIX_NBLOCKS * XOF_BLOCKBYTES;
            ctr = rej_uniform(a[i].vec[j].coeffs, KYBER_N, buf, buflen);
            //--printBstr("CPA_SHAKE128", buf, buflen);

            while (ctr < KYBER_N) {
                xof_squeezeblocks(buf, 1, &state);
                buflen = XOF_BLOCKBYTES;
                //--printBstr("CPA_SHAKE128", buf, buflen);
                ctr += rej_uniform(a[i].vec[j].coeffs + ctr, KYBER_N - ctr, buf, buflen);
            }
            xof_ctx_release(&state);
            //--printCoeff("[CPA_coeffs]", a[i].vec[j].coeffs);
        }
    }
}

/*************************************************
* Name:        indcpa_keypair_derand
*
* Description: Generates public and private key for the CPA-secure
*              public-key encryption scheme underlying Kyber
*
* Arguments:   - uint8_t *pk: pointer to output public key
*                             (of length KYBER_INDCPA_PUBLICKEYBYTES bytes)
*              - uint8_t *sk: pointer to output private key
*                             (of length KYBER_INDCPA_SECRETKEYBYTES bytes)
*              - const uint8_t *coins: pointer to input randomness
*                             (of length KYBER_SYMBYTES bytes)
**************************************************/
void indcpa_keypair_derand(uint8_t pk[KYBER_INDCPA_PUBLICKEYBYTES],
        uint8_t sk[KYBER_INDCPA_SECRETKEYBYTES],
        const uint8_t coins[KYBER_SYMBYTES]) {
    unsigned int i;
    uint8_t buf[2 * KYBER_SYMBYTES];
    const uint8_t *publicseed = buf;
    const uint8_t *noiseseed = buf + KYBER_SYMBYTES;
    uint8_t nonce = 0;
    polyvec a[KYBER_K], e, pkpv, skpv;

    memcpy(buf, coins, KYBER_SYMBYTES);
    buf[KYBER_SYMBYTES] = KYBER_K;
    //--printBstr("CPA_d", buf, KYBER_SYMBYTES);
    hash_g(buf, buf, KYBER_SYMBYTES + 1);

    //--printBstr("CPA_rho", buf, KYBER_SYMBYTES);                  // buf前32字节存rho
    //--printBstr("CPA_sigma", buf+KYBER_SYMBYTES, KYBER_SYMBYTES); // buf后32字节存sigma
  
    printf("CPA: GenMatrix_A:\n");
    gen_a(a, publicseed);

    for (i = 0; i < KYBER_K; i++) {
        printf("CPA_s[%d]: \n", i);
        poly_getnoise_eta1(&skpv.vec[i], noiseseed, nonce++);
    }
    for (i = 0; i < KYBER_K; i++) {
        printf("CPA_e[%d]: \n", i);
        poly_getnoise_eta1(&e.vec[i], noiseseed, nonce++);
    }
    printf("CPA_ntt(s):\n");
    polyvec_ntt(&skpv);
    printf("CPA_ntt(e):\n");
    polyvec_ntt(&e);

    printf("CPA: t=A*s+e :\n");
    // matrix-vector multiplication
    for (i = 0; i < KYBER_K; i++) {
        printf("\t tmp = A[%d] * s:\n", i);                                // t = As
        //--printCoeff("A?0", a[i].vec[0].coeffs);
        //--printCoeff("A?1", a[i].vec[1].coeffs);
        //--printCoeff("s0", skpv.vec[0].coeffs);
        //--printCoeff("s1", skpv.vec[1].coeffs);
        polyvec_basemul_acc_montgomery(&pkpv.vec[i], &a[i], &skpv);
        poly_tomont(&pkpv.vec[i]);
        //--printCoeff("tmp", pkpv.vec[i].coeffs);
    }

    polyvec_add(&pkpv, &pkpv, &e);
    //--printCoeff("CPA_t[0]",pkpv.vec[0].coeffs);
    //--printCoeff("CPA_t[1]",pkpv.vec[1].coeffs);
    polyvec_reduce(&pkpv);
    //--printCoeff("CPA_t[0]_reduce",pkpv.vec[0].coeffs);
    //--printCoeff("CPA_t[1]_reduce",pkpv.vec[1].coeffs);

    pack_sk(sk, &skpv);
    pack_pk(pk, &pkpv, publicseed);
}


/*************************************************
* Name:        indcpa_enc
*
* Description: Encryption function of the CPA-secure
*              public-key encryption scheme underlying Kyber.
*
* Arguments:   - uint8_t *c: pointer to output ciphertext
*                            (of length KYBER_INDCPA_BYTES bytes)
*              - const uint8_t *m: pointer to input message
*                                  (of length KYBER_INDCPA_MSGBYTES bytes)
*              - const uint8_t *pk: pointer to input public key
*                                   (of length KYBER_INDCPA_PUBLICKEYBYTES)
*              - const uint8_t *coins: pointer to input random coins used as seed
*                                      (of length KYBER_SYMBYTES) to deterministically
*                                      generate all randomness
**************************************************/
void indcpa_enc(uint8_t c[KYBER_INDCPA_BYTES],
                                       const uint8_t m[KYBER_INDCPA_MSGBYTES],
                                       const uint8_t pk[KYBER_INDCPA_PUBLICKEYBYTES],
                                       const uint8_t coins[KYBER_SYMBYTES]) {
    unsigned int i;
    uint8_t seed[KYBER_SYMBYTES];
    uint8_t nonce = 0;
    polyvec sp, pkpv, ep, at[KYBER_K], b;
    poly v, k, epp;

    printf("CPA: t=Decode12(pk) :\n");
    unpack_pk(&pkpv, seed, pk);
    //--printBstr("CPA_input_pk", (unsigned char*)&pk[0], KYBER_INDCPA_PUBLICKEYBYTES);
    //--printCoeff("CPA_input_t[0]",pkpv.vec[0].coeffs);
    //--printCoeff("CPA_input_t[1]",pkpv.vec[1].coeffs);
    //--printBstr("CPA_input_rho", seed, KYBER_SYMBYTES);

    printf("CPA: Decompress(Decode1(m),1):\n");
    //--printBstr("CPA_input_m", (unsigned char*)&m[0], KYBER_INDCPA_MSGBYTES);
    poly_frommsg(&k, m);
    //--printCoeff("[CPA_poly_m]", k.coeffs);

    gen_at(at, seed);

    for (i = 0; i < KYBER_K; i++) {
        printf("CPA_r[%d]: \n", i);
        //--printBstr("CPA_input_r", (unsigned char*)&coins[0], KYBER_SYMBYTES);    
        poly_getnoise_eta1(sp.vec + i, coins, nonce++);
    }
    for (i = 0; i < KYBER_K; i++) {
        printf("CPA_e1[%d]: \n", i);
        poly_getnoise_eta2(ep.vec + i, coins, nonce++);
    }
    printf("CPA_e2: \n");
    poly_getnoise_eta2(&epp, coins, nonce++);

    printf("CPA_ntt(r):\n");
    polyvec_ntt(&sp);

    // matrix-vector multiplication
    for (i = 0; i < KYBER_K; i++) {
        polyvec_basemul_acc_montgomery(&b.vec[i], &at[i], &sp);
    }

    polyvec_basemul_acc_montgomery(&v, &pkpv, &sp);

    polyvec_invntt_tomont(&b);
    poly_invntt_tomont(&v);

    printf("CPA_u = Ar+e1 : \n");
    polyvec_add(&b, &b, &ep);
    //--printCoeff("CPA_u[0]",b.vec[0].coeffs);
    //--printCoeff("CPA_u[1]",b.vec[1].coeffs); 

    printf("CPA: v = invntt(tt*r)+e2+Decompress(Decode1(m),1) \n");
    poly_add(&v, &v, &epp);
    poly_add(&v, &v, &k);
    //--printCoeff("CPA_v", v.coeffs);

    polyvec_reduce(&b);
    //--printCoeff("CPA_u[0]_reduce",b.vec[0].coeffs);
    //--printCoeff("CPA_u[1]_reduce",b.vec[1].coeffs);

    poly_reduce(&v);
    //--printCoeff("CPA_v_reduce", v.coeffs);

    printf("CPA_pack_ciphertext:\n");
    pack_ciphertext(c, &b, &v);
}

/*************************************************
* Name:        indcpa_dec
*
* Description: Decryption function of the CPA-secure
*              public-key encryption scheme underlying Kyber.
*
* Arguments:   - uint8_t *m: pointer to output decrypted message
*                            (of length KYBER_INDCPA_MSGBYTES)
*              - const uint8_t *c: pointer to input ciphertext
*                                  (of length KYBER_INDCPA_BYTES)
*              - const uint8_t *sk: pointer to input secret key
*                                   (of length KYBER_INDCPA_SECRETKEYBYTES)
**************************************************/
void indcpa_dec(uint8_t m[KYBER_INDCPA_MSGBYTES],
                                       const uint8_t c[KYBER_INDCPA_BYTES],
                                       const uint8_t sk[KYBER_INDCPA_SECRETKEYBYTES]) {
    polyvec b, skpv;
    poly v, mp;

    unpack_ciphertext(&b, &v, c);
    unpack_sk(&skpv, sk);

    printf("CPA_ntt(u):\n");
    polyvec_ntt(&b);
    polyvec_basemul_acc_montgomery(&mp, &skpv, &b);
    poly_invntt_tomont(&mp);

    poly_sub(&mp, &v, &mp);
    poly_reduce(&mp);

    poly_tomsg(m, &mp);
}
