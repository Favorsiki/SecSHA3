`timescale 1ns/1ns

module keccak_top #(
    // BASIC OPTIONS
    parameter RATE = 1088, // The rate of the sponge construction
    parameter W = 64,      // The width of one Keccak register, aka lane length
    parameter SHARES = 1,  // Number of shares to use (SHARES-1 == protection order).

    //TODO Would be nice to have a coarse configuration setting in case we don't need full configurability
    // 0 = Minimum area. Detailed description goes here
    // 1 = Almost minimum area. Detailed description goes here
    // ...
    //parameter CONFIGURATION = 0,


    // ADVANCED OPTIONS

    // Number of lanes that are absorbed in one cycle.
    // You probably want to set ABSORB_ITERATIVE=0 if this is not RATE/W,
    // otherwise absorbtion will take a significant amount of time.
    parameter ABSORB_LANES = RATE/W,

    // Note: If all of the following *_ITERATIVE options are 0, all steps
    //       are done in one cycle. Consequently the whole computation takes
    //       12+2*ld(W) (== #rounds) cycles

    // 0 = State reset is done asynchronously
    // 1 = State reset takes W cycles, but the more expensive Clear FF are
    //     not used
    parameter RESET_ITERATIVE = 1,

    // 0 = Absorb in one cycle. (Automatically true if W==SLICES_PARALLEL)
    // 1 = Absorb concurrently with Theta step if W!=SLICES_PARALLEL.
    // ABSORB_ITERATIVE implies THETA_ITERATIVE, thus THETA_ITERATIVE is
    // ignored if (ABSORB_ITERATIVE == 1)
    parameter ABSORB_ITERATIVE = 1,

    // 0 = Theta executed in 1 cycle
    // 1 = Theta takes W/SLICES_PARALLEL cycles
    // ABSORB_ITERATIVE implies THETA_ITERATIVE, thus THETA_ITERATIVE is
    // ignored if (ABSORB_ITERATIVE == 1)
    parameter THETA_ITERATIVE = 1,

    //TODO rename
    // 0 = Rho+Pi executed in 1 cycle
    // 1 = Rho is done in W cycles, Pi takes W/SLICES_PARALLEL cycles
    parameter RHO_PI_ITERATIVE = 0,

    // 0 = Chi+Iota executed in 1 cycle
    // 1 = Chi+Iota takes W/SLICES_PARALLEL cycles if unprotected, and
    //     2*W/SLICES_PARALLEL cycles if DOM is used (pipelining and double
    //     clocking decrease this to W/SLICES_PARALLEL+1 and W/SLICES_PARALLEL
    //     respectively)
    parameter CHI_IOTA_ITERATIVE = 1,

    // The iterative steps operate on SLICES_PARALLEL slices.
    // Each iterative step thus takes W/SLICES_PARALLEL cycles.
    // Note that an iterative Chi step drastically reduces the required
    // randomness of a masked configuration (see further documentation for
    // details).
    parameter SLICES_PARALLEL = 1,

    // The Chi step takes 2*ABSORB_SLICES cycles in DOM. Clock the inner domain
    // register with the negative edge to overcome this. This should hardly
    // influence the critical path, but increase throughput.
    parameter CHI_DOUBLE_CLK = 1,

    parameter LESS_RAND = 1,

    // Controls the insertion of the inner-domain FF when using more than 1 share
    // 0 = Only the cross-domain-FF are inserted
    // 1 = Inner-domain FF are inserted and used as pipeline stage if the
    //     configuration allows it
    parameter DOM_PIPELINE = 1,

    // LOCAL PARAMETERS - DO NOT MODIFY
    parameter ABSORB_SLICES = ABSORB_ITERATIVE ? SLICES_PARALLEL : W,
    parameter THETA_SLICES = THETA_ITERATIVE ? SLICES_PARALLEL : ABSORB_SLICES,
    parameter CHI_SLICES = CHI_IOTA_ITERATIVE ? SLICES_PARALLEL : W,
    parameter CONNECT_ABSORB_CHI = (ABSORB_ITERATIVE && CHI_IOTA_ITERATIVE && RATE/W == ABSORB_LANES) ? 1 : 0,
    parameter DATAOUT_SIZE = (CONNECT_ABSORB_CHI) ? 25*SLICES_PARALLEL : RATE
)(
    input wire ClkxCI,
    input wire RstxRBI,

    input  wire RandomnessAvailablexSI,
    input  wire StartAbsorbxSI,
    input  wire StartSqueezexSI,
    //TODO a valid/ready signal pair for DataxDO from Chi step (last round output)
    output wire ReadyxSO,
    input  wire[SHARES*(ABSORB_LANES*ABSORB_SLICES)-1:0] AbsorbSlicesxDI,
    //TODO ZxDI length can be adjusted to LESS_RAND (should be no functional difference, since upper bits are just unused at the moment in that case)
    input  wire[(SHARES*SHARES-SHARES)/2 * 25 * CHI_SLICES - 1:0] ZxDI,
    output reg[SHARES*DATAOUT_SIZE-1:0] DataxDO
);

localparam STATE_SIZE = 5*5*W;
localparam THETA_SLICES_SIZE = 5*5*THETA_SLICES;
localparam CHI_SLICES_SIZE = 5*5*CHI_SLICES;
localparam PI_SLICES = SLICES_PARALLEL; //TODO hmm
localparam PI_SLICES_SIZE = 5*5*PI_SLICES;
localparam ABSORB_SLICES_SIZE = ABSORB_SLICES * ABSORB_LANES;

function integer getLaneNr(input integer x_coord, input integer y_coord);
    getLaneNr = 5*x_coord + y_coord;
endfunction

function integer getXCoord(input integer lane_nr);
    getXCoord = lane_nr / 5;
endfunction

function integer getYCoord(input integer lane_nr);
    getYCoord = lane_nr % 5;
endfunction

function integer Idx(input integer s,
                     input integer x,
                     input integer y,
                     input integer len);
    Idx = s*25*len + getLaneNr(x,y)*len;
endfunction

function integer StateIdx(input integer s, input integer x, input integer y);
    StateIdx = s*STATE_SIZE + getLaneNr(x,y)*W;
endfunction

`define QUEUE(target_state, slices, slice_len, shift) \
    for(i=0; i < SHARES; i=i+1) begin \
        for(x=0; x < 5; x=x+1) begin \
            for(y=0; y < 5; y=y+1) begin \
                target_state[StateIdx(i,x,y) +: W] = { \
                    slices[Idx(i,x,y,slice_len) +: shift], \
                    StatexD[StateIdx(i,x,y) +: W] } >> shift; \
            end \
        end \
    end

`define CON_SLICES(dst, dst_len, src, src_len, start_slice, amount) \
    for(i=0; i < SHARES; i=i+1) begin \
        for(x=0; x < 5; x=x+1) begin \
            for(y=0; y < 5; y=y+1) begin \
                dst[Idx(i,x,y,dst_len) +: amount] \
                    = src[Idx(i,x,y,src_len) + start_slice +: amount]; \
            end \
        end \
    end

`define CON_ABSORB_XOR(dst, dst_len, src, src_len, amount) \
    for(i=0; i < SHARES; i=i+1) begin \
        for(x=0; x < 5; x=x+1) begin \
            for(y=0; y < 5; y=y+1) begin \
                if(x+5*y < RATE/W) begin \
                    dst[Idx(i,x,y, dst_len) +: amount] \
                        = AbsorbSlicesxDI[i*(ABSORB_LANES*ABSORB_SLICES) + ((x+5*y)%ABSORB_LANES)*ABSORB_SLICES +: ABSORB_SLICES] \
                        ^ src[Idx(i,x,y,src_len) +: amount]; \
                end \
            end \
        end \
    end

/*
generate begin
// Some parameter sanity checks
if(RATE % W || RATE > 25*W)
    _RATE__must_be_a_multiple_of_the_lane_length__W__and_smaller_or_equal_to_25W DONT_COMPILE();
else if(SLICES_PARALLEL > W)
    _SLICES_PARALLEL__must_be_smaller_or_equal_to_the_lane_length__W_  DONT_COMPILE();
else if(!(W == 1 || W == 2 || W == 4 || W == 8 || W == 16 || W == 32 || W == 64))
    The_lane_length__W__must_be_a_power_of_2 DONT_COMPILE();
else if( (W==SLICES_PARALLEL) && (ABSORB_ITERATIVE || THETA_ITERATIVE || RHO_PI_ITERATIVE || CHI_IOTA_ITERATIVE) )
    W_eq_SLICES_PARALLEL_but_at_least_one_step_should_be_iterative_according_to_a_xxITERATIVE_parameter DONT_COMPILE();
else if( (W!=SLICES_PARALLEL) && !(ABSORB_ITERATIVE || THETA_ITERATIVE || RHO_PI_ITERATIVE || CHI_IOTA_ITERATIVE) )
    W_neq_SLICES_PARALLEL_but_no_iterative_step DONT_COMPILE();
else if( W==SLICES_PARALLEL && SHARES > 1 ) begin
    // Just a warning. Comment the line if you really want this
    //W_equals_SLICES_PARALLEL_but_using_a_masked_implementation_This_requires_a_lot_of_fresh_randomness_in_the_Chi_step DONT_COMPILE();
end
else if( ABSORB_LANES < 1 || ABSORB_LANES > RATE/W || (RATE/W) % ABSORB_LANES != 0)
    Allowed_range_is_1_le_ABSORB_LANES_le_RATE_over_W___Further_restriction_is_RATE_over_W_mod_ABSORB_LANES_eq_0 DONT_COMPILE();
else if(RHO_PI_ITERATIVE && !CHI_IOTA_ITERATIVE)
    Not_useful_because_Rho_and_pi_will_take_W_cycles_each_Set_CHI_IOTA_ITERATIVE_so_that_the_Pi_step_is_done_concurrently_with_Chi DONT_COMPILE();
else if(RHO_PI_ITERATIVE && SLICES_PARALLEL != 1)
    The_iterative_Rho_step_is_done_by_shifting_the_lanes_Thus_we_need_W_cycles_and_not_W_over_SLICES_PARALLEL DONT_COMPILE();
else if(CHI_DOUBLE_CLK && DOM_PIPELINE)
    CHI_DOUBLE_CLK_and_DOM_PIPELINE_cannot_both_be_true DONT_COMPILE();
end endgenerate */

wire[SHARES*STATE_SIZE-1:0] StatexD;
reg[SHARES*5*5*THETA_SLICES-1:0] SlicesToThetaxD;
wire[SHARES*5*5*THETA_SLICES-1:0] SlicesFromThetaxD;

reg[SHARES*5*5-1:0] SliceZ0ToThetaxD;
wire[SHARES*5*5-1:0] SliceZ0FromThetaxD;

wire[SHARES*5*5*SLICES_PARALLEL-1:0] SlicesFromPixD;
reg[SHARES*5*5*SLICES_PARALLEL-1:0] SlicesToPixD;

wire[SHARES*STATE_SIZE-1:0] StateFromRhoPixD;
reg[SHARES*STATE_SIZE-1:0] StateToRhoPixD;

reg[SHARES*5*5*CHI_SLICES-1:0] SlicesToChixD;
wire[SHARES*5*5*CHI_SLICES-1:0] SlicesFromChixD;

wire[24:0] ctrl_enable_lane;
wire ctrl_enable_absorb;
wire ctrl_enable_lambda;
wire ctrl_enable_theta;
wire ctrl_enable_rhopi;
wire ctrl_enable_chi_iota;
wire ctrl_theta_last;
wire ctrl_enable_absorb_theta;
wire ctrl_enable_DOM_ff;
wire ctrl_reset_state;

genvar i;
generate begin
    for(i = 0; i < SHARES; i=i+1) begin : gen_linear_steps

        //---------------------------------------------------------------------
        // States

        keccak_state #(
            .RATE(RATE),
            .W(W),
            .RESET_ITERATIVE(RESET_ITERATIVE),
            .ABSORB_ITERATIVE(ABSORB_ITERATIVE),
            .THETA_ITERATIVE(THETA_ITERATIVE),
            .RHO_PI_ITERATIVE(RHO_PI_ITERATIVE),
            .CHI_IOTA_ITERATIVE(CHI_IOTA_ITERATIVE),
            .CONNECT_ABSORB_CHI(CONNECT_ABSORB_CHI),
            .SLICES_PARALLEL(SLICES_PARALLEL),
            .THETA_SLICES(THETA_SLICES),
            .CHI_SLICES(CHI_SLICES),
            .ABSORB_LANES(ABSORB_LANES),
            .ABSORB_SLICES(ABSORB_SLICES)
            ) SHARE(
            .ClkxCI(ClkxCI),
            .RstxRBI(RstxRBI),
            .EnableLanexSI     (ctrl_enable_lane  ),
            .ctrl_reset_state  (ctrl_reset_state  ),
            .ctrl_enable_rhopi (ctrl_enable_rhopi ),
            .ctrl_enable_theta (ctrl_enable_theta ),
            .ctrl_theta_last   (ctrl_theta_last   ),
            .ctrl_enable_lambda(ctrl_enable_lambda),
            .ctrl_enable_absorb(ctrl_enable_absorb),
            .AbsorbSlicesxDI(AbsorbSlicesxDI[i*(ABSORB_LANES*ABSORB_SLICES) +: (ABSORB_LANES*ABSORB_SLICES)]),
            .SliceZ0FromThetaxDI(SliceZ0FromThetaxD[i*25 +: 25]),
            .SlicesFromThetaxDI(SlicesFromThetaxD[i*THETA_SLICES_SIZE +: THETA_SLICES_SIZE]),
            .StateFromRhoPixDI(StateFromRhoPixD[i*STATE_SIZE +: STATE_SIZE]),
            .SlicesFromChixDI(SlicesFromChixD[i*CHI_SLICES_SIZE +: CHI_SLICES_SIZE]),
            .StatexDO(StatexD[i*STATE_SIZE +: STATE_SIZE])
        );

        //---------------------------------------------------------------------
        // Theta

        keccak_theta #(.W(W), .SLICES_PARALLEL(THETA_SLICES)) THETA(
            .ClkxCI(ClkxCI),
            .RstxRBI(RstxRBI),
            .RstSyncxRI(ctrl_theta_last),
            .EnablexSI(ctrl_enable_theta),
            .SlicesxDI(SlicesToThetaxD[i*THETA_SLICES_SIZE +: THETA_SLICES_SIZE]),
            .SliceZ0xDI(SliceZ0ToThetaxD[i*25 +: 25]),
            .SlicesxDO(SlicesFromThetaxD[i*THETA_SLICES_SIZE +: THETA_SLICES_SIZE]),
            .SliceZ0xDO(SliceZ0FromThetaxD[i*25 +: 25])
        );

        //---------------------------------------------------------------------
        // Rho + Pi

        if(RHO_PI_ITERATIVE) begin
            keccak_pi #(
                .SLICES_PARALLEL(PI_SLICES)
                ) PI (
                .ClkxCI(ClkxCI),
                .RstxRBI(RstxRBI),
                .SlicesxDI(SlicesToPixD[i*PI_SLICES_SIZE +: PI_SLICES_SIZE]),
                .SlicesxDO(SlicesFromPixD[i*PI_SLICES_SIZE +: PI_SLICES_SIZE])
            );
        end
        else begin
            keccak_rhopi #(.W(W)) RHOPI(
                .StatexDI(StateToRhoPixD[i*STATE_SIZE +: STATE_SIZE]),
                .StatexDO(StateFromRhoPixD[i*STATE_SIZE +: STATE_SIZE])
            );
        end

    end
end
endgenerate

//-----------------------------------------------------------------------------
// Chi + Iota

wire[CHI_SLICES-1:0] IotaRCxD;
keccak_chi_iota #(
    .SHARES(SHARES),
    .SLICES(CHI_SLICES),
    .CHI_DOUBLE_CLK(CHI_DOUBLE_CLK),
    .LESS_RAND(LESS_RAND),
    .DOM_PIPELINE(DOM_PIPELINE)
    ) CHI(
    .ClkxCI(ClkxCI),
    .EnablexSI(ctrl_enable_DOM_ff),
    .RstxRBI(RstxRBI),
    .SlicesxDI(SlicesToChixD),
    .ZxDI(ZxDI),
    .IotaRCxDI(IotaRCxD),
    .SlicesxDO(SlicesFromChixD)
);

//-----------------------------------------------------------------------------
// Connection of the steps in different configurations

always @(*) begin : OUTPUT_CONNECT
    integer i, x, y;
    if(CONNECT_ABSORB_CHI) begin
        // Outputs are slices from Chi. User has to store them and put them
        // back together
        DataxDO = SlicesFromChixD;
    end
    else begin
        // Output is part of the state
        for(i=0; i < SHARES; i=i+1)
            for(x=0; x < 5; x=x+1)
                for(y=0; y < 5; y=y+1)
                    if(x+5*y < RATE/W) // First Rate/W lanes
                        DataxDO[i*RATE + (x+5*y)*W +: W] = StatexD[StateIdx(i,x,y) +: W];
    end

end

always @(*) begin : THETA_CONNECT
    integer i, x, y;
    //`CON_SLICES(dst, dst_len, src, src_len, start_slice, amount)
    if(THETA_ITERATIVE || ABSORB_ITERATIVE) begin
        `CON_SLICES(SliceZ0ToThetaxD, 1, StatexD, W, THETA_SLICES, 1)
    end
    else begin
        SliceZ0ToThetaxD = {SHARES*25{1'b0}};
    end

    if(CONNECT_ABSORB_CHI) begin
        // ABSORB_SLICES == THETA_SLICES == CHI_SLICES
        `CON_SLICES(SlicesToThetaxD, THETA_SLICES, SlicesFromChixD, CHI_SLICES, 0, THETA_SLICES)
        if(ctrl_enable_absorb_theta) begin
            `CON_ABSORB_XOR(SlicesToThetaxD, THETA_SLICES, SlicesFromChixD, CHI_SLICES, THETA_SLICES)
        end
    end
    else if(ABSORB_ITERATIVE) begin
        // Absorbtion and Theta step concurrent in slice based absorbtion
        `CON_SLICES(SlicesToThetaxD, THETA_SLICES, StatexD, W, 0, THETA_SLICES)
        if(ctrl_enable_absorb_theta) begin
            `CON_ABSORB_XOR(SlicesToThetaxD, THETA_SLICES, StatexD, W, THETA_SLICES)
        end
    end
    else begin
        `CON_SLICES(SlicesToThetaxD, THETA_SLICES, StatexD, W, 0, THETA_SLICES)
    end
end

always @(*) begin : RHO_PI_CONNECT
    integer i, x, y;
    if(RHO_PI_ITERATIVE) begin
        `CON_SLICES(SlicesToPixD, PI_SLICES, StatexD, W, 0, PI_SLICES)
    end
    else if(!RHO_PI_ITERATIVE && !THETA_ITERATIVE && !ABSORB_ITERATIVE) begin
        // Linear steps not iterative -> chain Theta+Rho+Pi steps together
        `CON_SLICES(StateToRhoPixD, W, SlicesFromThetaxD, W, 0, W)
    end
    else begin
        StateToRhoPixD = StatexD;
    end
end

always @(*) begin : CHI_CONNECT
    integer i, x, y;
    //`CON_SLICES(dst, dst_len, src, src_len, start_slice, amount)
    // NOTE: The non-completeness property would not be fulfilled
    // if chi(pi(rho(theta(STATE)))) is performed combinationally
    if(CHI_IOTA_ITERATIVE || (SHARES > 1)) begin
        if(RHO_PI_ITERATIVE) begin
            `CON_SLICES(SlicesToChixD, CHI_SLICES, SlicesFromPixD, PI_SLICES, 0, CHI_SLICES)
        end
        else begin
            `CON_SLICES(SlicesToChixD, CHI_SLICES, StatexD, W, 0, CHI_SLICES)
        end
    end
    else begin
        `CON_SLICES(SlicesToChixD, CHI_SLICES, StateFromRhoPixD, W, 0, CHI_SLICES)
    end
end

//-----------------------------------------------------------------------------
// Control path

keccak_control #(
    .RATE(RATE),
    .W(W),
    .SHARES(SHARES),
    .ABSORB_LANES(ABSORB_LANES),
    .RESET_ITERATIVE(RESET_ITERATIVE),
    .ABSORB_ITERATIVE(ABSORB_ITERATIVE),
    .THETA_ITERATIVE(THETA_ITERATIVE),
    .RHO_PI_ITERATIVE(RHO_PI_ITERATIVE),
    .CHI_IOTA_ITERATIVE(CHI_IOTA_ITERATIVE),
    .SLICES_PARALLEL(SLICES_PARALLEL),
    .ABSORB_SLICES(ABSORB_SLICES),
    .THETA_SLICES(THETA_SLICES),
    .CHI_SLICES(CHI_SLICES),
    .CHI_DOUBLE_CLK(CHI_DOUBLE_CLK),
    .CONNECT_ABSORB_CHI(CONNECT_ABSORB_CHI),
    .DOM_PIPELINE(DOM_PIPELINE)
    ) KECCAK_CONTROL (
    .ClkxCI(ClkxCI),
    .RstxRBI(RstxRBI),
    .StartAbsorbxSI(StartAbsorbxSI),
    .StartSqueezexSI(StartSqueezexSI),
    .RandomnessAvailablexSI(RandomnessAvailablexSI),
    .ReadyxSO(ReadyxSO),
    .IotaRCxDO(IotaRCxD),
    .StateCtrlxSO( {ctrl_enable_lane,
                    ctrl_enable_absorb,
                    ctrl_enable_lambda,
                    ctrl_enable_theta,
                    ctrl_enable_rhopi,
                    ctrl_enable_chi_iota,
                    ctrl_theta_last,
                    ctrl_enable_absorb_theta,
                    ctrl_enable_DOM_ff,
                    ctrl_reset_state } )
);

endmodule
