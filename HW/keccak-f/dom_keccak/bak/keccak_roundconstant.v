`timescale 1ns / 1ps


module keccak_roundconstant #(
    parameter W = 16,
    parameter COUNTER_BITWIDTH = 4,
    parameter SLICES_PARALLEL = 1,
    parameter DOM_PIPELINE = 1,
    parameter SBOX_1CYCLE = 0
)
(
    input wire ClkxCI,
    input wire RstxRBI,
    input wire[4:0] RoundNrxDI,
    input wire[COUNTER_BITWIDTH:0] SliceNrxDI,
    input wire[COUNTER_BITWIDTH:0] NextSliceNrxDI,
    input wire ResetRCxSI,
    input wire EnableRCxSI,
    output reg[SLICES_PARALLEL-1:0] RCxDO
    );

generate begin

if(0 && SLICES_PARALLEL == 1 && W == 64) begin

    reg[7:0] RC_LFSRxDP, RC_LFSRxDN;
    reg RC_ZeroxSP, RC_ZeroxSN;
    always @(posedge ClkxCI or negedge RstxRBI) begin
        if(~RstxRBI) begin
            RC_LFSRxDP <= 8'h01;
            RC_ZeroxSP <= 0;
        end
        else begin
            RC_LFSRxDP <= RC_LFSRxDN;
            RC_ZeroxSP <= RC_ZeroxSN;
        end
    end

    always @(*) begin : LFSR_UPDATE
        reg[7:0] r;
        reg[COUNTER_BITWIDTH:0] tmp;

        tmp = {COUNTER_BITWIDTH{1'b0}};
        if(DOM_PIPELINE)
            tmp = (SliceNrxDI == 0) ? 0 : (SliceNrxDI - 1);
        else if(!SBOX_1CYCLE)
            tmp = NextSliceNrxDI >> 1;
        else
            tmp = NextSliceNrxDI;

        RC_ZeroxSN = (tmp == 0) | (tmp == 1) | (tmp == 3) | (tmp == 7) | (tmp == 15)
                    | (tmp == 31) | (tmp == 63);

        r = RC_LFSRxDP;
        RC_LFSRxDN = RC_LFSRxDP;

        if(ResetRCxSI) begin
            RC_LFSRxDN = 8'h01;
        end
        else if(EnableRCxSI) begin
            if (RC_ZeroxSP) begin
                RC_LFSRxDN[7] = r[6] ^ r[5] ^ r[4] ^ r[0];
                RC_LFSRxDN[6:0] = r[7:1];
            end
        end

        RCxDO[0] = RC_LFSRxDP[0] & RC_ZeroxSP;//next;
    end
end
else begin

    wire[0:24*64-1] RC = {
        64'h0000000000000001, 64'h0000000000008082, 64'h800000000000808A, 64'h8000000080008000,
        64'h000000000000808B, 64'h0000000080000001, 64'h8000000080008081, 64'h8000000000008009,
        64'h000000000000008A, 64'h0000000000000088, 64'h0000000080008009, 64'h000000008000000A,
        64'h000000008000808B, 64'h800000000000008B, 64'h8000000000008089, 64'h8000000000008003,
        64'h8000000000008002, 64'h8000000000000080, 64'h000000000000800A, 64'h800000008000000A,
        64'h8000000080008081, 64'h8000000000008080, 64'h0000000080000001, 64'h8000000080008008
    };

    always @(*) begin : SELECT_ROUND_CONSTANT
        integer i;
        reg[63:0] current_rc;
        i = SliceNrxDI;
        if(DOM_PIPELINE)
            i = SliceNrxDI;
        else if(!SBOX_1CYCLE)
            i = i >> 1; // 2 cycles per iteration if DOM is applied and the inner domain register isn't clocked with the negative clock edge
        current_rc = RC[RoundNrxDI*64 +: 64];
        RCxDO = EnableRCxSI ? current_rc[i*SLICES_PARALLEL +: SLICES_PARALLEL] : 64'h0;
    end

end
end endgenerate


endmodule
