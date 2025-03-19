#ifndef KECCAKF1600_H
#define KECCAKF1600_H

#include <stdint.h>

#define NROUNDS 24
#define ROL(a, offset) (((a) << (offset)) ^ ((a) >> (64 - (offset))))

void KeccakF1600_StateExtractBytes(uint64_t *state, unsigned char *data, unsigned int offset, unsigned int length);
void KeccakF1600_StateXORBytes(uint64_t *state, const unsigned char *data, unsigned int offset, unsigned int length);
void KeccakF1600_StatePermute(uint64_t * state);

#endif
