module tb_dom_keccak();
    
    // BASIC OPTIONS
    parameter RATE = 1600; // The rate of the sponge construction
    parameter W = 64;      // The width of one Keccak register, aka lane length
    parameter SHARES = 2;  // Number of shares to use (SHARES-1 == protection order).
    parameter ABSORB_LANES = RATE/W;
    parameter RESET_ITERATIVE = 0;
    parameter ABSORB_ITERATIVE = 0;//1;
    parameter THETA_ITERATIVE = 0;//1;
    parameter RHO_PI_ITERATIVE = 0;
    parameter CHI_IOTA_ITERATIVE = 0;//1;
    parameter SLICES_PARALLEL = 0;//1;
    parameter CHI_DOUBLE_CLK = 0;
    parameter LESS_RAND = 1;
    parameter DOM_PIPELINE = 1;

    // LOCAL PARAMETERS - DO NOT MODIFY
    parameter ABSORB_SLICES = ABSORB_ITERATIVE ? SLICES_PARALLEL : W;
    parameter THETA_SLICES = THETA_ITERATIVE ? SLICES_PARALLEL : ABSORB_SLICES;
    parameter CHI_SLICES = CHI_IOTA_ITERATIVE ? SLICES_PARALLEL : W;
    parameter CONNECT_ABSORB_CHI = (ABSORB_ITERATIVE && CHI_IOTA_ITERATIVE && RATE/W == ABSORB_LANES) ? 1 : 0;
    parameter DATAOUT_SIZE = (CONNECT_ABSORB_CHI) ? 25*SLICES_PARALLEL : RATE;

    
    reg clk, rst_n;
    reg [SHARES*(ABSORB_LANES*ABSORB_SLICES)-1:0] hsh_AbsorbSlicesxDI;
    reg [(SHARES*SHARES-SHARES)/2 * 25 * CHI_SLICES - 1:0] hsh_ZxDI;
    reg hsh_StartAbsorbxSI, hsh_StartSqueezexSI;
    wire [SHARES*DATAOUT_SIZE-1:0] hsh_DataxDO;
    wire hsh_RandomnessAvailablexSI, hsh_ReadyxSO;
    assign hsh_RandomnessAvailablexSI = 1;


    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 1;
        hsh_AbsorbSlicesxDI = 3200'h0;
        hsh_ZxDI = 1600'h0;
        hsh_StartAbsorbxSI = 0;
        hsh_StartSqueezexSI = 0;
        #100; rst_n = 0; #100 rst_n = 1;
        #100 hsh_StartAbsorbxSI = 1; #10 hsh_StartAbsorbxSI = 0;
        #100000 
        $stop; 
    end




    keccak_top #(
        .RATE(RATE),
        .W(W),
        .SHARES(SHARES),
        .SLICES_PARALLEL(SLICES_PARALLEL),       // 1
        .ABSORB_LANES(ABSORB_LANES),
        .RESET_ITERATIVE(RESET_ITERATIVE),       // 1 ? 0
        .ABSORB_ITERATIVE(ABSORB_ITERATIVE),     // 1
        .THETA_ITERATIVE(THETA_ITERATIVE),       // 1
        .RHO_PI_ITERATIVE(RHO_PI_ITERATIVE),     // 0
        .CHI_IOTA_ITERATIVE(CHI_IOTA_ITERATIVE), // 1
        .CHI_DOUBLE_CLK(CHI_DOUBLE_CLK),         // 1 ? 0
        .LESS_RAND(LESS_RAND),                   // 1
        .DOM_PIPELINE(DOM_PIPELINE)              // 1
    )
    hsh (
        .ClkxCI(clk),
        .RstxRBI(rst_n),
        .RandomnessAvailablexSI(hsh_RandomnessAvailablexSI),
        .StartAbsorbxSI(hsh_StartAbsorbxSI),
        .StartSqueezexSI(hsh_StartSqueezexSI),
        .ReadyxSO(hsh_ReadyxSO),
        .AbsorbSlicesxDI(hsh_AbsorbSlicesxDI),
        .ZxDI(hsh_ZxDI),
        .DataxDO(hsh_ReadyxSO)
    );


endmodule