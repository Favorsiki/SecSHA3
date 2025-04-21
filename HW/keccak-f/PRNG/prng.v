`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Wuhan University
// Engineer: Kehao Yang
// 
// Create Date: 2025/02/19 10:37:41
// Design Name: SecSHA3_HW
// Module Name: prng
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


// module prng #(
//     parameter OUTLENGTH = 64;
// ) (
//     input clk, 
//     input rst,
//     input ren,
//     output reg [OUTLENGTH-1:0] dout
// );    
//     // 计算�?要的PRNG实例数量
//     localparam NUM_PRNG = (OUTLENGTH + 31) / 32;  // 向上取整
    
//     // 生成NUM_PRNG�?32位PRNG输出
//     reg [32*NUM_PRNG-1:0] sftreg;
    
//     // 实例化NUM_PRNG个PRNG模块
//     genvar i, j;
//     always @(posedge clk) begin
//         if (rst) begin generate
//             for (i = 0; i < NUM_PRNG; i = i + 1) begin : RESET 
//                 sftreg[32*i +: 32] <= 32'h9973CD2D;
//             end 
//         endgenerate end else begin generate
//             sftreg[31:0] <= {sftreg[31]^sftreg[28]^sftreg[0], sftreg[31:1]};
//             for (j = 1 ; j < NUM_PRNG; j = j + 1) begin : RESET 
//                 sftreg[32*j +: 32] <= {sftreg[32*j+31]^sftreg[32*j+28]^sftreg[32*j]^sftreg[32*j-1], sftreg[32*j+31:32*j+1]};
//             end 
//         endgenerate end 
//     end 

//     always @(posedge clk) begin
//         if (rst) dout <= 0;
//         else if (en) dout <= sftreg[OUTLENGTH-1:0];
//     end 

// endmodule


module prng #(
    parameter OUTLENGTH = 63
) (
    input clk, 
    input rst_n,
    input ren,  
    output reg [OUTLENGTH-1:0] dout
);    
    localparam NUM_PRNG = (OUTLENGTH + 31) / 32; 
    
    reg [32*NUM_PRNG-1:0] sftreg;
    

    always @(posedge clk) begin
        if (!rst_n) sftreg[31:0] <= 32'hE4106D0C;
        else sftreg[31:0] <= {sftreg[31]^sftreg[28]^sftreg[0], sftreg[31:1]};
    end
    genvar i;
    generate 
        for (i = 1; i < NUM_PRNG; i = i + 1) begin
            always @(posedge clk) begin
                if (!rst_n) sftreg[32*i+31:32*i] <= 32'h9973CD2D;
                else sftreg[32*i + 31: 32*i] <= {
                    sftreg[32*i+31]^sftreg[32*i+28]^sftreg[32*i]^sftreg[32*i-1], 
                    sftreg[32*i+31:32*i+1]
                };
            end 
        end 
    endgenerate
 
    always @(posedge clk) begin
        if (!rst_n) dout <= 0;
        else if (ren)  dout <= sftreg[OUTLENGTH-1:0];
    end
endmodule