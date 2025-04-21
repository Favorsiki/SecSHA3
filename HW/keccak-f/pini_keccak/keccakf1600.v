`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Wuhan University
// Engineer: Kehao Yang
// 
// Create Date: 2025/04/09 10:00:06
// Design Name: SecSHA3_HW
// Module Name: pini_keccak
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

module pini_keccakf1600 #(parameter ROUND_CHI_SIZE = 400) (
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
    localparam SBOX_NUM = ROUND_CHI_SIZE/5;
    localparam CHI_LATENCY = (320 / SBOX_NUM);

    reg wen_rf, shiftSignal;
    wire Chi_done;
    reg [63:0] iota_const;
    wire [10*SBOX_NUM-1 : 0] rand_data;
    //wire [5*SBOX_NUM-1 : 0] chiResult_0, chiResult_1;
    wire [5*SBOX_NUM-1 : 0] state_chi_0, state_chi_1;
    wire [1599:0] reg0_out, reg1_out, reg0_in , reg1_in;
    wire [1599:0] state_iota_0, state_iota_1;
    wire [1599:0] state_pi2chi_0, state_pi2chi_1;
    wire [1599:0] rcs0_y, rcs1_y, ircs0_x, ircs1_x;

    // Internal Signals
    wire RegLastRound, lasRound;
    wire InStChi, InStIotaThetaRhoPi, InStFinish;
    assign lasRound = (round_cnt == 5'd24);
    assign InStChi = (state == StChi);
    assign InStFinish = (state == StFinish);
    assign InStIotaThetaRhoPi = (state == StIotaThetaRhoPi);
    // assign RegLastRound = InStIotaThetaRhoPi && lasRound;
    // assign reg1_in = RegLastRound ? state_iota_1 : rcs1_y;
    assign reg0_in = InStIotaThetaRhoPi ? (lasRound ? state_iota_0 : rcs0_y) : ircs0_x;
    assign reg1_in = InStIotaThetaRhoPi ? (lasRound ? state_iota_1 : rcs1_y) : ircs1_x;

    // Generate Output
    assign result = squeeze ? (squeeze_indx ? reg1_out[31:0] : reg0_out[31:0]) : reg0_out[31:0];
    assign state_iota_0 = {reg0_out[1599:64], reg0_out[63:0] ^ iota_const};
    assign state_iota_1 = reg1_out;
    assign done = InStFinish;

    reg [2:0] state, next_state;
    reg [4:0] round_cnt;
    localparam StReset = 3'd0, StInit = 3'd1, StIotaThetaRhoPi = 3'd2;
    localparam StChi = 3'd3, StFinish = 3'd4;

    // ========================== FSM ============================
    always @(posedge clk) begin
        if (!rst_n) state <= 3'd0;
        else if (init) state <= 3'd1;
        else state <= next_state ;
    end 

    always @(*) case (state)
        StReset : next_state = init ? StInit : StReset;
        StInit  : next_state = go ? StIotaThetaRhoPi : StInit;
        StIotaThetaRhoPi : begin 
            if (round_cnt == 5'd24) next_state = StFinish;
            else  next_state = StChi;
        end 
        StChi :  next_state = Chi_done ? StIotaThetaRhoPi : StChi;
        StFinish : next_state = StInit;
        default : next_state = StReset;
    endcase

    // Shift the result of Chi sub-process into Registerfile
    // Set the chiShift signal of Registerfile
    wire chiShift;
    assign chiShift = InStChi && shiftSignal;
    always @(posedge clk) case (state)
        StIotaThetaRhoPi : shiftSignal <= 1'b0;
        StChi : shiftSignal <= ~shiftSignal;
        default : shiftSignal <= 1'b0;
    endcase

    // Set Write Enable signal of Registerfile
    always @(*) case (state)
        StIotaThetaRhoPi : wen_rf = 1;
        StChi : wen_rf = Chi_done;
        default : wen_rf = 0;
    endcase

    // Generate Round Const
    reg [8:0] Chi_cnt;
    assign Chi_done = (Chi_cnt == CHI_LATENCY) && InStChi;
    always @(posedge clk) case (state) 
        StIotaThetaRhoPi : begin 
            round_cnt <= round_cnt;
            Chi_cnt <= 9'd0;
        end 
        StChi : begin 
            round_cnt <= Chi_done ? round_cnt + 1 : round_cnt; 
            Chi_cnt <= Chi_cnt + chiShift;
        end
        default : begin 
            round_cnt <= 5'd0;
            Chi_cnt <= 9'd0;
        end 
    endcase

    always @(*) case (round_cnt)
        5'd01:   iota_const = 64'h0000000000000001;
        5'd02:   iota_const = 64'h0000000000008082;
        5'd03:   iota_const = 64'h800000000000808A;
        5'd04:   iota_const = 64'h8000000080008000;
        5'd05:   iota_const = 64'h000000000000808B;
        5'd06:   iota_const = 64'h0000000080000001;
        5'd07:   iota_const = 64'h8000000080008081;
        5'd08:   iota_const = 64'h8000000000008009;
        5'd09:   iota_const = 64'h000000000000008A;
        5'd10:   iota_const = 64'h0000000000000088;
        5'd11:   iota_const = 64'h0000000080008009;
        5'd12:   iota_const = 64'h000000008000000A;
        5'd13:   iota_const = 64'h000000008000808B;
        5'd14:   iota_const = 64'h800000000000008B;
        5'd15:   iota_const = 64'h8000000000008089;
        5'd16:   iota_const = 64'h8000000000008003;
        5'd17:   iota_const = 64'h8000000000008002;
        5'd18:   iota_const = 64'h8000000000000080;
        5'd19:   iota_const = 64'h000000000000800A;
        5'd20:   iota_const = 64'h800000008000000A;
        5'd21:   iota_const = 64'h8000000080008081;
        5'd22:   iota_const = 64'h8000000000008080;
        5'd23:   iota_const = 64'h0000000080000001;
        5'd24:   iota_const = 64'h8000000080008008;
        default: iota_const = 64'h0000000000000000;
    endcase
    
    generate
        if ((1600 % ROUND_CHI_SIZE != 0) || (ROUND_CHI_SIZE % 5 != 0)) begin
            // Simulation Assertion
            $error("Error: ROUND_CHI_SIZE value is inappropriate! ROUND_CHI_SIZE = %d > 1600", ROUND_CHI_SIZE);
        end
    endgenerate

    prng #(.OUTLENGTH(10*SBOX_NUM)) randGen(.clk(clk), .rst_n(rst_n), .ren(chiShift), .dout(rand_data));
    registerfdre_pini #(.SBOX_NUM(SBOX_NUM)) reg_0 (
        .clk(clk),
        .rst_n(rst_n),
        .init(init),
        .enable(wen_rf),
        .absorb(absorb),
        .extend(extend),
        .squeeze(squeeze),
        .chiShift(chiShift),
        .chiResult(state_chi_0),
        .din(din_0),
        .d(reg0_in),
        .q(reg0_out) );
    registerfdre_pini #(.SBOX_NUM(SBOX_NUM)) reg_1 (
        .clk(clk),
        .rst_n(rst_n),
        .init(init),
        .enable(wen_rf),
        .absorb(absorb),
        .extend(extend),
        .squeeze(squeeze),
        .chiShift(chiShift),
        .chiResult(state_chi_1),
        .din(din_1),
        .d(reg1_in),
        .q(reg1_out) );
    keccak_theta_rho_pi_pini theta_rho_pi_0 (
        .state_round_in_i(state_iota_0),
        .state_pi2chi_o(state_pi2chi_0)
    );
    keccak_theta_rho_pi_pini theta_rho_pi_1 (
        .state_round_in_i(state_iota_1),
        .state_pi2chi_o(state_pi2chi_1)
    );
    keccak_chi_pini #(.SBOX_NUM(SBOX_NUM)) chi (
        .clk(clk),
        .din_0(reg0_out[5*SBOX_NUM-1 : 0]),
        .din_1(reg1_out[5*SBOX_NUM-1 : 0]),
        .rand_data(rand_data),
        .dout_0(state_chi_0),
        .dout_1(state_chi_1) );
    ReOrderChiSquence rcs0(
        .orgin(state_pi2chi_0),
        .reorder(rcs0_y) );
    ReOrderChiSquence rcs1(
        .orgin(state_pi2chi_1),
        .reorder(rcs1_y) );
    InvReOrderChiSquence ircs0(
        .reorder(reg0_out),
        .orgin(ircs0_x) );
    InvReOrderChiSquence ircs1(
        .reorder(reg1_out),
        .orgin(ircs1_x) );
        
endmodule


module registerfdre_pini #(parameter SBOX_NUM = 320) (
    input           clk,
    input           rst_n,
    input           init,
    input           enable,
    input           absorb,
    input           extend,
    input           squeeze,
    input           chiShift,
    input   [5*SBOX_NUM-1 : 0] chiResult,
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
        else if (chiShift) begin
            if (SBOX_NUM >= 320)
                q_buf <= chiResult;  // Full state update
            else
                q_buf <= {chiResult, q_buf[1599:5*SBOX_NUM]};  // Partial update
        end 
    end
    generate
        if (5*SBOX_NUM > 1600) begin
            // Simulation Assertion
            $error("ASSERTION FAILED: SBOX_NUM = %d > 320", SBOX_NUM);
            // Synthesis  Assertion
            wire [1599:0] ASSERT_FAILED = chiResult[1599:0]; 
            /*
            * ASSERTION FAILED: 
            * SBOX_NUM (%d) exceeds maximum allowed (320).
            */
        end
    endgenerate
endmodule

module keccak_theta_rho_pi_pini(
    input [1599:0] state_round_in_i,
    input [1599:0] state_pi2chi_o
);
    wire [1599:0] A, B;
    wire    [319:0] theta_sums;
    // theta step
    assign theta_sums = state_round_in_i[1599:1280] ^ state_round_in_i[1279:960] ^ state_round_in_i[959:640] ^ state_round_in_i[639:320] ^ state_round_in_i[319:0];
    genvar i;
    generate
        for (i = 0; i < 5; i = i + 1)
            begin               
                assign A[320*i+63  : 320*i+0]   = state_round_in_i[320*i+63  : 320*i+0]   ^ theta_sums[319 : 256] ^ {theta_sums[126 : 64],  theta_sums[127]};
                assign A[320*i+127 : 320*i+64]  = state_round_in_i[320*i+127 : 320*i+64]  ^ theta_sums[63  : 0]   ^ {theta_sums[190 : 128], theta_sums[191]};
                assign A[320*i+191 : 320*i+128] = state_round_in_i[320*i+191 : 320*i+128] ^ theta_sums[127 : 64]  ^ {theta_sums[254 : 192], theta_sums[255]};
                assign A[320*i+255 : 320*i+192] = state_round_in_i[320*i+255 : 320*i+192] ^ theta_sums[191 : 128] ^ {theta_sums[318 : 256], theta_sums[319]};
                assign A[320*i+319 : 320*i+256] = state_round_in_i[320*i+319 : 320*i+256] ^ theta_sums[255 : 192] ^ {theta_sums[62  : 0],   theta_sums[63]};
            end        
    endgenerate

    // rho step
    assign B[  63 :    0] = {A[  63 :    0]};
    assign B[ 127 :   64] = {A[ 126 :   64], A[ 127]};
    assign B[ 191 :  128] = {A[ 129 :  128], A[ 191 :  130]};
    assign B[ 255 :  192] = {A[ 227 :  192], A[ 255 :  228]};
    assign B[ 319 :  256] = {A[ 292 :  256], A[ 319 :  293]};
    assign B[ 383 :  320] = {A[ 347 :  320], A[ 383 :  348]};
    assign B[ 447 :  384] = {A[ 403 :  384], A[ 447 :  404]};
    assign B[ 511 :  448] = {A[ 505 :  448], A[ 511 :  506]};
    assign B[ 575 :  512] = {A[ 520 :  512], A[ 575 :  521]};
    assign B[ 639 :  576] = {A[ 619 :  576], A[ 639 :  620]};
    assign B[ 703 :  640] = {A[ 700 :  640], A[ 703 :  701]};
    assign B[ 767 :  704] = {A[ 757 :  704], A[ 767 :  758]};
    assign B[ 831 :  768] = {A[ 788 :  768], A[ 831 :  789]};
    assign B[ 895 :  832] = {A[ 870 :  832], A[ 895 :  871]};
    assign B[ 959 :  896] = {A[ 920 :  896], A[ 959 :  921]};   
    assign B[1023 :  960] = {A[ 982 :  960], A[1023 :  983]};
    assign B[1087 : 1024] = {A[1042 : 1024], A[1087 : 1043]};
    assign B[1151 : 1088] = {A[1136 : 1088], A[1151 : 1137]};
    assign B[1215 : 1152] = {A[1194 : 1152], A[1215 : 1195]};
    assign B[1279 : 1216] = {A[1271 : 1216], A[1279 : 1272]};   
    assign B[1343 : 1280] = {A[1325 : 1280], A[1343 : 1326]};
    assign B[1407 : 1344] = {A[1405 : 1344], A[1407 : 1406]};
    assign B[1471 : 1408] = {A[1410 : 1408], A[1471 : 1411]};
    assign B[1535 : 1472] = {A[1479 : 1472], A[1535 : 1480]};
    assign B[1599 : 1536] = {A[1585 : 1536], A[1599 : 1586]}; 

    // pi step
    assign state_pi2chi_o[  63 :   0] = B[  63 :    0];
    assign state_pi2chi_o[ 127 :  64] = B[ 447 :  384];
    assign state_pi2chi_o[ 191 : 128] = B[ 831 :  768];
    assign state_pi2chi_o[ 255 : 192] = B[1215 : 1152];
    assign state_pi2chi_o[ 319 : 256] = B[1599 : 1536];
    assign state_pi2chi_o[ 383 : 320] = B[ 255 :  192];
    assign state_pi2chi_o[ 447 : 384] = B[ 639 :  576];
    assign state_pi2chi_o[ 511 : 448] = B[ 703 :  640];
    assign state_pi2chi_o[ 575 : 512] = B[1087 : 1024];
    assign state_pi2chi_o[ 639 : 576] = B[1471 : 1408];
    assign state_pi2chi_o[ 703 : 640] = B[ 127 :   64];
    assign state_pi2chi_o[ 767 : 704] = B[ 511 :  448];
    assign state_pi2chi_o[ 831 : 768] = B[ 895 :  832];
    assign state_pi2chi_o[ 895 : 832] = B[1279 : 1216];
    assign state_pi2chi_o[ 959 : 896] = B[1343 : 1280];  
    assign state_pi2chi_o[1023 :  960] = B[ 319 :  256];
    assign state_pi2chi_o[1087 : 1024] = B[ 383 :  320];
    assign state_pi2chi_o[1151 : 1088] = B[ 767 :  704];
    assign state_pi2chi_o[1215 : 1152] = B[1151 : 1088];
    assign state_pi2chi_o[1279 : 1216] = B[1535 : 1472];   
    assign state_pi2chi_o[1343 : 1280] = B[ 191 :  128];
    assign state_pi2chi_o[1407 : 1344] = B[ 575 :  512];
    assign state_pi2chi_o[1471 : 1408] = B[ 959 :  896];
    assign state_pi2chi_o[1535 : 1472] = B[1023 :  960];
    assign state_pi2chi_o[1599 : 1536] = B[1407 : 1344]; 
endmodule


module keccak_chi_pini #(parameter SBOX_NUM = 320) (
    input clk, 
    input [5*SBOX_NUM-1  : 0] din_0, din_1,
    input [10*SBOX_NUM-1 : 0] rand_data,
    output [5*SBOX_NUM-1 : 0] dout_0, dout_1
);
    genvar i;
    generate for (i = 0; i < SBOX_NUM; i = i + 1) begin : k_sbox
        keccak_sbox_pini inst(
            .clk(clk),
            .din_share({din_0[i*5+4 : i*5], din_1[i*5+4 : i*5]}),
            .rand_data(rand_data[i*10+9 : i*10]),
            .dout_share({dout_0[i*5+4 : i*5], dout_1[i*5+4 : i*5]})
        );
    end
    endgenerate
endmodule 

