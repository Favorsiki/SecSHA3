#include "masked.h"
#include "params.h"
#include "randombytes.h"
#include "transformpower2.h"
#include "a2b.h"

// transformpower2 transforms a masked coefficient modulo q, to a masked
// coefficient modulo 2^15.  The function implements Algorithm 1 from
// [OSPG18].
//
// It is *required* that the input shares are reduced into the range [0, q),
// otherwise, this function will produce incorrect results.
//
masked_coeff_pow2 transformpower2(masked_coeff_q x)
{
#if MASKING_N != 2
#error "This function only supports a masking order of 2."
#endif /* MASKING_N != 2 */

	masked_coeff_pow2 r = {};
	int16_t random = 0;
	int16_t k11 = 0, k12 = 0, k21 = 0, k22 = 0;
	int16_t y1 = 0, y2 = 0, z0 = 0, z[2] = {};
	uint32_t tmp;

	tmp = randomint();
	y1 = tmp & 0xFFFF;
	random = (tmp >> 16) & 0xFFFF;

	y2 = (x.i16[0] - y1);
	y2 = (y2 + x.i16[1]);
	z0 = (y1 - KYBER_Q);
	//masked_A2B_Transform(z, z0, y2);
	z[0] = A2B_convert(z0, y2);
	z[1] = y2;

	tmp = randomint();
	k11 = tmp & 0xFFFF;
	k21 = (tmp >> 16) & 0xFFFF;

	k12 = (((uint16_t)z[0] >> 15) ^ 1) - k11;
	k22 = ((uint16_t)z[1] >> 15) - k21;

	// random has already been set to a random value earlier.
	r.i16[0] = (random + y1);
	r.i16[0] -= (((uint16_t)z[0] >> 15) ^ 1) * KYBER_Q;
	r.i16[0] -= ((uint16_t)z[1] >> 15) * KYBER_Q;
	r.i16[0] += 2 * k11 * k21 * KYBER_Q;
	r.i16[0] += 2 * k11 * k22 * KYBER_Q;
	r.i16[0] += 2 * k12 * k21 * KYBER_Q;
	r.i16[0] += 2 * k12 * k22 * KYBER_Q;

	r.i16[1] = (y2 - random);

	return r;
}
