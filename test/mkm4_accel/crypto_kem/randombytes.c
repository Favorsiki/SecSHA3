#include <stdint.h>

#include "randombytes.h"

#ifdef NO_RANDOM
// Use fully deterministic randomness, using an insecure PRNG from a fixed
// seed.  This is only meant for debugging purposes.

static struct {
    uint32_t a, b, c, d;
} xorshift128_state = {
    .a = 0x12345678,
    .b = 0xAAAAAAA1,
    .c = 0xAAAAAAA2,
    .d = 0xAAAAAAA3,
};


uint32_t xorshift128(void)
{
	// Algorithm "xor128" from p. 5 of Marsaglia, "Xorshift RNGs"
    // This version is taken from Wikipedia.
	uint32_t t = xorshift128_state.d;

	uint32_t const s = xorshift128_state.a;
	xorshift128_state.d = xorshift128_state.c;
	xorshift128_state.c = xorshift128_state.b;
	xorshift128_state.b = s;

	t ^= t << 11;
	t ^= t >> 8;
    xorshift128_state.a = t ^ s ^ (s >> 19);
    return xorshift128_state.a;
}

#endif /* NO_RANDOM */

int randombytes(uint8_t *obuf, size_t len)
{
    uint32_t randombytes_pool = 0;
    uint8_t randombytes_pool_size = 0;

    for (size_t idx = 0; idx < len; idx++) {
        if (randombytes_pool_size == 0) {
            randombytes_pool = randomint();
            randombytes_pool_size = sizeof(randombytes_pool);
        }
        obuf[idx] = randombytes_pool & 0xFF;
        randombytes_pool >>= 8;
        randombytes_pool_size--;
    }
    return 0;
}
