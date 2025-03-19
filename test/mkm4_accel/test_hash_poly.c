#include <stdint.h>
#include <stdbool.h>
//#include <stdio.h>
#include <string.h>
#include <sleep.h>

#include "api.h"
#include "pqm4-hal.h"
#include "xparameters.h"
#include "xil_io.h"
#include "dma.h"


unsigned long long hash_cycles;
unsigned long long ntt_cycles, intt_cycles, poly_arith_cycles;

unsigned long long cbd_cycles;
unsigned long long xof_cycles;
unsigned long long enc_cycles;
unsigned long long dec_cycles;
unsigned long long g_cycles;
unsigned long long A2A_10_1_cycles;
unsigned long long A2A_13_10_cycles;
unsigned long long A2A_10_4_cycles;
unsigned long long gen_A_cycles;
unsigned long long mask_comp_cycles;
unsigned long long poly_enc_cycles;
unsigned long long poly_dec_cycles;
unsigned long long rng_cycles;
unsigned long long rng_calls = 0;

bool trigger = false;
uint8_t en_rand = 1;

#define UART0_DEVICE_ID XPAR_UARTLITE_0_DEVICE_ID
#define UART1_DEVICE_ID XPAR_UARTLITE_1_DEVICE_ID
#define UART0_BAUD_RATE 115200
#define UART1_BAUD_RATE 115200

int main(void)
{
  masked_sk ssk;
  masked_ss ss_K;
  unsigned char key_a[CRYPTO_BYTES], key_b[CRYPTO_BYTES];
  unsigned char pk[CRYPTO_PUBLICKEYBYTES];
  unsigned char ct[CRYPTO_CIPHERTEXTBYTES];
  uint64_t t0, t1;
  uint32_t t32, h32;

  dma_init();
  xil_printf("==============1============\n\r");
  // Key-pair generation
  hash_cycles = 0;
  ntt_cycles = 0;
  intt_cycles = 0;
  poly_arith_cycles = 0;
  t0 = hal_get_time();
  crypto_kem_keypair(pk, &ssk);
  t1 = hal_get_time();
  t32 = (t1 - t0) & 0xffffffff;
  h32 = hash_cycles & 0xffffffff;
  xil_printf("keypair cycles: %lu.\n\r", t32);
  xil_printf("keypair hash cycles: %lu.\n\r", h32);
  h32 = (poly_arith_cycles & 0xffffffff);
  xil_printf("keypair poly_arith cycles: %lu.\n\r", h32);
  h32 = (ntt_cycles & 0xffffffff);
  xil_printf("keypair ntt  cycles: %lu.\n\r", h32);
  h32 = (intt_cycles & 0xffffffff);
  xil_printf("keypair intt cycles: %lu.\n\r", h32);

  xil_printf("==============2============\n\r");
  // Encapsulation
  hash_cycles = 0;
  ntt_cycles = 0;
  intt_cycles = 0;
  poly_arith_cycles = 0;
  t0 = hal_get_time();
  crypto_kem_enc(ct, key_a, pk);
  t1 = hal_get_time();
  t32 = (t1 - t0) & 0xffffffff;
  h32 = hash_cycles & 0xffffffff;
  xil_printf("encaps cycles: %lu.\n\r", t32);
  xil_printf("encaps hash cycles: %lu.\n\r", h32);
  h32 = (poly_arith_cycles & 0xffffffff);
  xil_printf("encaps poly_arith cycles: %lu.\n\r", h32);
  h32 = (ntt_cycles & 0xffffffff);
  xil_printf("encaps ntt  cycles: %lu.\n\r", h32);
  h32 = (intt_cycles & 0xffffffff);
  xil_printf("encaps intt cycles: %lu.\n\r", h32);

  print("==============3============\n\r");
  // Decapsulation
  hash_cycles = 0;
  ntt_cycles = 0;
  intt_cycles = 0;
  poly_arith_cycles = 0;
  cbd_cycles = xof_cycles = enc_cycles = dec_cycles = g_cycles = 0;
  t0 = hal_get_time();
  crypto_kem_dec_masked(&ss_K, ct, &ssk);
  t1 = hal_get_time();
  t32 = (t1 - t0) & 0xffffffff;
  h32 = hash_cycles & 0xffffffff;
  xil_printf("decaps cycles: %lu.\n\r", t32);
  xil_printf("decaps hash cycles: %lu.\n\r", h32);
  h32 = (poly_arith_cycles & 0xffffffff);
  xil_printf("decaps poly_arith cycles: %lu.\n\r", h32);
  h32 = (ntt_cycles & 0xffffffff);
  xil_printf("decaps ntt  cycles: %lu.\n\r", h32);
  h32 = (intt_cycles & 0xffffffff);
  xil_printf("decaps intt cycles: %lu.\n\r", h32);
//  xil_printf("decaps cbd cycles: %llu.\n\r", cbd_cycles);
//  xil_printf("decaps xof cycles: %llu.\n\r", xof_cycles);
//  xil_printf("decaps gen_secret cycles: %llu.\n\r", cbd_cycles + xof_cycles);
//  xil_printf("decaps enc cycles: %llu.\n\r", enc_cycles-mask_comp_cycles);
//  xil_printf("decaps dec cycles: %llu.\n\r", dec_cycles);
//  xil_printf("decaps g cycles: %llu.\n\r", g_cycles);
//  xil_printf("decaps A2A_10_1 cycles: %llu.\n\r", A2A_10_1_cycles);
//  xil_printf("decaps A2A_13_10 cycles: %llu.\n\r", A2A_13_10_cycles);
//  xil_printf("decaps A2A_10_4 cycles: %llu.\n\r", A2A_10_4_cycles);
//  xil_printf("decaps gen_A cycles: %llu.\n\r", gen_A_cycles);
//  xil_printf("decaps mask_comp_A cycles: %llu.\n\r", mask_comp_cycles);
//  xil_printf("decaps poly_enc cycles: %llu.\n\r", poly_enc_cycles);
//  xil_printf("decaps poly_dec cycles: %llu.\n\r", poly_dec_cycles);
//  xil_printf("decaps rng cycles: %llu.\n\r", rng_cycles);
//  xil_printf("decaps rng calls: %llu.\n\r", rng_calls);


  int i;
  for (i = 0; i < 32; i++) {
	  key_b[i] = ss_K.share[0].u8[i] ^ ss_K.share[1].u8[i];
  }

  if (memcmp(key_a, key_b, CRYPTO_BYTES)) {
	  xil_printf("ERROR KEYS\n\r");
  }
  else {
	  xil_printf("OK KEYS\n\r");
  }

  xil_printf("#");
  dma_cleanup();
  return 0;
}
