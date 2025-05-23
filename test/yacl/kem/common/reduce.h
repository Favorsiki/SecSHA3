#ifndef PQCLEAN_MLKEM512_CLEAN_REDUCE_H
#define PQCLEAN_MLKEM512_CLEAN_REDUCE_H
#ifdef __cplusplus
extern "C" {
#endif
#include "params.h"
#include <stdint.h>

#define MONT (-1044) // 2^16 mod q
#define QINV (-3327) // q^-1 mod 2^16

int16_t PQCLEAN_MLKEM512_CLEAN_montgomery_reduce(int32_t a);

int16_t PQCLEAN_MLKEM512_CLEAN_barrett_reduce(int16_t a);
#ifdef __cplusplus
}
#endif
#endif
