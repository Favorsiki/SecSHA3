#include "masked-poly.h"
#include "masked.h"
#include "poly.h"
#include "masked-cbd.h"
#include "fips202-masked.h"
#include "randombytes.h"
#include "a2b.h"

void masked_poly_tobytes(unsigned char *r, masked_poly *a) {
    poly a2;

    masked_poly_unmask(&a2, a);
    poly_tobytes(r, &a2);
}

extern int16_t asm_barrett_reduce32(int32_t a);
extern int16_t sub_mod(int16_t a, int16_t b);


void masked_poly_frommsg(masked_poly *r, const masked_u8_msgbytes *msg) {
#if MASKING_N == 2
	size_t i, j;
	//subshares
	int16_t m11, m12, m21, m22;
	//Decode each share and add to current coefficient of poly r
	uint16_t mask;

	for (i = 0; i < KYBER_SYMBYTES; i++) {
		for (j = 0; j < 8; j++) {
			mask = -((msg->share[0].u8[i] >> j) & 1);
			r->polys[0].coeffs[8 * i + j] += (mask & ((KYBER_Q + 1) / 2));
		}
	}
	for (i = 0; i < KYBER_SYMBYTES; i++) {
		for (j = 0; j < 8; j++) {
			mask = -((msg->share[1].u8[i] >> j) & 1);
			r->polys[1].coeffs[8 * i + j] += (mask & ((KYBER_Q + 1) / 2));
		}
	}
	//If all shares of msg[i] == 1, the recombined polynomial is not correct (q+1 instead of q) 

	for (i = 0; i < KYBER_SYMBYTES; i++) {
		for (j = 0; j < 8; j++) {


			//get random sub-share m11 and m21
			//Caution: NOT constant-time, for t-test sample in advance
			
			do {
				randombytes((uint8_t *)& m11,2) ;
				m11 &= 0xFFF;
			} while ((uint16_t)m11 >= KYBER_Q);

			m12 = asm_barrett_reduce32(2 * KYBER_Q - ((msg->share[0].u8[i] >> j) & 1) - m11);

			do {
				randombytes((uint8_t *)&m21, 2);
				m21 &= 0xFFF;
			} while ((uint16_t)m21 >= KYBER_Q);

			m22 = asm_barrett_reduce32(KYBER_Q + ((msg->share[1].u8[i] >> j) & 1) - m21);

			r->polys[0].coeffs[i * 8 + j] = asm_barrett_reduce32(r->polys[0].coeffs[i * 8 + j] + m11 * m21);

			r->polys[0].coeffs[i * 8 + j] = asm_barrett_reduce32(r->polys[0].coeffs[i * 8 + j] + m11 * m22);

			r->polys[0].coeffs[i * 8 + j] = asm_barrett_reduce32(r->polys[0].coeffs[i * 8 + j] + m12 * m21);

			r->polys[0].coeffs[i * 8 + j] = asm_barrett_reduce32(r->polys[0].coeffs[i * 8 + j] + m12 * m22);

		}
	}
#else
#error "unsupported masking order"
#endif

}


//Masked Poly to Message similar to [OSPG18], Algorithm 2, MDecode
void masked_poly_tomsg(masked_u8_msgbytes* msg, masked_poly* a) {
#if MASKING_N == 2 
	size_t i, j;
	int16_t a1, a2;
	uint16_t c[2];

	int16_t random;
	int16_t k11, k12, k21, k22;
	uint16_t y1, y2, z0, z[2];
	

	A2B_reset();

	for (j = 0; j < MASKING_N; j++){
		for (i = 0; i < KYBER_SYMBYTES; i++) {

			msg->share[j].u8[i] = 0;
		
		}	
	}
	
	for (i = 0; i < KYBER_SYMBYTES; i++) {
		for (j = 0; j < 8; j++) {

			a1 = (a->polys[0].coeffs[8 * i + j] - KYBER_Q / 4 + KYBER_Q) % KYBER_Q;
			a2 = a->polys[1].coeffs[8 * i + j];

			//masked TransformPower2 to shares mod 2^16 then A2B from [OSPG18]
			uint32_t tmp = randomint();
			y1 = tmp & 0xFFFF;
			random = (tmp >> 16) & 0xFFFF;

			y2 = (a1 - y1);
			y2 = (y2 + a2);
			z0 = (y1 - KYBER_Q);
			z[0] = A2B_convert(z0, y2);
			z[1] = y2; 

			tmp = randomint();
			k11 = tmp & 0xFFFF;
			k21 = (tmp >> 16) & 0xFFFF;

			k12 = (((uint16_t)z[0] >> 15) ^ 1) - k11;
			k22 = ((uint16_t)z[1] >> 15) - k21;

			// random has been initialized earlier in this function.
			c[0] = (int64_t)(((random + y1) - (((uint16_t)z[0] >> 15) ^ 1) * KYBER_Q) - ((uint16_t)z[1] >> 15) * KYBER_Q + (int64_t)2 * k11 * k21 * KYBER_Q + (int64_t)2 * k11 * k22 * KYBER_Q + (int64_t)2 * k12 * k21 * KYBER_Q + (int64_t)2 * k12 * k22 * KYBER_Q);
			c[1] = (y2 - random);
			// End Masked TransformPower2

			c[0] = (c[0] - KYBER_Q / 2);

			c[0] = A2B_convert(c[0], c[1]);

			msg->share[0].u8[i] += ((c[0] >> 15) & 1) << j;
			msg->share[1].u8[i] += ((c[1] >> 15) & 1) << j;
		}
	}
#else
#error "unsupported masking order"
#endif
}

void masked_poly_noise(masked_poly *r, const masked_u8_symbytes *seed, unsigned char nonce, int add) {
    masked_u8_sampling buf;
    
#if MASKING_N > 2
#error "unsupported MASKING_N"
#endif
    masked_prf(&buf, seed, nonce);
    masked_cbd(r, &buf, add);
}

void masked_poly_ntt(masked_poly *r) {
    size_t i;

    for(i = 0; i < MASKING_N; i++){
        poly_ntt(&r->polys[i]);
    }
}

void masked_poly_invntt(masked_poly *r) {
    size_t i;

    for(i = 0; i < MASKING_N; i++){
        poly_invntt(&r->polys[i]);
    }
}

void masked_poly_basemul(masked_poly *r, const poly *a, const masked_poly *b) {
    size_t i;

    for(i = 0; i < MASKING_N; i++){
        poly_basemul(&r->polys[i], a, &b->polys[i]);
    }
}

void masked_poly_basemul_acc(masked_poly *r, const poly *a, const masked_poly *b) {
    size_t i;

    for(i = 0; i < MASKING_N; i++){
        poly_basemul_acc(&r->polys[i], a, &b->polys[i]);
    }
}

void masked_poly_add2(masked_poly *r, const masked_poly *a) {
    size_t i;

    for(i = 0; i < MASKING_N; i++){
        poly_add(&r->polys[i],&r->polys[i], &a->polys[i]);
    }
}

void masked_poly_sub(masked_poly *r, const poly *a, const masked_poly *b) {
    size_t i,j;
    poly_sub(&r->polys[0], a, &b->polys[0]);

    for(i = 1; i < MASKING_N;i++){
        for(j = 0; j < KYBER_N; j++)
        r->polys[i].coeffs[j] = -b->polys[i].coeffs[j];
    }
}

void masked_poly_reduce(masked_poly *r) {
    size_t i;

    for (i = 0; i < MASKING_N; i++) {
        poly_reduce(&r->polys[i]);
    }
}


//Not needed for decompressed comparison
void masked_poly_compress(masked_poly *r, const masked_poly *a){
    unsigned char tmp[KYBER_POLYCOMPRESSEDBYTES];
    poly p;
    masked_poly_unmask(&p, a);
    poly_compress(tmp, &p);
    poly_decompress(&p, tmp);
    masked_poly_mask(r, &p);
}

