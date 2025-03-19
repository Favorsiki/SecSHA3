#include "randombytes.h"
#include "a2a.h"
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>


#define k 6
#define pow2(k) (1 << (k))
#define mod2(k) (pow2(k)-1)
#define mod2_16(k) ((mod2(k) << 16) | (mod2(k)))
#define SABER_N 256
#define SABER_Q 8192


struct A2A_C_A_s {
    uint32_t n;
    uint32_t rrr;
    uint32_t GAMMA;
    uint16_t C_A[pow2(k)];
};

static struct A2A_C_A_s args = {.n=0};

// generates the Table C_A
static void gen_C_A(int n)
{
    int i;
    //struct A2A_C_A_s args;
    
    args.n = n;

    uint32_t rand = randomint();
    uint32_t r = rand & mod2(k);
    uint32_t gamma = rand >> k;

    // gen_C_A
    for(uint32_t A=0;A<pow2(k);A++){
        args.C_A[A] = (((A+r) >> k) + gamma);
    }

    uint32_t rrr = 0, GAMMA=0;

    for(i=0;i<n;i++){
        rrr = (rrr | pow2(i*k)*r);
        GAMMA = (GAMMA + pow2((i+1)*k)*gamma);
    }

    args.rrr = rrr;
    args.GAMMA = GAMMA;
}


// does the actual A2A conversion using the table C_A
static void A2A_C_A(int16_t *Aptr, int16_t *Rptr, uint32_t mod)
{

    size_t i;
    uint32_t A, R;
    uint32_t A_l, R_l;

    A = *Aptr;
    R = *Rptr;

    A = (A - args.rrr) & mod;
    A = (A - args.GAMMA) & mod;
    R = R & mod;

    for(i = 0; i < args.n; i++)
    {

        R_l = R & mod2(k);

        A = (A + R_l) & (mod >> (i*k));

        A_l = A & mod2(k);

        A >>= k;
        R >>= k;

        A = (A + args.C_A[A_l]) & (mod >> ((i+1)*k));

    }

    *Aptr = A;
    *Rptr = R;
}


// 2^13 -> 2^1
void A2A_C_A_13_1(int16_t *a, int16_t *b){
    const int n = 2;
    if (args.n != n)
    {
      gen_C_A(n);
    }
    A2A_C_A(a, b, (1<<13)-1);
}

void A2A_reset(void)
{
    args.n = 0;
}
