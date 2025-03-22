# This Makefile can be used with GNU Make or BSD Make


CC=/usr/bin/g++
CFLAGS += -O0 -march=native -fomit-frame-pointer
LDFLAGS=-lcrypto

SOURCES= mlkem_enc_test.cc key_utils.cc mlkem_enc.cc common/cbd.c common/fips202.c common/indcpa.c common/kem.c common/ntt.c common/poly.c common/polyvec.c common/reduce.c common/randombytes.c common/verify.c common/symmetric-shake.c   
HEADERS= mlkem_enc.h key_utils.h kem_interface.h common/api.h common/cbd.h common/fips202.h common/indcpa.h common/ntt.h common/params.h common/poly.h common/polyvec.h common/reduce.h common/randombytes.h common/verify.h common/symmetric.h    

PQCgenKAT_kem: $(HEADERS) $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $(SOURCES) $(LDFLAGS)

.PHONY: clean

clean:
	-rm PQCgenKAT_kem

