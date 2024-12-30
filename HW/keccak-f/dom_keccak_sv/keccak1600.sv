`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/06 17:29:46
// Design Name: 
// Module Name: keccak1600
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
//  
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
// 2022-11-17 11:04
// 2022-12-21 14:05
// 2023-01-03 15:11
// 2023-02-13 10:17
module keccak1600 (
    input           CLK,
    input           RESET,
    input           INIT,
    input           GO,
    input           SQUEEZE,
	input 			IN_READY,
    input           ABSORB,
    input           EXTEND,
    input   [31:0]  DIN_0, DIN_1,
    output          DONE,
    output  [31:0]  RESULT_0, RESULT_1
);

    wire    RESET_RF, ENABLE_RF, DONE_INTERN;
    wire    [63:0]   CONST;
    wire    [1599:0] REORDER_OUT_0, REORDER_OUT_1;
	reg 	[1599:0] STATE_RESULT_0, STATE_RESULT_1;
    assign RESULT_0 = STATE_RESULT_0[1599:1568];
    assign RESULT_1 = STATE_RESULT_1[1599:1568];
    assign DONE = DONE_INTERN;
	
	always @(posedge CLK) begin
		if (RESET) begin STATE_RESULT_0 <= 0; STATE_RESULT_1 <= 0; end 
		else if (DONE_INTERN) begin STATE_RESULT_0 <= REORDER_OUT_0; STATE_RESULT_1 <= REORDER_OUT_1; end 
		else if (SQUEEZE) begin STATE_RESULT_0 <= {STATE_RESULT_0[1567:0], STATE_RESULT_0[1599:1568]}; STATE_RESULT_1 <= {STATE_RESULT_1[1567:0], STATE_RESULT_1[1599:1568]}; end 
		else begin STATE_RESULT_0 <= STATE_RESULT_0; STATE_RESULT_1 <= STATE_RESULT_1; end 
	end 

    Round rnd(.CLK(CLK), .RESET(RESET_RF), .INIT(INIT), .ENABLE(ENABLE_RF), .IN_READY(IN_READY), .ABSORB(ABSORB), .EXTEND(EXTEND), .CONST(CONST), .DIN_0(DIN_0), .DIN_1(DIN_1), .OUTPUT_0(REORDER_OUT_0), .OUTPUT_1(REORDER_OUT_1));
    StateMachine fsm(.CLK(CLK), .RESET(RESET), .INIT(INIT), .GO(GO), .DONE(DONE_INTERN), .RESET_RF(RESET_RF), .ENABLE_RF(ENABLE_RF), .CONST(CONST));

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`define low_pos(w,b)      ((w)*64 + (b)*8)
`define low_pos2(w,b)     `low_pos(w,7-b)
`define high_pos(w,b)     (`low_pos(w,b) + 7)
`define high_pos2(w,b)    (`low_pos2(w,b) + 7)

module Round (
    input           CLK,
    input           RESET,
    input           INIT,
    input           ENABLE,
    input           IN_READY,
    input           ABSORB,
    input           EXTEND,
    input   [63:0]  CONST,
    input   [31:0]  DIN_0, DIN_1,
    output  [1599:0] OUTPUT_0, OUTPUT_1
);

    wire    [1599:0] MUX_0, STATE_0, TMP1_0, TMP2_0, TMP3_0, TMP4_0, TMP5_0, TMP6_0;
    wire    [1599:0] MUX_1, STATE_1, TMP1_1, TMP2_1, TMP3_1, TMP4_1, TMP5_1, TMP6_1;

    assign OUTPUT_0 = STATE_0;
    assign OUTPUT_1 = STATE_1;

    RegisterFDRE Reg_0(.CLK(CLK), .RESET(RESET), .INIT(INIT), .ENABLE(ENABLE), .IN_READY(IN_READY), .ABSORB(ABSORB), .EXTEND(EXTEND), .DIN(DIN_0), .D(TMP6_0), .Q(STATE_0));
    RegisterFDRE Reg_1(.CLK(CLK), .RESET(RESET), .INIT(INIT), .ENABLE(ENABLE), .IN_READY(IN_READY), .ABSORB(ABSORB), .EXTEND(EXTEND), .DIN(DIN_1), .D(TMP6_1), .Q(STATE_1));
    Theta   T0(.X(MUX_0), 	.Y(TMP1_0));
    Theta   T1(.X(MUX_1), 	.Y(TMP1_1));
    Rho     R0(.X(TMP1_0), 	.Y(TMP2_0));
    Rho     R1(.X(TMP1_1), 	.Y(TMP2_1));
    Pi      P0(.X(TMP2_0), 	.Y(TMP3_0));
    Pi      P1(.X(TMP2_1), 	.Y(TMP3_1));
    Chi     C(.X_0(TMP3_0),	.X_1(TMP3_1), .Y_0(TMP4_0), .Y_1(TMP4_1));
    Iota    I0(.X(TMP4_0), .C(CONST), .Y(TMP5_0));
    assign TMP5_1 = TMP4_1;
	

	genvar w, b;
	
    generate
      for(w=0; w<25; w=w+1)
        begin  
          for(b=0; b<8; b=b+1)
            begin 
              assign MUX_0[`high_pos(w,b):`low_pos(w,b)] = STATE_0[`high_pos2(w,b):`low_pos2(w,b)];
              assign MUX_1[`high_pos(w,b):`low_pos(w,b)] = STATE_1[`high_pos2(w,b):`low_pos2(w,b)];
            end
        end
    endgenerate

    generate
      for(w=0; w<25; w=w+1)
        begin  
          for(b=0; b<8; b=b+1)
            begin  
              assign TMP6_0[`high_pos(w,b):`low_pos(w,b)] = TMP5_0[`high_pos2(w,b):`low_pos2(w,b)];
              assign TMP6_1[`high_pos(w,b):`low_pos(w,b)] = TMP5_1[`high_pos2(w,b):`low_pos2(w,b)];
            end
        end
    endgenerate
	
endmodule

`undef low_pos
`undef low_pos2
`undef high_pos
`undef high_pos2

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RegisterFDRE (
    input           CLK,
    input           RESET,
    input           INIT,
    input           ENABLE,
    input           IN_READY,
    input           ABSORB,
    input           EXTEND,
    input   [31:0]  DIN,
    input   [1599:0] D,
    output  [1599:0] Q
);

    wire    [31:0]  Din_mux;
    reg     [1599:0] Q_buf;

    assign Q = Q_buf;
    assign Din_mux = EXTEND ? Q_buf[1599:1568] : (ABSORB ? Q_buf[1599:1568] ^ DIN : DIN) ;

    always @(posedge CLK) begin
        if (RESET) Q_buf <= 0;
        else if (INIT) Q_buf <= 0;
        else if (IN_READY | EXTEND ) Q_buf <= {Q_buf[1567:0], Din_mux};
        else if (ENABLE) Q_buf <= D;
    end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module StateMachine (
    input           CLK,
    input           RESET,
    input           INIT,
    input           GO,
    output  reg     DONE,
    output  reg     RESET_RF,
    output  reg     ENABLE_RF,
    output reg [63:0] CONST
);
    `define     S_RESET 2'h0
    `define     S_INIT  2'h1
    `define     S_ROUND 2'h2
    `define     S_DONE  2'h3

    reg     [1:0]   STATE, NEXT_STATE;
    reg     [7:0]   LFSR;
    reg             RESET_LFSR, ENABLE_LFSR;

    always @(posedge CLK) begin
        if (RESET_LFSR) LFSR <= 8'h1;
        else if (ENABLE_LFSR) LFSR <= {LFSR[6:0], (LFSR[7] ^ LFSR[5] ^ LFSR[4] ^ LFSR[3])};
        else LFSR <= LFSR;
    end     

    always @(LFSR) begin 
        case(LFSR)
            8'h01  : CONST <= 64'h0000000000000001;
            8'h02  : CONST <= 64'h0000000000008082;
            8'h04  : CONST <= 64'h800000000000808A;
            8'h08  : CONST <= 64'h8000000080008000;
            8'h11  : CONST <= 64'h000000000000808B;
            8'h23  : CONST <= 64'h0000000080000001;
            8'h47  : CONST <= 64'h8000000080008081;
            8'h8E  : CONST <= 64'h8000000000008009;
            8'h1C  : CONST <= 64'h000000000000008A;
            8'h38  : CONST <= 64'h0000000000000088;
            8'h71  : CONST <= 64'h0000000080008009;
            8'hE2  : CONST <= 64'h000000008000000A;
            8'hC4  : CONST <= 64'h000000008000808B;
            8'h89  : CONST <= 64'h800000000000008B;
            8'h12  : CONST <= 64'h8000000000008089;
            8'h25  : CONST <= 64'h8000000000008003;
            8'h4B  : CONST <= 64'h8000000000008002;
            8'h97  : CONST <= 64'h8000000000000080;
            8'h2E  : CONST <= 64'h000000000000800A;
            8'h5C  : CONST <= 64'h800000008000000A;
            8'hB8  : CONST <= 64'h8000000080008081;
            8'h70  : CONST <= 64'h8000000000008080;
            8'hE0  : CONST <= 64'h0000000080000001;
            8'hC0  : CONST <= 64'h8000000080008008; 			
            default : CONST <= 64'h0000000000000000;
        endcase
    end 

    always @(posedge CLK) begin
        if (RESET)  STATE <= `S_RESET;
        else        STATE <= NEXT_STATE;
    end 

    always @(STATE, INIT, GO, LFSR) begin
        RESET_RF <= 0;
        ENABLE_RF <= 0;
        RESET_LFSR <= 0;
        ENABLE_LFSR <= 0;
        DONE <= 0;
        NEXT_STATE <= STATE;
        
        case (STATE)
            `S_RESET : begin 
                RESET_RF <= 1;
                RESET_LFSR <= 1;
                if (INIT) NEXT_STATE <= `S_INIT;
            end 
            `S_INIT : begin
               ENABLE_RF <= 0;
               ENABLE_LFSR <= 0;
               DONE <= 0; 
               if (GO) NEXT_STATE <= `S_ROUND;
            end
            `S_ROUND : begin
                ENABLE_RF <= 1;
                ENABLE_LFSR <= 1;
                if (LFSR == 8'hC0) NEXT_STATE <= `S_DONE;
            end 
            `S_DONE : begin
                DONE <= 1;
                RESET_LFSR <= 1;
                NEXT_STATE <= `S_INIT;
            end 
        endcase
    end 

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Theta (
    input   [1599:0] X,
    output  [1599:0] Y
);
    wire    [319:0] SUMS;
    assign SUMS = X[1599:1280] ^ X[1279:960] ^ X[959:640] ^ X[639:320] ^ X[319:0];

    genvar I;
    generate
        for (I = 0; I < 5; I = I + 1)
            begin				
                assign Y[320*I+319 : 320*I+256] = X[320*I+319 : 320*I+256] ^ SUMS[63  :  0 ] ^ {SUMS[254 : 192], SUMS[255]}; // 0
                assign Y[320*I+255 : 320*I+192] = X[320*I+255 : 320*I+192] ^ SUMS[319 : 256] ^ {SUMS[190 : 128], SUMS[191]}; // 1	
                assign Y[320*I+191 : 320*I+128] = X[320*I+191 : 320*I+128] ^ SUMS[255 : 192] ^ {SUMS[126 : 64 ], SUMS[127]}; // 2
                assign Y[320*I+127 : 320*I+64 ] = X[320*I+127 : 320*I+64 ] ^ SUMS[191 : 128] ^ {SUMS[ 62 :  0 ], SUMS[63]}; // 3	
				assign Y[320*I+63  :  320*I+0 ] = X[320*I+63  :  320*I+0 ] ^ SUMS[127 : 64 ] ^ {SUMS[318 : 256], SUMS[319]}; // 4	
            end        
    endgenerate

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Rho (
    input   [1599:0] X,
    output  [1599:0] Y
);
    // Y = 0
    assign Y[1599 : 1536] = X[1599 : 1536]; 
    assign Y[1535 : 1472] = {X[1534 : 1472] , X[1535]};
    assign Y[1471 : 1408] = {X[1409 : 1408], X[1471 : 1410]};// 62
    assign Y[1407 : 1344] = {X[1379 : 1344], X[1407 : 1380]};// 28
    assign Y[1343 : 1280] = {X[1316 : 1280], X[1343 : 1317]};// 27

    // Y = 1
    assign Y[1279 : 1216] = {X[1243 : 1216], X[1279 : 1244]};// 36
    assign Y[1215 : 1152] = {X[1171 : 1152], X[1215 : 1172]};// 44
    assign Y[1151 : 1088] = {X[1145 : 1088], X[1151 : 1146]};// 6
    assign Y[1087 : 1024] = {X[1032 : 1024], X[1087 : 1033]};// 55
    assign Y[1023 :  960] = {X[1003 :  960], X[1023 : 1004]};// 20
	
    // Y = 2 
    assign Y[ 959 :  896] = {X[ 956 :  896], X[ 959 :  957]};// 3
    assign Y[ 895 :  832] = {X[ 885 :  832], X[ 895 :  886]};// 10
    assign Y[ 831 :  768] = {X[ 788 :  768], X[ 831 :  789]};// 43
    assign Y[ 767 :  704] = {X[ 742 :  704], X[ 767 :  743]};// 25
    assign Y[ 703 :  640] = {X[ 664 :  640], X[ 703 :  665]};// 39
	
    // Y = 3
    assign Y[ 639 :  576] = {X[ 598 :  576], X[ 639 :  599]};// 41
    assign Y[ 575 :  512] = {X[ 530 :  512], X[ 575 :  531]};// 45
    assign Y[ 511 :  448] = {X[ 496 :  448], X[ 511 :  497]};// 15
    assign Y[ 447 :  384] = {X[ 426 :  384], X[ 447 :  427]};// 21
    assign Y[ 383 :  320] = {X[ 375 :  320], X[ 383 :  376]};// 8
      
    // Y = 4
    assign Y[ 319 :  256] = {X[ 301 :  256], X[ 319 :  302]};// 18
    assign Y[ 255 :  192] = {X[ 253 :  192], X[ 255 :  254]};// 2
    assign Y[ 191 :  128] = {X[ 130 :  128], X[ 191 :  131]};// 61
    assign Y[ 127 :   64] = {X[ 71 :   64 ], X[ 127 :  72 ]};// 56
    assign Y[  63 :    0] = {X[  49 :    0], X[  63 :  50 ]};// 14

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Pi (
    input   [1599:0] X,
    output  [1599:0] Y
);
    // Y = 0   
    assign Y[1599 : 1536] = X[1599 : 1536]; // 0,0 - 0,0
    assign Y[1535 : 1472] = X[1215 : 1152];	//[1,0] - 1,1
    assign Y[1471 : 1408] = X[ 831 :  768];	//[2,0] - 2,2
    assign Y[1407 : 1344] = X[ 447 :  384];	//[3,0] - 3,3
    assign Y[1343 : 1280] = X[  63 :    0];	//[4,0] - 4,4 

    // Y = 1
    assign Y[1279 : 1216] = X[1407 : 1344]; //[0,1] - 3,0 
    assign Y[1215 : 1152] = X[1023 :  960];	//[1,1] - 4,1
    assign Y[1151 : 1088] = X[ 959 :  896];	//[2,1] - 0,2
    assign Y[1087 : 1024] = X[ 575 :  512];	//[3,1] - 1,3
    assign Y[1023 :  960] = X[ 191 :  128]; //[4,1] - 2,4

    // Y = 2    
    assign Y[ 959 :  896] = X[1535 : 1472];  // 0,2 - 1,0
    assign Y[ 895 :  832] = X[1151 : 1088];  // 1,2 - 2,1
    assign Y[ 831 :  768] = X[ 767 :  704];  // 2,2 - 3,2
    assign Y[ 767 :  704] = X[ 383 :  320];  // 3,2 - 4,3
    assign Y[ 703 :  640] = X[ 319 :  256];  // 4,2 - 0,4
	
    // Y = 3
    assign Y[ 639 :  576] = X[1343 : 1280];  // 0,3 - 4,0
    assign Y[ 575 :  512] = X[1279 : 1216];  // 1,3 - 0,1
    assign Y[ 511 :  448] = X[ 895 :  832];  // 2,3 - 1,2
    assign Y[ 447 :  384] = X[ 511 :  448];	 // 3,3 - 2,3
    assign Y[ 383 :  320] = X[ 127 :   64];	 // 4,3 - 3,4

    // Y = 4
    assign Y[ 319 :  256] = X[1471 : 1408];  // 0,4 - 2,0
    assign Y[ 255 :  192] = X[1087 : 1024];	 // 1,4 - 3,1
    assign Y[ 191 :  128] = X[ 703 :  640];	 // 2,4 - 4,2
    assign Y[ 127 :   64] = X[ 639 :  576];	 // 3,4 - 0,3
    assign Y[  63 :    0] = X[ 255 :  192];	 // 4,4 - 1,4
	
endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`define low_pos(x,y)        `high_pos(x,y) - 63
`define high_pos(x,y)       1599 - 64*(5*y+x)
`define add_1(x)            (x == 4 ? 0 : x + 1)
`define add_2(x)            (x == 3 ? 0 : x == 4 ? 1 : x + 2)

module Chi (
    input   [1599:0] X_0, X_1,
    output  [1599:0] Y_0, Y_1
);

    wire   [63:0]   e_0[4:0][4:0], e_1[4:0][4:0], f_0[4:0][4:0], f_1[4:0][4:0];
    wire    [63:0]   a0b0[4:0][4:0], a0b1[4:0][4:0], a1b0[4:0][4:0], a1b1[4:0][4:0];
    genvar x, y;

    generate
      for(y=0; y<5; y=y+1)
        begin : L0
          for(x=0; x<5; x=x+1)
            begin : L1
              assign e_0[x][y] = X_0[`high_pos(x,y) : `low_pos(x,y)];
              assign e_1[x][y] = X_1[`high_pos(x,y) : `low_pos(x,y)];
            end
        end
    endgenerate

	generate
      for(y=0; y<5; y=y+1)
        begin : L5
          for(x=0; x<5; x=x+1)
            begin : L6
				assign a0b0[x][y] = e_0[x][y] ^ e_0[`add_2(x)][y] ^ (e_0[`add_1(x)][y] & e_0[`add_2(x)][y]);
				assign a0b1[x][y] = e_0[`add_1(x)][y] & e_1[`add_2(x)][y];
				assign a1b0[x][y] = e_1[`add_1(x)][y] & e_0[`add_2(x)][y];
				assign a1b1[x][y] = e_1[x][y] ^ e_1[`add_2(x)][y] ^ (e_1[`add_1(x)][y] & e_1[`add_2(x)][y]);
			  
				assign f_0[x][y] = a0b0[x][y] ^ a0b1[x][y];
				assign f_1[x][y] = a1b0[x][y] ^ a1b1[x][y];
            end
        end
    endgenerate 

    generate
      for(y=0; y<5; y=y+1)
        begin : L99
          for(x=0; x<5; x=x+1)
            begin : L100
              assign Y_0[`high_pos(x,y) : `low_pos(x,y)] = f_0[x][y];
              assign Y_1[`high_pos(x,y) : `low_pos(x,y)] = f_1[x][y];
            end
        end
    endgenerate

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Iota (
    input   [1599:0] X,
    input   [63:0]   C,
    output  [1599:0] Y
);

    assign Y = {(X[1599:1536] ^ C), X[1535:0]};

endmodule

`undef low_pos 
`undef high_pos 
`undef add_1 
`undef add_2 