#include "masked-polyvec.h"
#include "masked-poly.h"
#include "polyvec.h"


void masked_polyvec_ntt(masked_polyvec *r) {
    size_t i;
    for(i = 0; i < KYBER_K; i++) {
        masked_poly_ntt(&r->vec[i]);
    }
}

//Not needed due to decompressed comparison
void masked_polyvec_compress(masked_polyvec *r, const masked_polyvec *a){
    unsigned char tmp[KYBER_POLYVECCOMPRESSEDBYTES];
    polyvec p;
    masked_polyvec_unmask(&p, a);
    polyvec_compress(tmp, &p);
    polyvec_decompress(&p, tmp);
    masked_polyvec_mask(r, &p);
}