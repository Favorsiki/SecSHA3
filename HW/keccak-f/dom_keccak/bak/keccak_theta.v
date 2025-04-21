`timescale 1ns/1ns

module keccak_theta #(
    parameter W = 16,
    parameter SLICES_PARALLEL = 1
)(
    input wire ClkxCI,
    input wire RstxRBI,
    input wire RstSyncxRI,
    input wire EnablexSI,
    input wire[25*SLICES_PARALLEL-1:0] SlicesxDI,
    input wire[24:0] SliceZ0xDI,
    output reg[25*SLICES_PARALLEL-1:0] SlicesxDO,
    output reg[24:0] SliceZ0xDO
);

function integer Idx(input integer x, input integer y);
    Idx = (5*x+y)*SLICES_PARALLEL;
endfunction

generate begin
reg[5*SLICES_PARALLEL-1:0] C, C_rot;
reg[25*SLICES_PARALLEL-1:0] A, D;
localparam SP = SLICES_PARALLEL;

//-----------------------------------------------------------------------------
// Fully parallel Theta step. Computed in 1 cycle
if(W==SLICES_PARALLEL) begin

    always @(*) begin : THETA_PARALLEL
        integer x, y;
        A = SlicesxDI;
        for(x=0; x < 5; x=x+1) begin
            C[x*SP +: SP] = A[Idx(x,0) +: SP] ^ A[Idx(x,1) +: SP] ^ A[Idx(x,2) +: SP]
                            ^ A[Idx(x,3) +: SP] ^ A[Idx(x,4) +: SP];
            C_rot[x*SP +: SP] = {2{C[x*SP +: SP]}} >> (SP-1);
        end
        for(x=0; x < 5; x=x+1) begin
            for(y=0; y < 5; y=y+1) begin
                D[Idx(x,y) +: SP] = A[Idx(x,y) +: SP]
                    ^ C[(((x-1)+5) % 5)*SP +: SP] ^ C_rot[((x+1) % 5)*SP +: SP];
            end
        end

        SlicesxDO = D;
    end
end
//-----------------------------------------------------------------------------
// Iterative Theta step. Compute Theta on part of the state. The highest
// slice's parity is temporarily saved and acts as input for the next
// iteration. In the first iteration the first slice (z=0) is only partly
// evaluated, since the last slice (z=W-1) is not available. It is finished in
// the last iteration together with the last slice block.
else begin
    reg[4:0] TmpStoragexDP, TmpStoragexDN;

    always @(*) begin : THETA_ITERATIVE
        integer x, y;
        TmpStoragexDN = TmpStoragexDP;

        A = SlicesxDI;
        for(x=0; x < 5; x=x+1) begin
            C[x*SP +: SP] = A[Idx(x,0) +: SP] ^ A[Idx(x,1) +: SP] ^ A[Idx(x,2) +: SP]
                ^ A[Idx(x,3) +: SP] ^ A[Idx(x,4) +: SP];
            C_rot[x*SP +: SP] = {2{C[x*SP +: SP]}} >> (SP-1);
            TmpStoragexDN[x] = C[x*SP + SP - 1]; // save highest slice parity for next block
        end
        for(x=0; x < 5; x=x+1) begin
            for(y=0; y < 5; y=y+1) begin
                D[Idx(x,y) +: SP] = A[Idx(x,y) +: SP] ^ C[(((x-1)+5) % 5)*SP +: SP]
                    ^ {C_rot[((x+1)%5)*SP +: SP] >> 1, TmpStoragexDP[(x+1)%5]};
            end
        end

        SlicesxDO = D;
    end

    always @(posedge ClkxCI or negedge RstxRBI) begin
        if(~RstxRBI) TmpStoragexDP <= {5{1'b0}};
        else if(RstSyncxRI) TmpStoragexDP <= {5{1'b0}};
        else if(EnablexSI) TmpStoragexDP <= TmpStoragexDN;
    end

    always @(*) begin : LAST_SLICE
        integer x, y;
        for(x=0; x < 5; x=x+1) begin
            for(y=0; y < 5; y=y+1) begin
                SliceZ0xDO[5*x+y] = SliceZ0xDI[5*x+y] ^ TmpStoragexDN[(x+1)%5];
            end
        end
    end
end

end
endgenerate

endmodule
`default_nettype wire
