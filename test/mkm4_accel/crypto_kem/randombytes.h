#ifndef RANDOMBYTES_H
#define RANDOMBYTES_H

#include <stdint.h>

#ifdef _WIN32
#include <CRTDEFS.H>
#else
#include <unistd.h>
#endif

#ifdef CW
#define NO_RANDOM
#endif

#ifndef NO_RANDOM
//#include <libopencm3/stm32/rng.h>
#endif

// Enable/disable randomness for masks ON/OFF
extern uint8_t en_rand;

#ifdef NO_RANDOM

uint32_t xorshift128(void);

#else

// Get 32 bits of randomness from the STM32F4 true rng.  This function will
// block on rng errors, and wait for the rng to recover.
// This function assumes that no other thread or interrupt will be interacting
// with the rng peripheral!
static inline uint32_t trng_get_random_u32(void) {
//    for (;;) {
//        uint32_t rng_status = RNG_SR; // Ensure only *one* volatile read.
//        uint32_t errors = rng_status & (RNG_SR_CECS | RNG_SR_SECS);
//        uint32_t data_rdy = rng_status & RNG_SR_DRDY;
//        if (errors == 0 && data_rdy != 0) {
//            return RNG_DR;
//        }
//    }
	return 348589;
}

#endif

// Get one 32-bit number.  This function is optimized to be as efficient
// as possible.  If you can, prefer this function over `randombytes`.
// This function assumes that no other thread or interrupt will be interacting
// with the rng peripheral!
static inline uint32_t randomint(void) {
    uint32_t rand = 0;
    #ifdef NO_RANDOM
    rand = xorshift128();
    #else
    rand = trng_get_random_u32();
    #endif
    rand &= -(int32_t)en_rand;
    return rand;
}

// Sample `xlen` randombytes into `buf`.
// This function assumes that no other thread or interrupt will be interacting
// with the rng peripheral!
int randombytes(uint8_t *buf, size_t xlen);

#endif
