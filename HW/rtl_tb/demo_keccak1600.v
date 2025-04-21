`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Wuhan University
// Engineer: Sinuo Zhang
// 
// Create Date: 2025/01/09 14:00:06
// Design Name: SecSHA3_HW
// Module Name: demo_keccakf1600
// Project Name: SecSHA3
// Target Devices: Zedboard(xc7z020clg484-1)
// Tool Versions: Vivado 2022.1
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module demo_keccakf1600 (
    input           clk,
    input           rst_n,
    input           init,
    input           go,
    input           absorb,
    input           extend,
    input           squeeze,
    input           squeeze_indx,
    input    [31:0] din_0, din_1,
    output          done,
    output   [31:0] result
);
    wire    rstn_rf, enable_rf, done_intern;
    wire    [63:0]   iota_const;
    wire    [1599:0] reorder_out_0, reorder_out_1, rand_data;
    assign done = done_intern;
    assign result = squeeze ? (squeeze_indx ? reorder_out_1[31:0] : reorder_out_0[31:0]) : reorder_out_0[31:0];

    round rnd(.clk(clk), .rst_n(rstn_rf), .init(init), .enable(enable_rf), .squeeze(squeeze), .squeeze_indx(squeeze_indx),.absorb(absorb), .extend(extend), .iota_const(iota_const), .din_0(din_0), .din_1(din_1), .output_0(reorder_out_0), .output_1(reorder_out_1), .rand_data(rand_data));
    statemachine fsm(.clk(clk), .rst_n(rst_n), .init(init), .go(go), .done(done_intern), .rstn_rf(rstn_rf), .enable_rf(enable_rf), .iota_const(iota_const));
    prng #(.OUTLENGTH(1600)) randGen_1600(.clk(clk), .rst_n(rst_n), .ren(enable_rf), .dout(rand_data));
endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module round (
    input           clk,
    input           rst_n,
    input           init,
    input           enable,
    input           absorb,
    input           extend,
    input           squeeze,
    input           squeeze_indx, 
    input  [63:0]   iota_const,
    input  [31:0]   din_0, din_1,
    input  [1599:0] rand_data,
    output [1599:0] output_0, output_1
);

    wire [1599:0] state0, state1;
    wire [1599:0] tmp10, tmp11;
    wire [1599:0] tmp20, tmp21;
    wire [1599:0] tmp30, tmp31;
    wire [1599:0] tmp40, tmp41;

    assign output_0 = state0;
    assign output_1 = state1;

    wire squeeze_0, squeeze_1;
    assign squeeze_0 = (squeeze && (squeeze_indx == 1'b0));
    assign squeeze_1 = (squeeze && (squeeze_indx == 1'b1));

    registerfdre reg_0(.clk(clk), .rst_n(rst_n), .init(init), .enable(enable), .squeeze(squeeze_0), .absorb(absorb), .extend(extend), .din(din_0), .d(tmp40), .q(state0));
    registerfdre reg_1(.clk(clk), .rst_n(rst_n), .init(init), .enable(enable), .squeeze(squeeze_1), .absorb(absorb), .extend(extend), .din(din_1), .d(tmp41), .q(state1));
    theta   t0(.x(state0),   .y(tmp10));
    theta   t1(.x(state1),   .y(tmp11));
    rho     r0(.x(tmp10),  .y(tmp20));
    rho     r1(.x(tmp11),  .y(tmp21));
    pi      p0(.x(tmp20),  .y(tmp30));
    pi      p1(.x(tmp21),  .y(tmp31));
    chi_iota ci(.clk(clk), .rst_n(rst_n), .I_iota_const(iota_const), .I_x0(tmp30), .I_x1(tmp31), .I_r(rand_data), .O_z0(tmp40), .O_z1(tmp41)); 
endmodule
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module registerfdre (
    input           clk,
    input           rst_n,
    input           init,
    input           enable,
    input           absorb,
    input           extend,
    input           squeeze,
    input   [31:0]  din,
    input   [1599:0] d,
    output  [1599:0] q
);

    wire    [31:0]  din_mux;
    reg     [1599:0] q_buf;

    assign q = q_buf;
    assign din_mux = absorb ? q_buf[31:0] ^ din : q_buf[31:0];

    always @(posedge clk) begin
        if (!rst_n) q_buf <= 0;
        else if (init) q_buf <= 0;
        else if (squeeze | extend | absorb) q_buf <= {din_mux, q_buf[1599:32]};
        else if (enable) q_buf <= d;
    end

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module statemachine (
    input           clk,
    input           rst_n,
    input           init,
    input           go,
    output  reg     done,
    output  reg     rstn_rf,
    output  reg     enable_rf,
    output reg [63:0] iota_const
);
    `define     s_reset  3'h0
    `define     s_init   3'h1
    `define     s_round1 3'h2
    `define     s_round2 3'h3
    `define     s_done   3'h4

    reg     [2:0]   state, next_state;
    reg     [7:0]   lfsr;
    reg             reset_lfsr, enable_lfsr;

    always @(posedge clk) begin
        if (reset_lfsr) lfsr <= 8'h1;
        else if (enable_lfsr) lfsr <= {lfsr[6:0], (lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3])};
        else lfsr <= lfsr;
    end     

    always @(lfsr) begin 
        case(lfsr)
            8'h01  : iota_const <= 64'h0000000000000001;
            8'h02  : iota_const <= 64'h0000000000008082;
            8'h04  : iota_const <= 64'h800000000000808a;
            8'h08  : iota_const <= 64'h8000000080008000;
            8'h11  : iota_const <= 64'h000000000000808b;
            8'h23  : iota_const <= 64'h0000000080000001;
            8'h47  : iota_const <= 64'h8000000080008081;
            8'h8e  : iota_const <= 64'h8000000000008009;
            8'h1c  : iota_const <= 64'h000000000000008a;
            8'h38  : iota_const <= 64'h0000000000000088;
            8'h71  : iota_const <= 64'h0000000080008009;
            8'he2  : iota_const <= 64'h000000008000000a;
            8'hc4  : iota_const <= 64'h000000008000808b;
            8'h89  : iota_const <= 64'h800000000000008b;
            8'h12  : iota_const <= 64'h8000000000008089;
            8'h25  : iota_const <= 64'h8000000000008003;
            8'h4b  : iota_const <= 64'h8000000000008002;
            8'h97  : iota_const <= 64'h8000000000000080;
            8'h2e  : iota_const <= 64'h000000000000800a;
            8'h5c  : iota_const <= 64'h800000008000000a;
            8'hb8  : iota_const <= 64'h8000000080008081;
            8'h70  : iota_const <= 64'h8000000000008080;
            8'he0  : iota_const <= 64'h0000000080000001;
            8'hc0  : iota_const <= 64'h8000000080008008;             
            default: iota_const <= 64'h0000000000000000;
        endcase
    end 

    always @(posedge clk) begin
        if (!rst_n)  state <= `s_reset;
        else        state <= next_state;
    end 

    always @(state, init, go, lfsr) begin
        rstn_rf <= 1;
        enable_rf <= 0;
        reset_lfsr <= 0;
        enable_lfsr <= 0;
        done <= 0;
        next_state <= state;
        
        case (state)
            `s_reset : begin 
                rstn_rf <= 0;
                reset_lfsr <= 1;
                if (init) next_state <= `s_init;
            end 
            `s_init : begin
               enable_rf <= 0;
               enable_lfsr <= 0;
               done <= 0; 
               if (go) next_state <= `s_round1;
            end
            `s_round1 : begin
                enable_rf <= 0;
                enable_lfsr <= 0;
                next_state <= `s_round2;
            end
            `s_round2 : begin
                enable_rf <= 1;
                enable_lfsr <= 1;
                if (lfsr == 8'hc0) next_state <= `s_done;
                else next_state <= `s_round1;
            end
            `s_done : begin
                done <= 1;
                reset_lfsr <= 1;
                next_state <= `s_init;
            end 
        endcase
    end 

`ifdef DEBUG_ILA
    ila_2 ILA_keccak_ctrl(
        .clk(clk),
        .probe0({state, next_state}), // 6
        .probe1({rst_n, init, go, done, rstn_rf, enable_rf}), // 6
        .probe2({iota_const}), // 64
        .probe3({lfsr, reset_lfsr, enable_lfsr}) // 10
    );
`endif
endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module theta (
    input   [1599:0] x,
    output  [1599:0] y
);
    wire    [319:0] sums;
    assign sums = x[1599:1280] ^ x[1279:960] ^ x[959:640] ^ x[639:320] ^ x[319:0];

    genvar i;
    generate
        for (i = 0; i < 5; i = i + 1)
            begin               
                assign y[320*i+63  : 320*i+0]   = x[320*i+63  : 320*i+0]   ^ sums[319 : 256] ^ {sums[126 : 64],  sums[127]};
                assign y[320*i+127 : 320*i+64]  = x[320*i+127 : 320*i+64]  ^ sums[63  : 0]   ^ {sums[190 : 128], sums[191]};
                assign y[320*i+191 : 320*i+128] = x[320*i+191 : 320*i+128] ^ sums[127 : 64]  ^ {sums[254 : 192], sums[255]};
                assign y[320*i+255 : 320*i+192] = x[320*i+255 : 320*i+192] ^ sums[191 : 128] ^ {sums[318 : 256], sums[319]};
                assign y[320*i+319 : 320*i+256] = x[320*i+319 : 320*i+256] ^ sums[255 : 192] ^ {sums[62  : 0],   sums[63]};
            end        
    endgenerate

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module rho (
    input   [1599:0] x,
    output  [1599:0] y
);
    // Y = 0
    assign y[  63 :    0] = {x[  63 :    0]};
    assign y[ 127 :   64] = {x[ 126 :   64], x[ 127]};
    assign y[ 191 :  128] = {x[ 129 :  128], x[ 191 :  130]};
    assign y[ 255 :  192] = {x[ 227 :  192], x[ 255 :  228]};
    assign y[ 319 :  256] = {x[ 292 :  256], x[ 319 :  293]};
    
    // Y = 1
    assign y[ 383 :  320] = {x[ 347 :  320], x[ 383 :  348]};
    assign y[ 447 :  384] = {x[ 403 :  384], x[ 447 :  404]};
    assign y[ 511 :  448] = {x[ 505 :  448], x[ 511 :  506]};
    assign y[ 575 :  512] = {x[ 520 :  512], x[ 575 :  521]};
    assign y[ 639 :  576] = {x[ 619 :  576], x[ 639 :  620]};
    
    // Y = 2
    assign y[ 703 :  640] = {x[ 700 :  640], x[ 703 :  701]};
    assign y[ 767 :  704] = {x[ 757 :  704], x[ 767 :  758]};
    assign y[ 831 :  768] = {x[ 788 :  768], x[ 831 :  789]};
    assign y[ 895 :  832] = {x[ 870 :  832], x[ 895 :  871]};
    assign y[ 959 :  896] = {x[ 920 :  896], x[ 959 :  921]};   

    // Y = 3
    assign y[1023 :  960] = {x[ 982 :  960], x[1023 :  983]};
    assign y[1087 : 1024] = {x[1042 : 1024], x[1087 : 1043]};
    assign y[1151 : 1088] = {x[1136 : 1088], x[1151 : 1137]};
    assign y[1215 : 1152] = {x[1194 : 1152], x[1215 : 1195]};
    assign y[1279 : 1216] = {x[1271 : 1216], x[1279 : 1272]};   
    
    // Y = 4
    assign y[1343 : 1280] = {x[1325 : 1280], x[1343 : 1326]};
    assign y[1407 : 1344] = {x[1405 : 1344], x[1407 : 1406]};
    assign y[1471 : 1408] = {x[1410 : 1408], x[1471 : 1411]};
    assign y[1535 : 1472] = {x[1479 : 1472], x[1535 : 1480]};
    assign y[1599 : 1536] = {x[1585 : 1536], x[1599 : 1586]}; 

endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module pi (
    input   [1599 : 0] x,
    output  [1599 : 0] y
);
    // Y = 0
    assign y[  63 :   0] = x[  63 :    0];
    assign y[ 127 :  64] = x[ 447 :  384];
    assign y[ 191 : 128] = x[ 831 :  768];
    assign y[ 255 : 192] = x[1215 : 1152];
    assign y[ 319 : 256] = x[1599 : 1536];
    
    // Y = 1
    assign y[ 383 : 320] = x[ 255 :  192];
    assign y[ 447 : 384] = x[ 639 :  576];
    assign y[ 511 : 448] = x[ 703 :  640];
    assign y[ 575 : 512] = x[1087 : 1024];
    assign y[ 639 : 576] = x[1471 : 1408];

    // Y = 2    
    assign y[ 703 : 640] = x[ 127 :   64];
    assign y[ 767 : 704] = x[ 511 :  448];
    assign y[ 831 : 768] = x[ 895 :  832];
    assign y[ 895 : 832] = x[1279 : 1216];
    assign y[ 959 : 896] = x[1343 : 1280];   

    // Y = 3
    assign y[1023 :  960] = x[ 319 :  256];
    assign y[1087 : 1024] = x[ 383 :  320];
    assign y[1151 : 1088] = x[ 767 :  704];
    assign y[1215 : 1152] = x[1151 : 1088];
    assign y[1279 : 1216] = x[1535 : 1472];   
 
    // Y = 4   
    assign y[1343 : 1280] = x[ 191 :  128];
    assign y[1407 : 1344] = x[ 575 :  512];
    assign y[1471 : 1408] = x[ 959 :  896];
    assign y[1535 : 1472] = x[1023 :  960];
    assign y[1599 : 1536] = x[1407 : 1344]; 
    
endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`define x1 (x0 == 4 ? 0 : x0 + 1)
`define x2 (x0 == 3 ? 0 : (x0 == 4 ? 1 : x0 + 2))
`define Idx(x,y) ((5 * y + x) * 64)
// function integer Idx(input integer x, input integer y);
//     Idx = (5 * y + x) * 64; // (5 * y + x) * 64
// endfunction

module chi_iota (
    input clk, rst_n,
    input [1599:0] I_x0, I_x1,
    input [1599:0] I_r,
    input [63:0] I_iota_const,
    output [1599:0] O_z0, O_z1
);

    wire [1599:0] FFxDN00, FFxDN01, FFxDN10, FFxDN11;
    wire [1599:0] result0, result1;

genvar x0, y;
generate
    for (x0 = 0; x0 < 5; x0 = x0 + 1) begin
        // Chi
        for (y = 0; y < 5; y = y + 1) begin
            assign FFxDN00[`Idx(x0,y)+:64] = I_x0[`Idx(x0,y)+:64] ^ (~I_x0[`Idx(`x1,y)+:64] & I_x0[`Idx(`x2,y)+:64]);
            assign FFxDN11[`Idx(x0,y)+:64] = I_x1[`Idx(x0,y)+:64] ^ (~I_x1[`Idx(`x1,y)+:64] & I_x1[`Idx(`x2,y)+:64]);
            assign FFxDN01[`Idx(x0,y)+:64] = (I_x0[`Idx(`x1,y)+:64] & I_x1[`Idx(`x2,y)+:64]) ^ I_r[`Idx(x0,y)+:64];
            assign FFxDN10[`Idx(x0,y)+:64] = (I_x1[`Idx(`x1,y)+:64] & I_x0[`Idx(`x2,y)+:64]) ^ I_r[`Idx(x0,y)+:64];
        end
    end
endgenerate
	assign result0 = FFxDN00 ^ FFxDN01;
	assign result1 = FFxDN10 ^ FFxDN11;

// Iota
assign O_z0 = {result0[1599:64], result0[63:0] ^ I_iota_const};
assign O_z1 = result1;

endmodule