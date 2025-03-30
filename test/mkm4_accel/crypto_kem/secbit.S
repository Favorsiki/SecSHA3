.syntax unified
#.cpu cortex-m4
.thumb



.macro trigger_high
push {R0,R1}
mov R0, #0x18
movt R0, #0x4800
mov R1, #0x1000
str R1, [R0]
pop {R0,R1}
.endm


.macro trigger_low
push {R0,R1}
mov R0, #0x18
movt R0, #0x4800
mov R1, #0
movt R1, #0x1000
str R1, [R0]
pop {R0,R1}
.endm





.macro secand2_pt1 z0, x0, y0, t0, t1, randaddr
and \t0, \x0, \y0
ldr \t1, [\randaddr], #4
eor \z0, \t0, \t1
.endm

.macro secand2_pt2 z1, x0, x1, y0, y1, t1, randaddr 
and \z1, \x0, \y1
eor \z1, \z1, \t1
ldr \t1, [\randaddr]
and \t1, \x1, \y0
eor \z1, \z1, \t1
ldr \t1, [\randaddr]
add \t1, R0 ;// "random" value to flush internal registers and ALU
ldr \t1, [\randaddr], #4
and \t1, \x1, \y1
eor \z1, \z1, \t1
.endm

.macro secand2 z0, z1, x0, x1, y0, y1, t0, t1, randaddr
secand2_pt1 \z0,     \x0,      \y0,     \t0, \t1, \randaddr
add \t0, R0, R1;// flush ALU
ldr \t0, [\randaddr]
secand2_pt2     \z1, \x0, \x1, \y0, \y1,     \t1, \randaddr
.endm







.macro secbitsub_loop
;// load z->bs[0].u32[0] and y->bs[0].u32[0]
ldr R4, [R0]
ldr R5, [R2], #4
eor R6, R4, R5
;// R5 now w.u32[0]
;// store z->bs[0].u32[0] ^= y->bs[0].u32[0]
str R6, [R0]

;// R3 = u.u32[0] = ~z->bs[0].u32[0]
mvn R4, R4
;// load z->bs[0].u32[1] and y->bs[0].u32[1]
ldr R7, [R0, #4]
ldr R8, [R2], #4
eor R9, R7, R8
;// R8 now w.u32[1]
;// store z->bs[0].u32[1] ^= y->bs[0].u32[1]
str R9, [R0, #4]

secand2 R10, R11,  R5, R8,  R4, R7,  R6, R9,  R3

;// R4 := z->bs[1].u32[0]
ldr R12, [R0, #8]
;// z->bs[1].u32[0] ^= R10 (preserve old state in R4)
eor R6, R10, R12
str R6, [R0, #8]

add R6, R0, R1 ;// flush ALU (leakage found if not done)
ldr R6, [R3], #4

;// R7 := z->bs[1].u32[1]
ldr R7, [R0, #12]
;// z->bs[1].u32[1] ^= R11 (preserve old state in R7)
eor R9, R11, R7
str R9, [R0, #12]

;// we need for next iteration l=2:
;// (R4, R7) = z->bs[1]
;// (R10, R11) = w

;// invert z->bs[1]
add R4, R0, R1
mvn R4, R12
add R12, R0, R1
secand2 R5, R8,  R10, R11,  R4, R7,  R6, R9,  R3


;// load z->bs[2].u32[0]
ldr R12, [R0, #16]
;// z->bs[2].u32[0] ^= R5
eor R12, R12, R5
str R12, [R0, #16]

add R12, R0, R1 ;// flush ALU

;// load z->bs[2].u32[1]
ldr R12, [R0, #20]
;// z->bs[2].u32[0] ^= R5
eor R12, R12, R8
str R12, [R0, #20]
add R12, R0, R1
.endm










.global	secbit_add_sub_constadd
.type	secbit_add_sub_constadd, %function
.align 2
;// further optimization possible:
;// as of now, the three functions are glued together
secbit_add_sub_constadd:
;// R0 - z (out) pointer (masked_lambda_bs32)
;// R1 - x (in) pointer (masked_eta_bs32)
;// R2 - y (in) pointer (masked_eta_bs32)
;// R3 - rand pointer

push {R4-R11}

;// flush registers
add R4, R0, R1
add R5, R0, R1
add R6, R0, R1
add R7, R0, R1
add R8, R0, R1
add R9, R0, R1
add R10, R0, R1
add R11, R0, R1

;// secbitadd 
;// load x->bs[0:1].u32[0:1] interleaved
ldr R4, [R1]
ldr R5, [R1, #8]
ldr R6, [R1, #4]
ldr R7, [R1, #12]

secand2_pt1 R8, R4, R5, R10, R11, R3

;// store z->bs[1].u32[0]
str R8, [R0, #8]
;// store z->bs[2].u32[0]
mov R8, #0
str R8, [R0, #16]

secand2_pt2 R9, R4, R6, R5, R7, R11, R3

;// store z->bs[1].u32[1]
str R9, [R0, #12]

;// compute and store z->bs[0].u32[0]
eor R4, R5, R4
str R4, [R0]
add R5, R0, R1 ;// flush R5


;// store z->bs[2].u32[1]
str R8, [R0, #20]

;// compute and store z->bs[0].u32[1]
eor R6, R7, R6
str R6, [R0, #4]



;// secbitsub

ldr R6, [R3], #4
ldr R7, [R3], #4



secbitsub_loop
secbitsub_loop


add R7, R0, R1 ;// flush ALU
  
;// secconstadd
ldr R7, [R0, #20]
ldr R8, [R0, #12]
eor R8, R8, R7
str R8, [R0, #20]

add R8, R0, R1 ;// flush ALU

ldr R4, [R0, #8]
ldr R5, [R0, #16]
eor R5, R5, R4
str R5, [R0, #16]
mvn R4, R4
str R4, [R0, #8]

pop {R4-R11}
bx lr




