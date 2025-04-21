`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Wuhan University
// Engineer: Kehao Yang
// 
// Create Date: 2025/03/09 20:31:16
// Design Name: SecSHA3_HW
// Module Name: nullfresh_keccakf1600
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


module nullfresh_keccakf1600(
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
    wire enable_rf, hsh_done, hsh_enable, hsh_reset;
    wire [1599:0] hsh_result1, hsh_result2;
    wire [1599:0] hash_message1, hash_message2;

    assign done = hsh_done;
    assign hsh_enable = go;
    assign hsh_reset = init | (~rst_n);
    assign enable_rf = hsh_done;
    assign result = squeeze ? (squeeze_indx ? hash_message2[31:0] : hash_message1[31:0]) : hash_message1[31:0];


    Keccak1600 hsh(
        .CLK(clk),
        .RESET(hsh_reset),
        .ENABLE(hsh_enable),
        .DONE(hsh_done),
        .MESSAGE1(hash_message1),
        .MESSAGE2(hash_message2),
        .RESULT1(hsh_result1),
        .RESULT2(hsh_result2) );
    registerfdre_nullfresh reg_1(
        .clk(clk),
        .rst_n(rst_n),
        .init(init),
        .enable(enable_rf),
        .absorb(absorb),
        .extend(extend),
        .squeeze(squeeze),
        .din(din_0),
        .d(hsh_result1),
        .q(hash_message1) );
    registerfdre_nullfresh reg_2(
        .clk(clk),
        .rst_n(rst_n),
        .init(init),
        .enable(enable_rf),
        .absorb(absorb),
        .extend(extend),
        .squeeze(squeeze),
        .din(din_1),
        .d(hsh_result2),
        .q(hash_message2) );

endmodule


module registerfdre_nullfresh (
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