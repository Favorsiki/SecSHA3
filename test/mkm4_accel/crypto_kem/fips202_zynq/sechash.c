#include "sechash.h"
#include "dma.h"
// args[18:15]: absorb(1bit)||padding(1bit)||squeeze(1bit)||init(1bit)
// args[14:0] : mlen(11bit)||mask(1bit)||hash_mode(3bit)
extern int hash_done;

int mask_inc, unmk_inc;
int sha3_counter = 0;
uint8_t unmk_buffer[200], mask_buffer_1[200], mask_buffer_2[200];

void unmk_keccak_init(int h_mode) {
	sha3_counter += 1;
	h_mode = h_mode ^ 0x8000;
	Xil_Out32(CMD_BASEADDR+SLV_REG0, h_mode);
}

void unmk_keccak_absorb(const uint8_t* in, int inlen,int h_mode) {
	// mlen
	int timeout = TIMEOUT;
	hash_done = 0;
	h_mode = h_mode ^ (inlen << 4) ^ 0x40000;
	Xil_Out32(CMD_BASEADDR+SLV_REG0, h_mode);
	dma_write_1(in, inlen);
	h_mode = h_mode & 0xf;
	Xil_Out32(CMD_BASEADDR+SLV_REG0, h_mode);
	while (!hash_done) {
		timeout -= 1;
		if (timeout == 0) {
			xil_printf("%d, %05x, unmk_keccak_absorb's hash_done return error.\n\r", sha3_counter, h_mode);
			break;
		}
	}
}

void unmk_keccak_padding(int h_mode) {
	int timeout = TIMEOUT;
	hash_done = 0;
	h_mode = h_mode ^ 0x20000;
	Xil_Out32(CMD_BASEADDR+SLV_REG0, h_mode);
	while (!hash_done) {
		timeout -= 1;
		if (timeout == 0) {
			xil_printf("%d, %05x, unmk_keccak_padding's hash_done return error.\n\r", sha3_counter, h_mode);
			break;
		}
	}
}

void unmk_keccak_squeeze(uint8_t* dout, int outlen, int h_mode) {
	int timeout = TIMEOUT;
	hash_done = 0;
	h_mode = h_mode ^ 0x10000;
	Xil_Out32(CMD_BASEADDR+SLV_REG0, h_mode);
	dma_read_1(dout, outlen);
	h_mode = h_mode & 0xf;
	Xil_Out32(CMD_BASEADDR+SLV_REG0, h_mode);
	while (!hash_done) {
		timeout -= 1;
		if (timeout == 0) {
			xil_printf("%d, %05x, unmk_keccak_squeeze's hash_done return error.\n\r", sha3_counter, h_mode);
			break;
		}
	}
}

void mask_keccak_init(int h_mode) {
	sha3_counter += 1;
	h_mode = h_mode ^ 0x8000;
	Xil_Out32(CMD_BASEADDR+SLV_REG0, h_mode);
}

void mask_keccak_absorb(const uint8_t* in0, const uint8_t* in1, int inlen, int h_mode) {
	// mlen <= 512
	int timeout = TIMEOUT;
	hash_done = 0;
	h_mode = h_mode ^ (inlen << 4) ^ 0x40000;
	Xil_Out32(CMD_BASEADDR+SLV_REG0, h_mode);
	dma_write_2(in0, in1, inlen);
	h_mode = h_mode & 0xf;
	Xil_Out32(CMD_BASEADDR+SLV_REG0, h_mode);
	while (!hash_done) {
		timeout -= 1;
		if (timeout == 0) {
			xil_printf("%d, %05x, mask_keccak_absorb's hash_done return error.\n\r", sha3_counter, h_mode);
			break;
		}
	}
}

void mask_keccak_padding(int h_mode) {
	int timeout = TIMEOUT;
	hash_done = 0;
	h_mode = h_mode ^ 0x20000;
	Xil_Out32(CMD_BASEADDR+SLV_REG0, h_mode);
	while (!hash_done) {
		timeout -= 1;
		if (timeout == 0) {
			xil_printf("%d, %05x, mask_keccak_padding's hash_done return error.\n\r", sha3_counter, h_mode);
			break;
		}
	}
}

void mask_keccak_squeeze(uint8_t* dout0, uint8_t* dout1, int outlen, int h_mode) {
	int timeout = TIMEOUT;
	hash_done = 0;
	h_mode = h_mode ^ 0x10000;
	Xil_Out32(CMD_BASEADDR+SLV_REG0, h_mode);
	dma_read_2(dout0, dout1, outlen);
	h_mode = h_mode & 0xf;
	Xil_Out32(CMD_BASEADDR+SLV_REG0, h_mode);
	while (!hash_done) {
		timeout -= 1;
		if (timeout == 0) {
			xil_printf("%d, %05x, mask_keccak_squeeze's hash_done return error.\n\r", sha3_counter, h_mode);
			break;
		}
	}
}

// external function
void unmk_sha3(uint8_t *output, size_t outlen, const uint8_t *input, size_t inlen, int h_mode, int rate) {
	uint8_t *o;
	unmk_keccak_init(h_mode);
	// SHA3 absorb
	while (inlen > MAX_ABSORB_LEN) {
		unmk_keccak_absorb(input, MAX_ABSORB_LEN, h_mode);
		inlen -= MAX_ABSORB_LEN;
		input += MAX_ABSORB_LEN;
	}
	if (inlen > 0) {
		unmk_keccak_absorb(input, inlen, h_mode);
	}
	// SHA3 padding
	unmk_keccak_padding(h_mode);
	// SHA3 squeeze
	o = output;
	while (outlen > rate) {
		unmk_keccak_squeeze(o, rate, h_mode);
		o += rate;
		outlen -= rate;
	}
	unmk_keccak_squeeze(o, outlen, h_mode);
}

void mask_sha3(uint8_t *output1, uint8_t *output2, size_t outlen, const uint8_t *input1,
		const uint8_t *input2, size_t inlen, int h_mode, int rate) {
	uint8_t *o1, *o2;
	mask_keccak_init(h_mode);
	// SHA3 absorb
	while (inlen > MAX_ABSORB_LEN) {
		mask_keccak_absorb(input1, input2, MAX_ABSORB_LEN, h_mode);
		inlen -= MAX_ABSORB_LEN;
		input1 += MAX_ABSORB_LEN;
		input2 += MAX_ABSORB_LEN;
	}
	if (inlen > 0) {
		mask_keccak_absorb(input1, input2, inlen, h_mode);
	}
	// SHA3 padding
	mask_keccak_padding(h_mode);
	// SHA3 squeeze
	o1 = output1;
	o2 = output2;
	while (outlen > rate)
	{
		mask_keccak_squeeze(o1, o2, rate, h_mode);
		o1 += rate;
		o2 += rate;
		outlen -= rate;
	}
	mask_keccak_squeeze(o1, o2, outlen, h_mode);

}

void unmk_sha3_inc_init(int h_mode) {
	unmk_inc = 0;
	unmk_keccak_init(h_mode);
}

void unmk_sha3_inc_absorb(const uint8_t* input, size_t inlen, int h_mode) {
	while (inlen > MAX_ABSORB_LEN) {
		unmk_keccak_absorb(input, MAX_ABSORB_LEN, h_mode);
		inlen -= MAX_ABSORB_LEN;
		input += MAX_ABSORB_LEN;
	}
	if (inlen > 0) {
		unmk_keccak_absorb(input, inlen, h_mode);
	}
}

void unmk_sha3_inc_padding(int h_mode) {
	unmk_keccak_padding(h_mode);
}

void unmk_sha3_inc_squeeze(uint8_t* output, int outlen, int h_mode, int rate) {
	uint8_t *o;
	int len, offset;
	if (outlen < mask_inc) {
		len = outlen;
	} else {
		len = mask_inc;
	}
	o = output;
	if (len > 0) {
		offset = rate - mask_inc;
		memcpy(o, mask_buffer_1+offset, len);
		o += len;
		outlen -= len;
		mask_inc -= len;
	}

	while (outlen > 0) {
		unmk_keccak_squeeze(unmk_buffer, rate, h_mode);
		if (outlen < rate) {
			len = outlen;
		} else {
			len = rate;
		}
		memcpy(o, unmk_buffer, len);
		o += len;
		outlen -= len;
		mask_inc -= rate - len;
	}
}

void mask_sha3_inc_init(int h_mode) {
	mask_inc = 0;
	mask_keccak_init(h_mode);
}

void mask_sha3_inc_absorb(const uint8_t* input1, const uint8_t* input2, size_t inlen, int h_mode) {
	while (inlen > MAX_ABSORB_LEN) {
		mask_keccak_absorb(input1, input2, MAX_ABSORB_LEN, h_mode);
		inlen -= MAX_ABSORB_LEN;
		input1 += MAX_ABSORB_LEN;
		input2 += MAX_ABSORB_LEN;
	}
	if (inlen > 0) {
		mask_keccak_absorb(input1, input2, inlen, h_mode);
	}
}

void mask_sha3_inc_padding(int h_mode) {
	mask_keccak_padding(h_mode);
}

void mask_sha3_inc_squeeze(uint8_t* output1, uint8_t* output2, int outlen, int h_mode, int rate) {
	uint8_t *o1, *o2;
	int len, offset;
	if (outlen < mask_inc) {
		len = outlen;
	} else {
		len = mask_inc;
	}
	o1 = output1;
	o2 = output2;
	if (len > 0) {
		offset = rate - mask_inc;
		memcpy(o1, mask_buffer_1+offset, len);
		memcpy(o2, mask_buffer_2+offset, len);
		o1 += len;
		o2 += len;
		outlen -= len;
		mask_inc -= len;
	}

	while (outlen > 0) {
		mask_keccak_squeeze(mask_buffer_1, mask_buffer_2, rate, h_mode);
		if (outlen < rate) {
			len = outlen;
		} else {
			len = rate;
		}
		memcpy(o1, mask_buffer_1, len);
		memcpy(o2, mask_buffer_2, len);
		o1 += len;
		o2 += len;
		outlen -= len;
		mask_inc -= rate - len;
	}
}


// Demo of unmk_sha3 and mask_sha3
void unmk_sha3_512(uint8_t *output, const uint8_t *input, size_t inlen) {
	unmk_sha3(output,64, input, inlen, SHA3_512, SHA3_512_RATE);
}

void mask_sha3_512(uint8_t *output1, uint8_t *output2, const uint8_t *input1,
                   const uint8_t *input2, size_t inlen) {
	mask_sha3(output1, output2, 64, input1, input2, inlen, SHA3_512_MASK, SHA3_512_RATE);
}

void unmk_sha3_256(uint8_t *output, const uint8_t *input, size_t inlen) {
	unmk_sha3(output, 32, input, inlen, SHA3_256, SHA3_256_RATE);
}

void unmk_shake256(uint8_t *output, int outlen, const uint8_t *input, size_t inlen) {
	unmk_sha3(output, outlen, input, inlen, SHAKE256, SHAKE256_RATE);
}

void mask_sha3_256(uint8_t *output1, uint8_t *output2, const uint8_t *input1,
                   const uint8_t *input2, size_t inlen) {
	mask_sha3(output1, output2, 64, input1, input2, inlen, SHA3_256_MASK, SHA3_256_RATE);
}

void mask_shake256(uint8_t *output1, uint8_t *output2, size_t outlen,
                     const uint8_t *input1, const uint8_t *input2, size_t inlen) {
	mask_sha3(output1, output2, outlen, input1, input2, inlen, SHAKE256_MASK, SHAKE256_RATE);
}

void unmk_shake128(uint8_t *output, int outlen, const uint8_t *input, size_t inlen) {
	unmk_sha3(output, outlen, input, inlen, SHAKE128, SHAKE128_RATE);
}



