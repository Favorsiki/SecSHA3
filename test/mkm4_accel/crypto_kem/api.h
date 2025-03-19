#ifndef API_H
#define API_H

#include "masked.h"
#include "params.h"

#define ITERATIONS 10

#ifdef DETAILBENCHMARK
struct decaps_measurements { uint64_t indcpadec, reenc, comp, hashh, hashg, kdf, unpackdecomp, decarith, compress, encsample,decompress,encmatacc, encarith;};
#endif

#define CRYPTO_SECRETKEYBYTES  KYBER_SECRETKEYBYTES
#define CRYPTO_PUBLICKEYBYTES  KYBER_PUBLICKEYBYTES
#define CRYPTO_CIPHERTEXTBYTES KYBER_CIPHERTEXTBYTES
#define CRYPTO_BYTES           KYBER_SSBYTES

#define CRYPTO_ALGNAME "Kyber768"

int crypto_kem_keypair(unsigned char *pk, masked_sk *sk);

int crypto_kem_enc(unsigned char *ct, unsigned char *ss, const unsigned char *pk);


#ifdef DETAILBENCHMARK
int crypto_kem_dec_masked(masked_ss *ss, const unsigned char *ct, masked_sk *sk, struct decaps_measurements * x);
#else
int crypto_kem_dec_masked(masked_ss *ss, const unsigned char *ct, masked_sk *sk);
#endif


#endif
