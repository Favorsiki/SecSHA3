`timescale 1ns/1ns

module keccak_state #(
    parameter RATE = 128,
    parameter W = 16,

    parameter RESET_ITERATIVE = 1,
    parameter ABSORB_ITERATIVE = 1,
    parameter THETA_ITERATIVE = 1,
    parameter RHO_PI_ITERATIVE = 0,
    parameter CHI_IOTA_ITERATIVE = 1,

    parameter CONNECT_ABSORB_CHI = 1,
        
    parameter SLICES_PARALLEL = 1,
    parameter THETA_SLICES = 1,
    parameter CHI_SLICES = 1,
    parameter ABSORB_LANES = RATE/W,
    parameter ABSORB_SLICES = W
)(
    input  wire ClkxCI,
    input  wire RstxRBI,
    input  wire[24:0] EnableLanexSI,
    input  wire ctrl_reset_state,
    input  wire ctrl_enable_rhopi,
    input  wire ctrl_enable_theta,
    input  wire ctrl_theta_last,
    input  wire ctrl_enable_lambda,
    input  wire ctrl_enable_absorb,
    input  wire[(ABSORB_LANES*ABSORB_SLICES)-1:0] AbsorbSlicesxDI,
    input  wire[24:0] SliceZ0FromThetaxDI,
    input  wire[25*THETA_SLICES-1:0] SlicesFromThetaxDI,
    input  wire[25*W-1:0] StateFromRhoPixDI,
    input  wire[25*CHI_SLICES-1:0] SlicesFromChixDI,
    output wire[25*W-1:0] StatexDO
);

localparam STATE_SIZE = 5*5*W;

function integer getLaneNr(input integer x_coord, input integer y_coord);
    getLaneNr = 5*x_coord + y_coord;
endfunction

function integer Idx(input integer x,
                     input integer y,
                     input integer len);
    Idx = getLaneNr(x,y)*len;
endfunction

`define QUEUE2(target_state, slices, slice_len, shift) \
    for(x=0; x < 5; x=x+1) begin \
        for(y=0; y < 5; y=y+1) begin \
            target_state[Idx(x,y,W) +: W] = { \
                slices[Idx(x,y,slice_len) +: shift], \
                StatexDP[Idx(x,y,W) +: W] } >> shift; \
        end \
    end

`define CON_SLICES2(dst, dst_len, src, src_len, start_slice, amount) \
    for(x=0; x < 5; x=x+1) begin \
        for(y=0; y < 5; y=y+1) begin \
            dst[Idx(x,y,dst_len) +: amount] \
                = src[Idx(x,y,src_len) + start_slice +: amount]; \
        end \
    end

`define CON_ABSORB_XOR2(dst, dst_len, src, src_len, amount) \
    for(x=0; x < 5; x=x+1) begin \
        for(y=0; y < 5; y=y+1) begin \
            if(x+5*y < RATE/W) begin \
                dst[Idx(x,y, dst_len) +: amount] \
                    = AbsorbSlicesxDI[((x+5*y)%ABSORB_LANES)*ABSORB_SLICES +: ABSORB_SLICES] \
                    ^ src[Idx(x,y,src_len) +: amount]; \
            end \
        end \
    end

reg[STATE_SIZE-1:0] SlicesToStatexD;
reg[STATE_SIZE-1:0] StatexDP;

always @(*) begin : STATE_CONNECT
    integer x, y;
    reg[STATE_SIZE-1:0] tmp;
    //SlicesToStatexD = StatexDP;

    if(CONNECT_ABSORB_CHI) begin
        if(RESET_ITERATIVE && ctrl_reset_state) begin
            tmp = {STATE_SIZE{1'b0}};
            `QUEUE2(SlicesToStatexD, tmp, W, THETA_SLICES)
        end
        else if(ctrl_enable_rhopi) begin
            if (RHO_PI_ITERATIVE) begin
                `QUEUE2(SlicesToStatexD, StatexDP, W, 1)
            end
            else begin
                SlicesToStatexD = StateFromRhoPixDI;
            end
        end
        else begin
            `QUEUE2(SlicesToStatexD, SlicesFromThetaxDI, THETA_SLICES, THETA_SLICES)
            if(ctrl_theta_last) begin
                //`CON_SLICES2(dst, dst_len, src, src_len, start_slice, amount)
                `CON_SLICES2(SlicesToStatexD, W, SliceZ0FromThetaxDI, 1, 0, 1)
            end
        end
    end
    else begin
        case(1'b1)
        RESET_ITERATIVE && ctrl_reset_state: begin
            tmp = {STATE_SIZE{1'b0}};
            `QUEUE2(SlicesToStatexD, tmp, W, THETA_SLICES)
        end
        ctrl_enable_absorb: begin
            if(!ABSORB_ITERATIVE) begin
                `CON_ABSORB_XOR2(SlicesToStatexD, W, StatexDP, W, W)
            end
            else if(W!=ABSORB_SLICES && ABSORB_LANES < RATE/W) begin
                `CON_ABSORB_XOR2(tmp, W, StatexDP, W, W)
                `QUEUE2(SlicesToStatexD, tmp, W, ABSORB_SLICES)
            end
            else begin
                // assert(false); 
                // Can't happen, by design. Since Verilog2001 doesn't have assertions
                // we write a bogus value to the state that is checked during simulations
                $fatal(1, "stop");
                SlicesToStatexD = 42;
            end
        end
        ctrl_enable_lambda: begin
            SlicesToStatexD = StateFromRhoPixDI;
        end
        ctrl_enable_rhopi: begin
            if (RHO_PI_ITERATIVE) begin
                `QUEUE2(SlicesToStatexD, StatexDP, W, 1)
            end
            else begin
                SlicesToStatexD = StateFromRhoPixDI;
            end
        end
        ctrl_enable_theta: begin
            `QUEUE2(SlicesToStatexD, SlicesFromThetaxDI, THETA_SLICES, THETA_SLICES)
            if((ABSORB_ITERATIVE || THETA_ITERATIVE) && ctrl_theta_last) begin
                //`CON_SLICES2(dst, dst_len, src, src_len, start_slice, amount)
                `CON_SLICES2(SlicesToStatexD, W, SliceZ0FromThetaxDI, 1, 0, 1)
            end
        end
        //ctrl_enable_chi_iota: begin
        default: begin
            // Use Chi/Iota as the default state, since the enable signals
            // handle the state update anyway. Decreases gate count, because
            // the synthesizer can't infer that SlicesToStatexD = StatexDP
            // is already done by these enable signals.
            `QUEUE2(SlicesToStatexD, SlicesFromChixDI, CHI_SLICES, CHI_SLICES)
        end
        endcase
    end

end



generate begin
if(!RESET_ITERATIVE) begin
    always @(posedge ClkxCI or negedge RstxRBI) begin : STATE
        integer regcnt;
        if(~RstxRBI) begin
            StatexDP <= {STATE_SIZE{1'b0}};
        end
        else begin
            for(regcnt=0; regcnt < 25; regcnt=regcnt+1) begin
                if (EnableLanexSI[regcnt]) begin
                    StatexDP[regcnt*W +: W] <= SlicesToStatexD[regcnt*W +: W];
                end
            end
        end
    end

end
else begin
    always @(posedge ClkxCI) begin : STATE
        integer regcnt;
        for(regcnt=0; regcnt < 25; regcnt=regcnt+1) begin
            if (EnableLanexSI[regcnt]) begin
                StatexDP[regcnt*W +: W] <= SlicesToStatexD[regcnt*W +: W];
            end
        end
    end

end
assign StatexDO = StatexDP;

end endgenerate


endmodule
