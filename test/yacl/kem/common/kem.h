#ifndef PQCLEAN_MLKEM512_CLEAN_KEM_H
#define PQCLEAN_MLKEM512_CLEAN_KEM_H
#ifdef __cplusplus
extern "C" {
#endif

#include "params.h"
#include <stdint.h>
#define PQCLEAN_MLKEM512_CLEAN_CRYPTO_SECRETKEYBYTES  KYBER_SECRETKEYBYTES
#define PQCLEAN_MLKEM512_CLEAN_CRYPTO_PUBLICKEYBYTES  KYBER_PUBLICKEYBYTES
#define PQCLEAN_MLKEM512_CLEAN_CRYPTO_CIPHERTEXTBYTES KYBER_CIPHERTEXTBYTES
#define PQCLEAN_MLKEM512_CLEAN_CRYPTO_BYTES           KYBER_SSBYTES

#define PQCLEAN_MLKEM512_CLEAN_CRYPTO_ALGNAME "ML-KEM-512"

int PQCLEAN_MLKEM512_CLEAN_crypto_kem_keypair_derand(uint8_t *pk, uint8_t *sk, const uint8_t *coins);

int PQCLEAN_MLKEM512_CLEAN_crypto_kem_keypair(uint8_t *pk, uint8_t *sk);

int PQCLEAN_MLKEM512_CLEAN_crypto_kem_enc_derand(uint8_t *ct, uint8_t *ss, const uint8_t *pk, const uint8_t *coins);

int PQCLEAN_MLKEM512_CLEAN_crypto_kem_enc(uint8_t *ct, uint8_t *ss, const uint8_t *pk);

int PQCLEAN_MLKEM512_CLEAN_crypto_kem_dec(uint8_t *ss, const uint8_t *ct, const uint8_t *sk);
#ifdef __cplusplus
}
#endif
#endif
