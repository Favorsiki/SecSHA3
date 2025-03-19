#ifndef INDCPA_H
#define INDCPA_H

#include "masked.h"
#include "api.h"
#include "pqm4-hal.h"

void indcpa_keypair(unsigned char *pk,
                    masked_polyvec *sk);

void indcpa_enc(unsigned char *c,
                const unsigned char *m,
                const unsigned char *pk,
                const unsigned char *coins);

unsigned char indcpa_enc_cmp(const unsigned char *ct,
                             const unsigned char *m,
                             const unsigned char *pk,
                             const unsigned char *coins);

#ifdef DETAILBENCHMARK
void indcpa_dec(masked_u8_msgbytes *m,
                const unsigned char *c,
                const masked_polyvec *sk, struct decaps_measurements *x);


unsigned char indcpa_maskedenc_cmp(const unsigned char *c,
                                   const masked_u8_msgbytes *m,
                                   const unsigned char *pk,
                                   const masked_u8_symbytes *coins, struct decaps_measurements *x);
#else

void indcpa_dec(masked_u8_msgbytes *m,
                const unsigned char *c,
                const masked_polyvec *sk);


unsigned char indcpa_maskedenc_cmp(const unsigned char *c,
                                   const masked_u8_msgbytes *m,
                                   const unsigned char *pk,
                                   const masked_u8_symbytes *coins);
#endif
#endif
