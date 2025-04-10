#ifndef PQCLEAN_MLKEM512_CLEAN_INDCPA_H
#define PQCLEAN_MLKEM512_CLEAN_INDCPA_H
#ifdef __cplusplus
extern "C" {
#endif
#include "params.h"
#include "polyvec.h"
#include <stdint.h>
void PQCLEAN_MLKEM512_CLEAN_gen_matrix(polyvec *a, const uint8_t seed[KYBER_SYMBYTES], int transposed);

void PQCLEAN_MLKEM512_CLEAN_indcpa_keypair_derand(uint8_t pk[KYBER_INDCPA_PUBLICKEYBYTES],
        uint8_t sk[KYBER_INDCPA_SECRETKEYBYTES],
        const uint8_t coins[KYBER_SYMBYTES]);

void PQCLEAN_MLKEM512_CLEAN_indcpa_enc(uint8_t c[KYBER_INDCPA_BYTES],
                                       const uint8_t m[KYBER_INDCPA_MSGBYTES],
                                       const uint8_t pk[KYBER_INDCPA_PUBLICKEYBYTES],
                                       const uint8_t coins[KYBER_SYMBYTES]);

void PQCLEAN_MLKEM512_CLEAN_indcpa_dec(uint8_t m[KYBER_INDCPA_MSGBYTES],
                                       const uint8_t c[KYBER_INDCPA_BYTES],
                                       const uint8_t sk[KYBER_INDCPA_SECRETKEYBYTES]);
#ifdef __cplusplus
}
#endif
#endif
