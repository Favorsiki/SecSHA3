#include "macros.i"

.syntax unified
#.cpu cortex-m4
.thumb

.global asm_barrett_reduce
.type asm_barrett_reduce,%function
.align 2
asm_barrett_reduce:
  push    {r4-r11, r14}

  poly        .req r0
  poly0       .req r1
  poly1       .req r2
  poly2       .req r3
  poly3       .req r4
  poly4       .req r5
  poly5       .req r6
  poly6       .req r7
  poly7       .req r8
  loop        .req r9
  barrettconst .req r10
  q           .req r11
  tmp         .req r12
  tmp2        .req r14

  movw barrettconst, #20159
  movw q, #3329

  movw loop, #16
  1:
    ldm poly, {poly0-poly7}

    doublebarrett poly0, tmp, tmp2, q, barrettconst
    doublebarrett poly1, tmp, tmp2, q, barrettconst
    doublebarrett poly2, tmp, tmp2, q, barrettconst
    doublebarrett poly3, tmp, tmp2, q, barrettconst
    doublebarrett poly4, tmp, tmp2, q, barrettconst
    doublebarrett poly5, tmp, tmp2, q, barrettconst
    doublebarrett poly6, tmp, tmp2, q, barrettconst
    doublebarrett poly7, tmp, tmp2, q, barrettconst

    stm poly!, {poly0-poly7}

    subs.w loop, #1
  bne.w 1b

  pop     {r4-r11, pc}


.macro from_mont q, qinv, a, c, tmp, tmp2
  smulbb \tmp, \a, \c
  montgomery \q, \qinv, \tmp, \tmp2
  smultb \a, \a, \c
  montgomery \q, \qinv, \a, \tmp
  pkhtb \a, \tmp, \tmp2, asr#16
.endm

.global asm_frommont
.type asm_frommont,%function
.align 2
asm_frommont:
  push    {r4-r11, r14}

  poly        .req r0
  poly0       .req r1
  poly1       .req r2
  poly2       .req r3
  poly3       .req r4
  poly4       .req r5
  poly5       .req r6
  poly6       .req r7
  poly7       .req r8
  loop        .req r9
  constant    .req r10
  qinv        .req r11
  q           .req r11
  tmp         .req r12
  tmp2        .req r14

  movw q, #3329
  movt qinv, #3327

  movw constant, #1353

  movw loop, #16
  1:
    ldm poly, {poly0-poly7}

    from_mont q, qinv, poly0, constant, tmp, tmp2
    from_mont q, qinv, poly1, constant, tmp, tmp2
    from_mont q, qinv, poly2, constant, tmp, tmp2
    from_mont q, qinv, poly3, constant, tmp, tmp2
    from_mont q, qinv, poly4, constant, tmp, tmp2
    from_mont q, qinv, poly5, constant, tmp, tmp2
    from_mont q, qinv, poly6, constant, tmp, tmp2
    from_mont q, qinv, poly7, constant, tmp, tmp2

    stm poly!, {poly0-poly7}

    subs.w loop, #1
  bne.w 1b

  pop     {r4-r11, pc}

.global sub_mod
.type sub_mod, %function
.align 2
// int16_t sub_mod(int16_t a, int16_t b) 
// Input coefficients have to be in range of 0,KYBER_Q
sub_mod:
		
	push    {r2-r3, r14}
	sub r0, r1
	add r2, r0, #3329
	sxtb r3, r0, ROR #24
	and r2, r3
	mvn r3, r3
	and r0, r3
	eor r0, r2
	pop     {r2-r3, pc}

.global add_mod
.type add_mod, %function
.align 2
// int16_t add_mod(int16_t a, int16_t b) 
// Input coefficients have to be in range of 0,KYBER_Q
add_mod:
		
	push    {r2-r3, r14}
	add r0, r1
	sub r2, r0, #3329
	sxtb r3, r2, ROR #24
	and r0, r3
	mvn r3, r3
	and r2, r3
	eor r0, r2
	pop     {r2-r3, pc}


.global asm_barrett_reduce32
.type asm_barrett_reduce32, %function
.align 2
//int16_t asm_barrett_reduce32(int32_t a)
// only works when a <= q^2
asm_barrett_reduce32:
		
	push    {r2-r3 ,r14}
	// const int16_t v = ((1U << 26) + KYBER_Q / 2) / KYBER_Q;
	movw r1, #0x4EBF

	// (int64_t)v * a
	smull r2, r3, r0, r1

	// (int64_t)v * a + (1 << 25)
	adds r2, r2, #0x2000000
	adc r3, r3, #0

	// (((int64_t)v * a + (1 << 25)) >> 26)
	lsr r2, r2, #26
	add r2, r2, r3, lsl #6

	// ((((int64_t)v * a + (1 << 25)) >> 26) - 1)
	sub r2, r2, #1

	// ((((int64_t)v * a + (1 << 25)) >> 26) - 1)*KYBER_Q
	movw r3, #0xD01
	mul r2, r2, r3

	// return a - ((((int64_t)v * a + (1 << 25)) >> 26) - 1)*KYBER_Q;
	sub r0, r0, r2
		
	pop     {r2-r3, pc}
