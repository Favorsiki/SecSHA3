`timescale 1ns/1ns

module keccak_rhopi #(
    parameter W = 16
)(
    input wire[25*W-1:0] StatexDI,
    output reg[25*W-1:0] StatexDO
);

function integer Idx(input integer x, input integer y);
    Idx = (5*x+y)*W;
endfunction

localparam [0:25*8-1] ROTATION_OFFSETS = {
    8'd00, 8'd36, 8'd03, 8'd41, 8'd18,
    8'd01, 8'd44, 8'd10, 8'd45, 8'd02,
    8'd62, 8'd06, 8'd43, 8'd15, 8'd61,
    8'd28, 8'd55, 8'd25, 8'd21, 8'd56,
    8'd27, 8'd20, 8'd39, 8'd08, 8'd14
};

reg[25*W-1:0] RHO;
always @(*) begin : RHO_PI_COMB
    reg[25*W-1:0] A;
    reg[25*W-1:0] B;
    integer x, y;

    A = StatexDI;
    for(x=0; x < 5; x=x+1) begin
        for(y=0; y < 5; y=y+1) begin
            RHO[Idx(x,y) +: W] = {2{A[Idx(x,y) +: W]}} >> (W - (ROTATION_OFFSETS[(5*x+y)*8 +: 8] % W));
            B[Idx(y,(2*x+3*y)%5) +: W] = RHO[Idx(x,y) +: W];
        end
    end
    StatexDO = B;
end

endmodule
