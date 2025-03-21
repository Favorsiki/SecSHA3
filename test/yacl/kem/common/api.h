#ifndef PQCLEAN_MLKEM512_CLEAN_API_H
#define PQCLEAN_MLKEM512_CLEAN_API_H

#include <stdint.h>
#include "params.h"

#define PQCLEAN_MLKEM512_CLEAN_CRYPTO_SECRETKEYBYTES  1632
#define PQCLEAN_MLKEM512_CLEAN_CRYPTO_PUBLICKEYBYTES  800
#define PQCLEAN_MLKEM512_CLEAN_CRYPTO_CIPHERTEXTBYTES 768
#define PQCLEAN_MLKEM512_CLEAN_CRYPTO_BYTES           32
#define PQCLEAN_MLKEM512_CLEAN_CRYPTO_ALGNAME "ML-KEM-512"

int PQCLEAN_MLKEM512_CLEAN_crypto_kem_keypair(uint8_t *pk, uint8_t *sk);

int PQCLEAN_MLKEM512_CLEAN_crypto_kem_enc(uint8_t *ct, uint8_t *ss, const uint8_t *pk);

int PQCLEAN_MLKEM512_CLEAN_crypto_kem_dec(uint8_t *ss, const uint8_t *ct, const uint8_t *sk);


#define CRYPTO_SECRETKEYBYTES  KYBER_SECRETKEYBYTES
#define CRYPTO_PUBLICKEYBYTES  KYBER_PUBLICKEYBYTES
#define CRYPTO_CIPHERTEXTBYTES KYBER_CIPHERTEXTBYTES
#define CRYPTO_BYTES           KYBER_SSBYTES

#if   (KYBER_K == 2)
#ifdef KYBER_90S
#define CRYPTO_ALGNAME "Kyber512-90s"
#else
#define CRYPTO_ALGNAME "Kyber512"
#endif
#elif (KYBER_K == 3)
#ifdef KYBER_90S
#define CRYPTO_ALGNAME "Kyber768-90s"
#else
#define CRYPTO_ALGNAME "Kyber768"
#endif
#elif (KYBER_K == 4)
#ifdef KYBER_90S
#define CRYPTO_ALGNAME "Kyber1024-90s"
#else
#define CRYPTO_ALGNAME "Kyber1024"
#endif
#endif


#define crypto_kem_keypair PQCLEAN_MLKEM512_CLEAN_crypto_kem_keypair
#define crypto_kem_enc PQCLEAN_MLKEM512_CLEAN_crypto_kem_enc
#define crypto_kem_dec PQCLEAN_MLKEM512_CLEAN_crypto_kem_dec


#endif
