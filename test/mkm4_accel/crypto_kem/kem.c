#include "api.h"
#include "indcpa.h"
#include "masked.h"
#include "params.h"
#include "randombytes.h"
#include "symmetric.h"
#include "verify.h"
#include "pqm4-hal.h"

#include <stdlib.h>

#include <string.h>
#include "xil_io.h"

/*************************************************
* Name:        crypto_kem_keypair
*
* Description: Generates public and private key
*              for CCA-secure Kyber key encapsulation mechanism
*
* Arguments:   - unsigned char *pk: pointer to output public key (an already allocated array of CRYPTO_PUBLICKEYBYTES bytes)
*              - unsigned char *sk: pointer to output private key (an already allocated array of CRYPTO_SECRETKEYBYTES bytes)
*
* Returns 0 (success)
**************************************************/
int crypto_kem_keypair(unsigned char *pk, masked_sk *sk) {
    size_t i;
    indcpa_keypair(pk, &sk->indcpa_sk);

    for (i = 0; i < KYBER_INDCPA_PUBLICKEYBYTES; i++) {
        sk->pk[i] = pk[i];
    }
    hash_h(sk->hpk, pk, KYBER_PUBLICKEYBYTES);
    masked_randombytes(sk->z.share[0].u8, KYBER_SYMBYTES);    /* Value z for pseudo-random output on reject */
    return 0;
}

/*************************************************
* Name:        crypto_kem_enc
*
* Description: Generates cipher text and shared
*              secret for given public key
*
* Arguments:   - unsigned char *ct:       pointer to output cipher text (an already allocated array of CRYPTO_CIPHERTEXTBYTES bytes)
*              - unsigned char *ss:       pointer to output shared secret (an already allocated array of CRYPTO_BYTES bytes)
*              - const unsigned char *pk: pointer to input public key (an already allocated array of CRYPTO_PUBLICKEYBYTES bytes)
*
* Returns 0 (success)
**************************************************/
int crypto_kem_enc(unsigned char *ct, unsigned char *ss, const unsigned char *pk) {
    unsigned char  kr[2 * KYBER_SYMBYTES];                                   /* Will contain key, coins */
    unsigned char buf[2 * KYBER_SYMBYTES];

    randombytes(buf, KYBER_SYMBYTES);
    hash_h(buf, buf, KYBER_SYMBYTES);                                        /* Don't release system RNG output */

    hash_h(buf + KYBER_SYMBYTES, pk, KYBER_PUBLICKEYBYTES);                  /* Multitarget countermeasure for coins + contributory KEM */
    hash_g(kr, buf, 2 * KYBER_SYMBYTES);

    indcpa_enc(ct, buf, pk, kr + KYBER_SYMBYTES);                            /* coins are in kr+KYBER_SYMBYTES */

    hash_h(kr + KYBER_SYMBYTES, ct, KYBER_CIPHERTEXTBYTES);                  /* overwrite coins in kr with H(c) */
    kdf(ss, kr, 2 * KYBER_SYMBYTES);                                         /* hash concatenation of pre-k and H(c) to k */
    return 0;
}

/*************************************************
* Name:        crypto_kem_dec
*
* Description: Generates shared secret for given
*              cipher text and private key
*
* Arguments:   - unsigned char *ss:       pointer to output shared secret (an already allocated array of CRYPTO_BYTES bytes)
*              - const unsigned char *ct: pointer to input cipher text (an already allocated array of CRYPTO_CIPHERTEXTBYTES bytes)
*              - const unsigned char *sk: pointer to input private key (an already allocated array of CRYPTO_SECRETKEYBYTES bytes)
*
* Returns 0.
*
* On failure, ss will contain a pseudo-random value.
**************************************************/
#ifdef DETAILBENCHMARK
int crypto_kem_dec_masked(masked_ss *ss, const unsigned char *ct, masked_sk *sk, struct decaps_measurements *details) {
    unsigned char fail;
    masked_u8_64 kr;                                             /* Will contain key, coins */
    masked_u8_64 mbuf;
    masked_u8_msgbytes mbuf_tmp;
    masked_u8_symbytes symbuf;
    uint8_t hc[32];
    uint64_t t0, t1, baseline;


    t0 = hal_get_time();
    t1 = hal_get_time();
    baseline = t1 - t0;
    t0 = hal_get_time();
    #ifdef DETAILBENCHMARK
    indcpa_dec(&mbuf_tmp, ct, &sk->indcpa_sk,details);
    #else
    indcpa_dec(&mbuf_tmp, ct, &sk->indcpa_sk);
    #endif
    t1 = hal_get_time();
    details->indcpadec = t1 - t0 - baseline;

    for (size_t n = 0; n < MASKING_N; n++)
    {
      memcpy(mbuf.share[n].u8, mbuf_tmp.share[n].u8, KYBER_INDCPA_MSGBYTES);
    }
    
    masked_u8_mask(mbuf_tmp.share[0].u8, sk->hpk, KYBER_INDCPA_MSGBYTES);               /* Multitarget countermeasure for coins + contributory KEM; Save hash by storing H(pk) in sk */
    
    for (size_t n = 0; n < MASKING_N; n++)
    {
      memcpy(mbuf.share[n].u8 + KYBER_INDCPA_MSGBYTES, mbuf_tmp.share[n].u8, KYBER_INDCPA_MSGBYTES);
    }

    t0 = hal_get_time();
    masked_hash_g(&kr, &mbuf);
    t1 = hal_get_time();
    details->hashg = t1 - t0 - baseline;

    
    for (size_t n = 0; n < MASKING_N; n++)
    {
      memcpy(mbuf_tmp.share[n].u8, mbuf.share[n].u8, KYBER_INDCPA_MSGBYTES);
      memcpy(symbuf.share[n].u8, kr.share[n].u8 + KYBER_SYMBYTES, KYBER_SYMBYTES);
    }
    
    #ifdef DETAILBENCHMARK
    fail = indcpa_maskedenc_cmp(ct, &mbuf_tmp, sk->pk, &symbuf, details);    
    #else
    fail = indcpa_maskedenc_cmp(ct, &mbuf_tmp, sk->pk, &symbuf);     
    #endif              /* coins are in kr+KYBER_SYMBYTES */


    t0 = hal_get_time();
    hash_h(hc, ct, KYBER_CIPHERTEXTBYTES);                           /* overwrite coins in kr with H(c)  */
    t1 = hal_get_time();
    details->hashh = t1 - t0 - baseline;
    

    masked_u8_mask_offset(&kr, hc, 32, 32, 64);

    masked_cmov(&kr, &sk->z, fail);       /* Overwrite pre-k with z on re-encryption failure */
    t0 = hal_get_time();
    masked_kdf(ss, &kr); 
    t1 = hal_get_time();
    details->kdf = t1 - t0 - baseline; /* hash concatenation of pre-k and H(c) to k */
    return 0;
}
#else
int crypto_kem_dec_masked(masked_ss *ss, const unsigned char *ct, masked_sk *sk) {
    unsigned char fail;
    masked_u8_64 kr;                                             /* Will contain key, coins */
    masked_u8_64 mbuf;
    masked_u8_msgbytes mbuf_tmp;
    masked_u8_symbytes symbuf;
    uint8_t hc[32];


    indcpa_dec(&mbuf_tmp, ct, &sk->indcpa_sk);


    for (size_t n = 0; n < MASKING_N; n++)
    {
      memcpy(mbuf.share[n].u8, mbuf_tmp.share[n].u8, KYBER_INDCPA_MSGBYTES);
    }
    
    masked_u8_mask(mbuf_tmp.share[0].u8, sk->hpk, KYBER_INDCPA_MSGBYTES);               /* Multitarget countermeasure for coins + contributory KEM; Save hash by storing H(pk) in sk */
    
    for (size_t n = 0; n < MASKING_N; n++)
    {
      memcpy(mbuf.share[n].u8 + KYBER_INDCPA_MSGBYTES, mbuf_tmp.share[n].u8, KYBER_INDCPA_MSGBYTES);
    }


    masked_hash_g(&kr, &mbuf);


    
    for (size_t n = 0; n < MASKING_N; n++)
    {
      memcpy(mbuf_tmp.share[n].u8, mbuf.share[n].u8, KYBER_INDCPA_MSGBYTES);
      memcpy(symbuf.share[n].u8, kr.share[n].u8 + KYBER_SYMBYTES, KYBER_SYMBYTES);
    }
    
    //xil_printf("Dec before cmp.\n\r");

    fail = indcpa_maskedenc_cmp(ct, &mbuf_tmp, sk->pk, &symbuf);                   /* coins are in kr+KYBER_SYMBYTES */



    hash_h(hc, ct, KYBER_CIPHERTEXTBYTES);                           /* overwrite coins in kr with H(c)  */


    masked_u8_mask_offset(&kr, hc, 32, 32, 64);

    masked_cmov(&kr, &sk->z, fail);       /* Overwrite pre-k with z on re-encryption failure */

    masked_kdf(ss, &kr); /* hash concatenation of pre-k and H(c) to k */
    return 0;
}
#endif

