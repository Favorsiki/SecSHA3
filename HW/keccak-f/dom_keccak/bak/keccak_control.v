`timescale 1ns/1ns

module keccak_control #(
    parameter RATE = 128,
    parameter W = 16,
    parameter SHARES = 2,
    parameter ABSORB_LANES = RATE/W,
    parameter RESET_ITERATIVE = 1,
    parameter ABSORB_ITERATIVE = 0,
    parameter THETA_ITERATIVE = 0,
    parameter RHO_PI_ITERATIVE = 0,
    parameter CHI_IOTA_ITERATIVE = 1,
    parameter SLICES_PARALLEL = 1,
    parameter CHI_DOUBLE_CLK = 1,
    parameter DOM_PIPELINE = 1,
    parameter ABSORB_SLICES = ABSORB_ITERATIVE ? SLICES_PARALLEL : W,
    parameter THETA_SLICES = THETA_ITERATIVE ? SLICES_PARALLEL : ABSORB_SLICES,
    parameter CHI_SLICES = CHI_IOTA_ITERATIVE ? SLICES_PARALLEL : W,
    parameter CONNECT_ABSORB_CHI = (ABSORB_ITERATIVE && CHI_IOTA_ITERATIVE && RATE/W == ABSORB_SLICES) ? 1 : 0
)(
    input wire ClkxCI,
    input wire RstxRBI,
    input wire StartAbsorbxSI,
    input wire StartSqueezexSI,
    input wire RandomnessAvailablexSI,
    output wire[CHI_SLICES-1:0] IotaRCxDO,
    output wire[33:0] StateCtrlxSO,
    output reg ReadyxSO
);
//-----------------------------------------------------------------------------
// (Constant) functions

function integer clog2(input integer value); begin
    value = value-1;
    for (clog2=0; value>0; clog2=clog2+1)
        value = value>>1;
end endfunction

function integer getLaneNr(input integer x_coord, input integer y_coord);
    getLaneNr = 5*x_coord + y_coord;
endfunction

function integer max(input integer first, input integer second);
    max = first > second ? first : second;
endfunction

//-----------------------------------------------------------------------------
// Constants

// NOTE: Computing chi(pi(rho(theta(STATE)))) in one cycle would violate the
// non-completeness property. Hence the output from pi needed to be saved into
// the state.
localparam USE_LAMBDA_STEPS = (SHARES > 1 || CHI_IOTA_ITERATIVE);

localparam SBOX_1CYCLE = (SHARES==1 || CHI_DOUBLE_CLK);
localparam ROUNDS = 12 + 2 * clog2(W);

localparam CHICNT_BITWIDTH = SBOX_1CYCLE ? clog2(W/CHI_SLICES) : clog2(2*W/CHI_SLICES);
localparam CHICNT_RST = DOM_PIPELINE ? (W/CHI_SLICES) :
                        (SBOX_1CYCLE ? (W/CHI_SLICES - 1) : (2*W/CHI_SLICES - 1));

localparam THETACNT_BITWIDTH = clog2(W/THETA_SLICES);
localparam THETACNT_RST = W/THETA_SLICES - 1;

localparam ABSORBCNT_BITWIDTH = clog2( (RATE/W)/ABSORB_LANES * W/ABSORB_SLICES);
localparam ABSORBCNT_BITWIDTH_SLICES = clog2(W/ABSORB_SLICES);
localparam ABSORBCNT_MAX = (RATE/W)/ABSORB_LANES * W/ABSORB_SLICES - 1;

localparam RHOCNT_BITWIDTH = RHO_PI_ITERATIVE ? clog2(W) : 0;
localparam RSTCNT_BITWIDTH = RESET_ITERATIVE ? clog2(W) : 0;
localparam RSTCNT_MAX = W-1;

localparam MAXCNT_BITWIDTH = max(max(max(max(ABSORBCNT_BITWIDTH,
        THETACNT_BITWIDTH), RHOCNT_BITWIDTH), CHICNT_BITWIDTH),
        RSTCNT_BITWIDTH);

localparam [0:25*8-1] ROTATION_OFFSETS = {
    8'd00, 8'd36, 8'd03, 8'd41, 8'd18,
    8'd01, 8'd44, 8'd10, 8'd45, 8'd02,
    8'd62, 8'd06, 8'd43, 8'd15, 8'd61,
    8'd28, 8'd55, 8'd25, 8'd21, 8'd56,
    8'd27, 8'd20, 8'd39, 8'd08, 8'd14
};

localparam
    RESET               = 7'h01,
    IDLE                = 7'h02,
    RHOPI               = 7'h04,
    THETA_CHI_IOTA      = 7'h08,
    THETA               = 7'h10,
    LAMBDA              = 7'h20,
    CHI_IOTA            = 7'h40;

//-----------------------------------------------------------------------------
// Signal declarations

// Sequential logic
reg[MAXCNT_BITWIDTH:0] CounterxDP, CounterxDN;
reg[6:0] CtrlStatexDP, CtrlStatexDN;
reg[4:0] RoundCountxDP, RoundCountxDN;
reg RoundCountLastxDP;

// Combinatoric logic
reg enableRoundCountxS;
reg SetInitialAbsorbDonexS;

reg[24:0] ctrl_enable_lane;
reg ctrl_enable_absorb;
reg ctrl_enable_lambda;
reg ctrl_enable_theta;
reg ctrl_enable_rhopi;
reg ctrl_enable_chi_iota;
reg ctrl_theta_last;
reg ctrl_enable_absorb_theta; //TODO check if we still need this
reg ctrl_enable_DOM_ff;
reg ctrl_reset_state;
assign StateCtrlxSO = { ctrl_enable_lane,
                        ctrl_enable_absorb,
                        ctrl_enable_lambda,
                        ctrl_enable_theta,
                        ctrl_enable_rhopi,
                        ctrl_enable_chi_iota,
                        ctrl_theta_last,
                        ctrl_enable_absorb_theta,
                        ctrl_enable_DOM_ff,
                        ctrl_reset_state};

task enable_absorb_lanes; begin : ENABLE_ABSORB_LANES
    integer y, x, l_cnt, l_nr;
    for(y = 0; y < 5; y=y+1) begin
        for(x = 0; x < 5; x=x+1) begin
            // All lanes that fulfill "x+5*y < RATE/W forall x,y" are absorbing lanes
            l_cnt = x + 5*y; // not the same as getLaneNr! (transposed enumeration)
            l_nr = getLaneNr(x,y);
            ctrl_enable_lane[l_nr] =
                (CounterxDP[ABSORBCNT_BITWIDTH:ABSORBCNT_BITWIDTH_SLICES]
                    == (l_cnt / ABSORB_LANES));
        end
    end
end endtask

task control_theta; begin
    ctrl_enable_lane = {25{1'b1}};
    ctrl_enable_theta = 1;
    CounterxDN = CounterxDP + 1;
    if(CounterxDP == THETACNT_RST) begin
        ctrl_theta_last = 1;
        CounterxDN = 0;
        if(CHI_IOTA_ITERATIVE)
            CtrlStatexDN = RHOPI;
        else
            CtrlStatexDN = CHI_IOTA;
    end
end endtask

//-----------------------------------------------------------------------------
// State machine

always @(*) begin : FSM
    CtrlStatexDN = CtrlStatexDP;
    CounterxDN = CounterxDP;

    ctrl_enable_lane = 25'b0;
    ctrl_enable_absorb = 0;
    ctrl_enable_lambda = 0;
    ctrl_enable_theta = 0;
    ctrl_enable_rhopi = 0;
    ctrl_enable_chi_iota = 0;
    ctrl_theta_last = 0;
    ctrl_enable_absorb_theta = 0;
    ctrl_enable_DOM_ff = 0;
    ctrl_reset_state = 0;

    enableRoundCountxS = 0;
    ReadyxSO = 0;
    SetInitialAbsorbDonexS = 0;

    case(CtrlStatexDP)
    RESET: begin
        ctrl_reset_state = 1;
        ctrl_enable_lane = {25{1'b1}};
        CounterxDN = CounterxDP + 1;
        if(CounterxDP == RSTCNT_MAX) begin
            CounterxDN = 0;
            CtrlStatexDN = IDLE;
        end
    end
    IDLE: begin
        ReadyxSO = 1;
        if(StartAbsorbxSI) begin
            ctrl_enable_absorb = 1;
            enable_absorb_lanes;

            if(ABSORB_LANES != RATE/W) begin
                // The data is delivered in chunks of lanes. ABSORB_LANES lanes get absorbed
                // concurrently.
                // Scenario: Data comes from a N-bit bus, so we can only absorb N/W lanes
                //           at once without additional buffer memory
                CounterxDN = CounterxDP + 1;
                if(CounterxDP == ABSORBCNT_MAX) begin
                    CounterxDN = 0;
                    // Absorb done
                    if(ABSORB_ITERATIVE || THETA_ITERATIVE || RHO_PI_ITERATIVE)
                        CtrlStatexDN = THETA;
                    else if(USE_LAMBDA_STEPS)
                        CtrlStatexDN = LAMBDA;
                    else
                        CtrlStatexDN = CHI_IOTA;
                end
            end
            else if(ABSORB_ITERATIVE) begin
                // The data is delivered in chunks of slices. ABSORB_SLICES slices get absorbed
                // concurrently. For efficiency reasons, this is done concurrently with the
                // Theta step
                // Scenario: Specialized implementations mainly. E.g. usage as a PRNG that is
                //           fed with some random bits from time to time

                // This is actually the first cycle of Theta
                ctrl_enable_absorb = 0;
                ctrl_enable_absorb_theta = 1;
                control_theta;
            end
            else if(THETA_ITERATIVE || RHO_PI_ITERATIVE) begin
                // The data is delivered in one big chunk having the size of RATE.
                // However, we want to perform the Theta,Rho or Pi steps iteratively (e.g.
                // because of area requirements)
                CtrlStatexDN = THETA;
            end
            else begin
                // The data is delivered in one big chunk having the size of RATE.
                // We want to perform Theta, Rho and Pi in one step after absorbtion.
                if(USE_LAMBDA_STEPS)
                    CtrlStatexDN = LAMBDA; // theta+rho+pi in one step
                else
                    CtrlStatexDN = CHI_IOTA;
            end
        end
        else if(StartSqueezexSI) begin
            if(ABSORB_ITERATIVE || THETA_ITERATIVE || RHO_PI_ITERATIVE) begin
                CtrlStatexDN = THETA;
            end
            else begin
                // NOTE: The non-completeness property would not be fulfilled
                // if chi(pi(rho(theta(STATE)))) is performed combinationally
                if(USE_LAMBDA_STEPS)
                    CtrlStatexDN = LAMBDA; // theta+rho+pi in one step
                else
                    CtrlStatexDN = CHI_IOTA;
            end
        end
    end
    LAMBDA: begin
        ctrl_enable_lane = {25{1'b1}};
        ctrl_enable_lambda = 1;
        CtrlStatexDN = CHI_IOTA;
    end
    THETA: begin
        control_theta;
    end
    RHOPI: begin
        if(RHO_PI_ITERATIVE) begin : RHO
            integer i;

            ctrl_enable_rhopi = 1;
            CounterxDN = CounterxDP + 1;
            for(i=0; i<25; i=i+1) begin
                if(CounterxDP < (W - (ROTATION_OFFSETS[i*8 +: 8] % W))) begin
                    ctrl_enable_lane[i] = 1'b1;
                end
            end
            if(CounterxDP == W-1) begin
                CounterxDN = 0;
                if(CONNECT_ABSORB_CHI)begin
                    SetInitialAbsorbDonexS = 1;
                    CtrlStatexDN = THETA_CHI_IOTA;
                end
                else begin
                    CtrlStatexDN = CHI_IOTA;
                end
            end
        end
        else begin
            ctrl_enable_lane = {25{1'b1}};
            ctrl_enable_rhopi = 1;
            CtrlStatexDN = CHI_IOTA;

            if(CONNECT_ABSORB_CHI)begin
                SetInitialAbsorbDonexS = 1;
                CtrlStatexDN = THETA_CHI_IOTA;
            end
        end
    end
    //THETA_CHI_IOTA_DOM_PIPELINE_DELAY: begin
        //if(StartAbsorbxSI && RoundCountLastxDP) begin
            
        //end
        //else begin
        //end
    //end
    THETA_CHI_IOTA: begin
        if(CONNECT_ABSORB_CHI) begin
            if(DOM_PIPELINE) begin
                if(RoundCountLastxDP && StartAbsorbxSI && (CounterxDP != 0)) begin
                    ReadyxSO = 1; // 1 cycle delay
                end
            end
            else if(SBOX_1CYCLE) begin
                if(RoundCountLastxDP)
                    ReadyxSO = 1;
            end
            else begin
                if(RoundCountLastxDP && CounterxDP[0])
                    ReadyxSO = 1;
            end

            if((ReadyxSO && StartAbsorbxSI)
                || !RoundCountLastxDP //RoundCountxDP
                || (!SBOX_1CYCLE && !CounterxDP[0])
                || (DOM_PIPELINE && (CounterxDP == 0))) begin
                CounterxDN = CounterxDP + 1;
                ctrl_enable_DOM_ff = 1;

                if((CounterxDP[0] == 1) || SBOX_1CYCLE || DOM_PIPELINE) begin
                    // DOM adds a delay cycle if not CHI_DOUBLE_CLK is active
                    ctrl_enable_chi_iota = 1;
                    ctrl_enable_lane = {25{1'b1}};
                    ctrl_enable_theta = 1;
                    ctrl_enable_absorb_theta = ReadyxSO;
                    if(DOM_PIPELINE) begin : pippi
                        // 1 cycle delay
                        reg delay;
                        delay = (CounterxDP != 0);
                        ctrl_enable_theta = delay;
                        ctrl_enable_absorb_theta = delay && ReadyxSO;
                    end
                end

                if(CounterxDP == CHICNT_RST) begin
                    CounterxDN = 0;
                    enableRoundCountxS = 1;
                    ctrl_theta_last = 1;
                    CtrlStatexDN = RHOPI;
                end
            end
        end
    end
    CHI_IOTA: begin
        CounterxDN = CounterxDP + 1;

        ctrl_enable_DOM_ff = 1;
        if(CounterxDP % 2 == 1 || SBOX_1CYCLE || DOM_PIPELINE) begin
            // DOM adds a delay cycle if not CHI_DOUBLE_CLK is active
            ctrl_enable_chi_iota = 1;
            ctrl_enable_lane = {25{1'b1}};
        end
        if(CounterxDP == CHICNT_RST) begin
            CounterxDN = 0;
            enableRoundCountxS = 1;

            if(RoundCountLastxDP) begin
                CtrlStatexDN = IDLE;
            end
            else begin
                if(ABSORB_ITERATIVE || THETA_ITERATIVE || RHO_PI_ITERATIVE)
                    CtrlStatexDN = THETA;
                else if(USE_LAMBDA_STEPS)
                    CtrlStatexDN = LAMBDA;
                else
                    CtrlStatexDN = CHI_IOTA;
            end
        end
    end
    endcase
end

always @(posedge ClkxCI or negedge RstxRBI) begin
    if(~RstxRBI) begin
        CtrlStatexDP <= RESET_ITERATIVE ? RESET : IDLE;
        RoundCountxDP <= 0;
        RoundCountLastxDP <= 0;
        CounterxDP <= 0;
    end
    else begin
        CtrlStatexDP <= CtrlStatexDN;
        RoundCountxDP <= RoundCountxDN;
        RoundCountLastxDP <= (RoundCountxDN == ROUNDS - 1);
        CounterxDP <= CounterxDN;
    end
end

wire resetRoundCountxS = (enableRoundCountxS & (RoundCountxDP == ROUNDS - 1));
always @(*) begin
    RoundCountxDN = RoundCountxDP;
    if(resetRoundCountxS) RoundCountxDN = 0;
    else if(enableRoundCountxS) RoundCountxDN = RoundCountxDP + 1;
end

// TODO only needed when CONNECT_ABSORB_CHI == 1
reg InitialAbsorbDonexDP;
always @(posedge ClkxCI or negedge RstxRBI) begin
    if(~RstxRBI) InitialAbsorbDonexDP <= 1'b0;
    else if(SetInitialAbsorbDonexS) InitialAbsorbDonexDP <= 1'b1;
end

wire[CHI_SLICES-1:0] RCxD;
//wire EnableRCxSI = DOM_PIPELINE ? CounterxDP != 0  && ctrl_enable_chi_iota
//                   (SBOX_1CYCLE ? CounterxDP != 0  && : 1

keccak_roundconstant #(
    .W(W),
    .SLICES_PARALLEL(CHI_SLICES),
    .COUNTER_BITWIDTH(MAXCNT_BITWIDTH),
    .DOM_PIPELINE(DOM_PIPELINE),
    .SBOX_1CYCLE(SBOX_1CYCLE)
    ) RC_GEN (
    .ClkxCI(ClkxCI),
    .RstxRBI(RstxRBI),
    .RoundNrxDI(RoundCountxDP),
    .SliceNrxDI(CounterxDP),
    .NextSliceNrxDI(CounterxDN),
    .ResetRCxSI(resetRoundCountxS),
//    .EnableRCxSI((DOM_PIPELINE ? CounterxDP != 0 : 1) && ctrl_enable_chi_iota),
    .EnableRCxSI(ctrl_enable_chi_iota),
    .RCxDO(RCxD)
    );

assign IotaRCxDO = RCxD & {CHI_SLICES{(!CONNECT_ABSORB_CHI || InitialAbsorbDonexDP)}};

endmodule
