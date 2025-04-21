`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Wuhan University
// Engineer: Kehao Yang
// 
// Create Date: 2025/03/09 19:20:17
// Design Name: SecSHA3_HW
// Module Name: dom_keccakf1600
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

module dom_keccakf1600 #(parameter ROUND_CHI_SIZE = 400) (
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


endmodule