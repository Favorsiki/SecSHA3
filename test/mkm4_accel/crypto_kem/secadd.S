;////////////////////////////
;// SecAnd with two shares //
;////////////////////////////
.macro secand2_pt1 z0, x0, y0, t0, t1, randaddr
and \t0, \x0, \y0
ldr \t1, [\randaddr], #4
eor \z0, \t0, \t1
.endm

.macro secand2_pt2 z1, x0, x1, y0, y1, t1, randaddr ;// TODO sometimes y0=y1 (and we know that) - can we simplify something in this case? - do we need secand at all?
and \z1, \x0, \y1
eor \z1, \z1, \t1
ldr \t1, [\randaddr]
and \t1, \x1, \y0
eor \z1, \z1, \t1
ldr \t1, [\randaddr]
add \t1, R0, R1 ;// "random" value to flush internal registers and ALU
ldr \t1, [\randaddr], #4
and \t1, \x1, \y1
eor \z1, \z1, \t1
.endm

.macro secand2 z0, z1, x0, x1, y0, y1, t0, t1, randaddr
secand2_pt1 \z0,     \x0,      \y0,      \t0, \t1, \randaddr
secand2_pt2     \z1, \x0, \x1, \y0, \y1,      \t1, \randaddr
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro ld_xor_st_st x, y, xa, ya, za, za2
ldr \x, [\xa], #8
ldr \y, [\ya], #8
eor \x, \x, \y
str \x, [\za2], #4
str \x, [\za], #8
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro ld_st_st y, ya, za, za2
ldr \y, [\ya], #8
str \y, [\za2], #4
str \y, [\za], #8
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro ld_xor_st x, y,  xa, ya
ldr \x, [\xa], #4
ldr \y, [\ya]
eor \y, \x, \y
str \y, [\ya], #4
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro ld_xor_st_2 x, y,  addr
ldr \x, [\addr], #4
ldr \y, [\addr, #100]
eor \x, \x, \y
str \x, [\addr, #100]
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro ld_xor_st_4 x, y,  addr
ldr \x, [\addr], #4
ldr \y, [\addr, #108]
eor \x, \x, \y
str \x, [\addr, #108]
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro ld_xor_st_finish x, y,  xa, ya
ldr \x, [\xa], #4
ldr \y, [\ya]
eor \x, \x, \y
str \x, [\ya], #8
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro ld_xor_xor_st x, g, gp,  xa, ga, gpa
ldr \x, [\xa]
ldr \gp, [\gpa], #4
ldr \g, [\ga], #4
eor \g, \g, \gp
eor \x, \x, \g
str \x, [\xa], #8
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro rca_carry_iteration
;// load x[i], then secand(x, c[i-1])
ldr R4, [R1], #4
secand2_pt1 R5, R4, R8, R10, R11, R3
str R5, [R12]
ldr R6, [R1], #4
secand2_pt2 R7, R4, R6, R8, R9, R11, R3
str R7, [R12, #48]

;// load y[i], then secand(y, c[i-1])
ldr R4, [R2], #4
secand2_pt1 R5, R4, R8, R10, R11, R3
ldr R6, [R2], #4
secand2_pt2 R7, R4, R6, R8, R9, R11, R3

ldr R8, [R12]
eor R8, R4, R8
str R8, [R12], #4
ldr R9, [R12, #44]
eor R9, R6, R9
str R9, [R12, #44]
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro rca_carry_lambda_iteration
;// load y[i], then secand(x, c[i-1])
ldr R4, [R2], #4
secand2_pt1 R5, R4, R8, R10, R11, R3
str R5, [R12]
ldr R6, [R2], #4
secand2_pt2 R7, R4, R6, R8, R9, R11, R3
str R7, [R12, #48]
.endm



;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro rca_finalize_iteration
ldr R4, [R1], #4
ldr R5, [R2], #4
ldr R10, [R12], #4
eor R8, R4, R5
eor R8, R10, R8
str R8, [R0], #4

ldr R6, [R1], #4
ldr R7, [R2], #4
ldr R11, [R12, #44]
eor R9, R6, R7
eor R9, R11, R9
str R9, [R0], #4
.endm



;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro rca_finalize_lambda_iteration
ldr R5, [R2], #4
ldr R10, [R12], #4
eor R8, R10, R5
str R8, [R0], #4

ldr R7, [R2], #4
ldr R11, [R12, #44]
eor R9, R11, R7
str R9, [R0], #4
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro x_xor_y
ldr R4, [R1], #8
ldr R5, [R2], #8
eor R6, R4, R5
str R6, [R0], #8
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro mov_z_y
ldr R5, [R2], #8
str R5, [R0], #8
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro x_and_y
ldr R4, [R1], #4
ldr R5, [R2], #4
secand2_pt1 R8, R4, R5, R10, R11, R3
str R8, [R12], #4
ldr R6, [R1], #4
ldr R7, [R2], #4
secand2_pt2 R9, R4, R6, R5, R7, R11, R3
str R9, [R12], #4
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro compute_carry
ldr R4, [R0], #4
secand2_pt1 R8, R4, R5, R10, R11, R3
ldr R6, [R0], #4
secand2_pt2 R9, R4, R6, R5, R7, R11, R3

ldr R5, [R12]
eor R5, R5, R8
str R5, [R12], #4
ldr R7, [R12]
eor R7, R7, R9
str R7, [R12], #4
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro compute_carry_lambda
ldr R4, [R0], #4
secand2_pt1 R8, R4, R5, R10, R11, R3
str R8, [R12], #4
ldr R6, [R0], #4
secand2_pt2 R9, R4, R6, R5, R7, R11, R3
str R9, [R12], #4
ldr R5, [R3]
eor R5, R5, R8
ldr R7, [R3], #4
eor R7, R7, R9
.endm

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.macro add_carry
ldr R4, [R0]
ldr R5, [R12], #8
eor R6, R4, R5
str R6, [R0], #8
.endm

.syntax unified
#.cpu cortex-m4
.thumb

;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.global	secadd_coef
.type	secadd_coef, %function
.align 2
;// R0 - z (out) pointer
;// R1 - x (in) pointer CONST
;// R2 - y (in) pointer CONST
;// R3 - rand pointer (u32)
secadd_coef:
push {R4-R12}
;//push {R12}
;//ldr R12, [R3]
;//push {R11}
;//ldr R11, [R3]
;//push {R10}
;//ldr R10, [R3]
;//push {R9}
;//ldr R9, [R3]
;//push {R8}
;//ldr R8, [R3]
;//push {R7}
;//ldr R7, [R3]
;//push {R6}
;//ldr R6, [R3]
;//push {R5}
;//ldr R5, [R3]
;//push {R4}
;//ldr R4, [R3], #4

;// 12 masked bitslices for carry
mov R12, SP
sub SP, #96

mov R4, #0
mov R5, #0

strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!

strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!

strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!

;// compute x^y share-wise
x_xor_y
x_xor_y
x_xor_y
x_xor_y

x_xor_y
x_xor_y
x_xor_y
x_xor_y

x_xor_y
x_xor_y
x_xor_y
x_xor_y

x_xor_y

sub R0, #100
sub R1, #100
sub R2, #100

x_xor_y
x_xor_y
x_xor_y
x_xor_y

x_xor_y
x_xor_y
x_xor_y
x_xor_y

x_xor_y
x_xor_y
x_xor_y
x_xor_y

x_xor_y

sub R0, #108
sub R1, #108
sub R2, #108

;// [R0] now: 13 bit slices of x^y

;// compute x&y
x_and_y
x_and_y
x_and_y
x_and_y

x_and_y
x_and_y
x_and_y
x_and_y

x_and_y
x_and_y
x_and_y
x_and_y

sub  R1, #96
sub  R2, #96
sub R12, #96

;// [SP] now: 12 bit slices of x&y

;// compute carry: c&(x^y) ^ (x&y)
add R0, #8
ldr R4, [R0], #4
ldr R5, [R12], #4
secand2_pt1 R8, R4, R5, R10, R11, R3
ldr R6, [R0], #4
ldr R7, [R12], #4
secand2_pt2 R9, R4, R6, R5, R7, R11, R3
;// R8,R9 = (x.bs[1]^y.bs[1])&c.bs[0]

ldr R5, [R12]
eor R5, R5, R8
str R5, [R12], #4
ldr R7, [R12]
eor R7, R7, R9
str R7, [R12], #4

compute_carry
compute_carry
compute_carry
compute_carry

compute_carry
compute_carry
compute_carry
compute_carry

compute_carry
compute_carry

sub R0, #88
sub R12, #96

;// add carry
add_carry
add_carry
add_carry
add_carry

add_carry
add_carry
add_carry
add_carry

add_carry
add_carry
add_carry
add_carry

sub R0, #92
sub R12, #92

add_carry
add_carry
add_carry
add_carry

add_carry
add_carry
add_carry
add_carry

add_carry
add_carry
add_carry
add_carry

;// restore and free
sub R0, #108
add SP, #96

;//pop {R4}
;//ldr R5, [R3]
;//pop {R5}
;//ldr R6, [R3]
;//pop {R6}
;//ldr R7, [R3]
;//pop {R7}
;//ldr R8, [R3]
;//pop {R8}
;//ldr R9, [R3]
;//pop {R9}
;//ldr R10, [R3]
;//pop {R10}
;//ldr R11, [R3]
;//pop {R11}
;//ldr R12, [R3], #4
;//pop {R12}
pop {R4-R12}
bx lr















;////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.global	secadd_lambda ;// only for lambda=3!
.type	secadd_lambda, %function
.align 2
;// R0 - z (out) pointer
;// R1 - x (in) pointer CONST lambda
;// R2 - y (in) pointer CONST coef
;// R3 - rand pointer (u32)
secadd_lambda:
push {R4-R12}
;//push {R12}
;//ldr R12, [R3]
;//push {R11}
;//ldr R11, [R3]
;//push {R10}
;//ldr R10, [R3]
;//push {R9}
;//ldr R9, [R3]
;//push {R8}
;//ldr R8, [R3]
;//push {R7}
;//ldr R7, [R3]
;//push {R6}
;//ldr R6, [R3]
;//push {R5}
;//ldr R5, [R3]
;//push {R4}
;//ldr R4, [R3], #4


;// 12 masked bitslices for carry
mov R12, SP
sub SP, #96

mov R4, #0
mov R5, #0

strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!

strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!

strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!
strd R4, R5, [R12, #-8]!

;// compute x^y share-wise
x_xor_y
x_xor_y
x_xor_y
mov_z_y

mov_z_y
mov_z_y
mov_z_y
mov_z_y

mov_z_y
mov_z_y
mov_z_y
mov_z_y

mov_z_y

sub R0, #100
sub R1, #20
sub R2, #100

x_xor_y
x_xor_y
x_xor_y
mov_z_y

mov_z_y
mov_z_y
mov_z_y
mov_z_y

mov_z_y
mov_z_y
mov_z_y
mov_z_y

mov_z_y

sub R0, #108
sub R1, #28
sub R2, #108

;// compute x&y
x_and_y
x_and_y
x_and_y
ldr R4, [R3], #4
mov R5, R4
strd R4, R5, [R12], #8

strd R4, R5, [R12], #8
strd R4, R5, [R12], #8
strd R4, R5, [R12], #8
strd R4, R5, [R12], #8

strd R4, R5, [R12], #8
strd R4, R5, [R12], #8
strd R4, R5, [R12], #8
strd R4, R5, [R12], #8

sub  R1, #24
sub  R2, #24
sub R12, #96

;// compute carry: c&(x^y) ^ (x&y)
add R0, #8
ldr R4, [R0], #4
ldr R5, [R12], #4
secand2_pt1 R8, R4, R5, R10, R11, R3
ldr R6, [R0], #4
ldr R7, [R12], #4
secand2_pt2 R9, R4, R6, R5, R7, R11, R3
;// R8,R9 = (x.bs[1]^y.bs[1])&c.bs[0]


ldr R5, [R3]
eor R8, R5, R8
ldr R7, [R3], #4
eor R9, R7, R9

ldr R5, [R12]
eor R5, R5, R8
str R5, [R12], #4

ldr R7, [R12]
eor R7, R7, R9
str R7, [R12], #4


;// compute carry with re-sharing
ldr R4, [R0], #4
secand2_pt1 R8, R4, R5, R10, R11, R3
ldr R6, [R0], #4
secand2_pt2 R9, R4, R6, R5, R7, R11, R3


ldr R5, [R3]
eor R8, R5, R8
ldr R7, [R3], #4
eor R9, R7, R9

ldr R5, [R12]
eor R5, R5, R8
str R5, [R12], #4
ldr R7, [R12]
eor R7, R7, R9
str R7, [R12], #4

compute_carry_lambda
compute_carry_lambda
compute_carry_lambda

compute_carry_lambda
compute_carry_lambda
compute_carry_lambda
compute_carry_lambda

compute_carry_lambda
compute_carry_lambda

sub R0, #88
sub R12, #96

;// add carry
add_carry
add_carry
add_carry
add_carry

add_carry
add_carry
add_carry
add_carry

add_carry
add_carry
add_carry
add_carry

sub R0, #92
sub R12, #92

add_carry
add_carry
add_carry
add_carry

add_carry
add_carry
add_carry
add_carry

add_carry
add_carry
add_carry
add_carry

;// restore and free
sub R0, #108
add SP, #96

;//pop {R4}
;//ldr R5, [R3]
;//pop {R5}
;//ldr R6, [R3]
;//pop {R6}
;//ldr R7, [R3]
;//pop {R7}
;//ldr R8, [R3]
;//pop {R8}
;//ldr R9, [R3]
;//pop {R9}
;//ldr R10, [R3]
;//pop {R10}
;//ldr R11, [R3]
;//pop {R11}
;//ldr R12, [R3], #4
;//pop {R12}
pop {R4-R12}
bx lr






















.global	secaddq_lambda ;// only for lambda=3!
.type	secaddq_lambda, %function
.align 2
;// R0 = z out ptr
;// R1 = x  in ptr (lambda)
;// R2 = y  in ptr (coef)
;// R3 = rand ptr
secaddq_lambda:
push {R0, R1, R2, R4, R5, LR}

sub SP, SP, #208
add R0, SP, #104
bl secadd_lambda


;// construct c from MSB
ldr R4, [R0, #96]
mov R5, #0

str R4, [SP]
str R4, [SP, #64]
str R4, [SP, #80]
str R4, [SP, #88]

mov R4, #0
strd R4, R5, [SP,  #8]
strd R4, R5, [SP, #16]
strd R4, R5, [SP, #24]
strd R4, R5, [SP, #32]
strd R4, R5, [SP, #40]
strd R4, R5, [SP, #48]
strd R4, R5, [SP, #56]
strd R4, R5, [SP, #72]
strd R4, R5, [SP, #96]

ldr R5, [R0, #100]
str R5, [SP,  #4]
str R5, [SP, #68]
str R5, [SP, #84]
str R5, [SP, #92]

;// call secadd_coef
mov R1, SP ;// first argument: c
add R2, SP, #104 ;// second argument: previous result
ldr R0, [SP, #208] ;// result address: our final result
bl secadd_coef
add SP, SP, #208 ;// free memory


pop {R0, R1, R2, R4, R5, LR}
bx lr












#void pack_bitslices(masked_eta_bs32 *z1, masked_eta_bs32 *z2, const masked_u8_sampling *x, size_t offset)
#{
  #size_t i;
  #for (i = 0; i < 32; i += 2, offset += 1)
  #{
    #z1->bs[0].u32[n] >>= 2;
    #z1->bs[1].u32[n] >>= 2;
    #z2->bs[0].u32[n] >>= 2;
    #z2->bs[1].u32[n] >>= 2;
    #z1->bs[0].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 30) & 0x40000000;
    #z1->bs[1].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 29) & 0x40000000;
    #z2->bs[0].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 28) & 0x40000000;
    #z2->bs[1].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 27) & 0x40000000;
    #z1->bs[0].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 27) & 0x80000000;
    #z1->bs[1].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 26) & 0x80000000;
    #z2->bs[0].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 25) & 0x80000000;
    #z2->bs[1].u32[n] |= ((uint32_t)x->share[n].u8[offset] << 24) & 0x80000000;
  #}
#}

.macro pack_one_iteration
and R9, R8, #1
lsl R9, R9, #30
orr R4, R4, R9

and R9, R8, #2
lsl R9, R9, #29
orr R5, R5, R9

and R9, R8, #4
lsl R9, R9, #28
orr R6, R6, R9

and R9, R8, #8
lsl R9, R9, #27
orr R7, R7, R9

and R9, R8, #16
lsl R9, R9, #27
orr R4, R4, R9

and R9, R8, #32
lsl R9, R9, #26
orr R5, R5, R9

and R9, R8, #64
lsl R9, R9, #25
orr R6, R6, R9

and R9, R8, #128
lsl R9, R9, #24
orr R7, R7, R9
.endm

.global	pack_bitslices
.type	pack_bitslices, %function
.align 2
;// R0 = masked_eta_bs32 *z1
;// R1 = masked_eta_bs32 *z2
;// R2 = const uint8_t*
;// R4 = z1->bs[0]
;// R5 = z1->bs[1]
;// R6 = z2->bs[0]
;// R7 = z2->bs[1]
pack_bitslices:
push {R4-R9}

mov R4, #0
mov R5, #0
mov R6, #0
mov R7, #0
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration
lsr R4, R4, #2
lsr R5, R5, #2
lsr R6, R6, #2
lsr R7, R7, #2
ldrb R8, [R2], #1
pack_one_iteration

str R4, [R0]
str R5, [R0, #8]
str R6, [R1]
str R7, [R1, #8]

mov R4, #0
mov R5, #0
mov R6, #0
mov R7, #0
mov R8, #0
mov R9, #0

pop {R4-R9}
bx lr





