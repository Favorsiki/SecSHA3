`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Wuhan University
// Engineer: Kehao Yang
// 
// Create Date: 2025/03/09 10:31:21
// Design Name: SecSHA3_HW
// Module Name: keccak_sbox
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

/*
    dout[0] = din[0] ^ (~din[1]) & din[2]
    dout[1] = din[1] ^ (~din[2]) & din[3]
    dout[2] = din[2] ^ (~din[3]) & din[4]
    dout[3] = din[3] ^ (~din[4]) & din[0]
    dout[4] = din[4] ^ (~din[0]) & din[1]
*/


module keccak_sbox_pini #(
    parameter security_order = 1
) (
    input clk, 
    input [5*(security_order+1)-1:0] din_share,
    input [10*(((security_order + 1) * security_order) / 2) - 1 :0] rand_data,
    output [5*(security_order+1)-1:0] dout_share
);
    localparam rand_bitlen = 2*(((security_order + 1) * security_order) / 2);

    wire [rand_bitlen - 1 :0] r0, r1, r2, r3, r4;
    wire [security_order : 0] c0, c1, c2, c3, c4;
    wire [security_order : 0] din0, din1, din2, din3, din4;
    wire [security_order : 0] dout0, dout1, dout2, dout3, dout4;
    wire [security_order : 0] inv_din0, inv_din1, inv_din2, inv_din3, inv_din4;

    genvar i;
    generate
        for (i = 0; i <= security_order; i = i + 1) begin
            assign din0[i] = din_share[5*i];
            assign din1[i] = din_share[5*i+1];
            assign din2[i] = din_share[5*i+2];
            assign din3[i] = din_share[5*i+3];
            assign din4[i] = din_share[5*i+4];
        end 
        for (i = 0; i <= security_order; i = i + 1) begin
            assign dout_share[5*i+0] = dout0[i];
            assign dout_share[5*i+1] = dout1[i];
            assign dout_share[5*i+2] = dout2[i];
            assign dout_share[5*i+3] = dout3[i];
            assign dout_share[5*i+4] = dout4[i];
        end 
    endgenerate

    assign inv_din0 = {din0[security_order : 1], ~din0[0]};
    assign inv_din1 = {din1[security_order : 1], ~din1[0]};
    assign inv_din2 = {din2[security_order : 1], ~din2[0]};
    assign inv_din3 = {din3[security_order : 1], ~din3[0]};
    assign inv_din4 = {din4[security_order : 1], ~din4[0]};
    assign r0 = rand_data[1*rand_bitlen-1 :  0];
    assign r1 = rand_data[2*rand_bitlen-1 : 1*rand_bitlen];
    assign r2 = rand_data[3*rand_bitlen-1 : 2*rand_bitlen];
    assign r3 = rand_data[4*rand_bitlen-1 : 3*rand_bitlen];
    assign r4 = rand_data[5*rand_bitlen-1 : 4*rand_bitlen];

    assign dout0 = c0 ^ din0;
    assign dout1 = c1 ^ din1;
    assign dout2 = c2 ^ din2;
    assign dout3 = c3 ^ din3;
    assign dout4 = c4 ^ din4;

    and_HPC3 #(.security_order(security_order)) and0(.clk(clk), .a(inv_din1), .b(din2), .r(r0), .c(c0));
    and_HPC3 #(.security_order(security_order)) and1(.clk(clk), .a(inv_din2), .b(din3), .r(r1), .c(c1));
    and_HPC3 #(.security_order(security_order)) and2(.clk(clk), .a(inv_din3), .b(din4), .r(r2), .c(c2));
    and_HPC3 #(.security_order(security_order)) and3(.clk(clk), .a(inv_din4), .b(din0), .r(r3), .c(c3));
    and_HPC3 #(.security_order(security_order)) and4(.clk(clk), .a(inv_din0), .b(din1), .r(r4), .c(c4));

endmodule