`timescale 1ns / 1ps

module keccak_pi #(
    parameter SLICES_PARALLEL = 1
)(
    input wire ClkxCI,
    input wire RstxRBI,
    input wire[25*SLICES_PARALLEL-1 : 0] SlicesxDI,
    output reg[25*SLICES_PARALLEL-1 : 0] SlicesxDO
);

localparam SP = SLICES_PARALLEL;

function integer Idx(input integer x, input integer y);
    Idx = (5*x+y)*SLICES_PARALLEL;
endfunction

always @(*) begin : RHO_PI_COMB
    reg[25*SP-1:0] A;
    reg[25*SP-1:0] B;
    integer x, y;

    A = SlicesxDI;
    for(x=0; x < 5; x=x+1) begin
        for(y=0; y < 5; y=y+1) begin
            B[Idx(y,(2*x+3*y)%5) +: SP] = A[Idx(x,y) +: SP];
        end
    end
    SlicesxDO = B;
end



endmodule
