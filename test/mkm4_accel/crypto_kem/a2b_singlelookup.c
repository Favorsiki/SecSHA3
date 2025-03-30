#include "a2b.h"
#include "def.h"
#include "randombytes.h"
#include <stdint.h>


typedef struct
{
#if k == 8
    uint16_t *T; 
#elif k == 4
    uint8_t *T; 
#endif
    uint8_t rho;
    uint16_t rrr;
} A2Bctx;

#if k == 8
   static uint16_t T[a2bn * pow2(k+1)]; 
#elif k == 4
   static uint8_t T[a2bn * pow2(k+1)]; 
#endif

static A2Bctx ctx;

static void A2B_init(void)
{

	size_t i, A;
	uint8_t r[a2bn], rho;
	uint32_t rrr = 0, buff;

	randombytes(&rho, 1);
	rho  &= 0x01;
	randombytes((uint8_t*)&buff, 2);
	//buff = rng_get_random_blocking() & mod2nk;

	/* (r_n || ... || r_i || ... || r_0) */
	for (i = 0; i < a2bn; i++)
	{
		r[i] = ((buff >> i*k) & mod2(k));
		rrr |= (r[i] << (i*k)); 
	}

	ctx.rrr = rrr;
	ctx.rho = rho;

	/* Tables */
	for (i = 0; i < a2bn; i++)
	{
		for (A = 0; A < pow2(k); A++)
		{
			ctx.T[index(i, rho, A)] = (A + r[i]) ^ ((rho << k) | r[i]);
			ctx.T[index(i, (rho ^ 1) , A)] = (A + r[i] + 1) ^ ((rho << k) | r[i]);
		}
	}
}

//extern uint32_t A2B_convert_asm(uint32_t A, uint32_t R, A2Bctx ctx);
static uint32_t A2B_convert_sw(uint32_t A, uint32_t R)
{

	size_t i;
	uint32_t A_l, R_l, betaBi, beta = ctx.rho, Bi, B = 0;
	//uint32_t mod2nik;

	A = (A - ctx.rrr) & mod2nk;       
	// mod2nik = mod2nk; // mod2((a2bn - i) * k)

	for (i = 0; i < a2bn; i++)
	{
		R_l = R & mod2k;
		A = (A + R_l) & mod2((a2bn - i) * k);
		// A = (A + R_l) & mod2nik;
		A_l = A & mod2k;

		betaBi = ctx.T[index(i, beta, A_l)]; // use i-th Table
		Bi = betaBi & mod2k;
        beta = betaBi >> k;

		Bi = Bi ^ R_l;
		B |= (Bi << i * k); 

		A >>= k;
		R >>= k;
		// mod2nik >>= k;
	}

	return B ^ ctx.rrr;
}

uint32_t A2B_convert(uint32_t A, uint32_t R)
{
	uint32_t B;

	/* 1. Generate table */
	//t0 = hal_get_time();
	if (!ctx.T){
		ctx.T = T;
		A2B_init();
	}
	//t1 = hal_get_time();
	//printcycles("precomp cycles:", t1-t0);

	/* 2. Convert */
	//t0 = hal_get_time();
	B = A2B_convert_sw(A, R);
	//t1 = hal_get_time();
	//printcycles("conv cycles:", t1-t0);

	return B;

}

void A2B_reset(void){
	ctx.T = NULL;
}


			
