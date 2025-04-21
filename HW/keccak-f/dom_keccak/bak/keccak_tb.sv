`default_nettype uwire

module keccak_tb #(
) ( );
timeunit 1ns;
timeprecision 1ns;

//-----------------------------------------------------------------------------
// Test setup. Testing of all relevant parameter configurations is done
// by the run_tests.py script.
// Keccak[128,272]
parameter int RATE = 1088;
parameter int W = 64;
parameter int SHARES = 2;
parameter string TEST_FILE = "keccak_r128_c272_s2.ref";
parameter int ABSORB_LANES = RATE/W;
parameter int RESET_ITERATIVE = 0;
parameter int ABSORB_ITERATIVE = 1;
parameter int THETA_ITERATIVE = 1;
parameter int RHO_PI_ITERATIVE = 0;
parameter int CHI_IOTA_ITERATIVE = 1;
parameter int SLICES_PARALLEL = 1;
parameter int CHI_DOUBLE_CLK = 0;
parameter int LESS_RAND = 1;
parameter int DOM_PIPELINE = 1;

localparam ABSORB_SLICES = ABSORB_ITERATIVE ? SLICES_PARALLEL : W;
localparam THETA_SLICES = THETA_ITERATIVE ? SLICES_PARALLEL : ABSORB_SLICES;
localparam CHI_SLICES = CHI_IOTA_ITERATIVE ? SLICES_PARALLEL : W;
localparam CONNECT_ABSORB_CHI = (ABSORB_ITERATIVE && CHI_IOTA_ITERATIVE && RATE/W == ABSORB_LANES) ? 1 : 0;
localparam DATAOUT_SIZE = CONNECT_ABSORB_CHI ? 25*SLICES_PARALLEL : RATE;

//-----------------------------------------------------------------------------

// Typedefs
typedef logic[4:0][4:0][W-1:0] State3D_t;
typedef logic[24:0][W-1:0] State2D_t;
typedef bit[(SHARES*SHARES-SHARES)/2 - 1:0][4:0][4:0][CHI_SLICES-1:0] Rand_t;

// Clock and reset
logic ClkxCI;
always #5 ClkxCI = ~ClkxCI;
logic RstxRBI;

// Signals to/from Keccak
logic StartAbsorbxSI;
logic StartSqueezexSI;
logic[SHARES-1:0][4:0][4:0][W-1:0] AbsorbStatexD;
logic[SHARES-1:0][ABSORB_LANES-1:0][ABSORB_SLICES-1:0] AbsorbSlicesxDI;
Rand_t ZxDI;
//logic[SHARES-1:0][RATE/W-1:0][W-1:0] DataxDO;
logic[SHARES*DATAOUT_SIZE-1:0] DataxDO;
logic ReadyxSO;

integer data_file; // file handler
integer STDERR = 32'h8000_0002;

keccak_top #(
        .RATE(RATE),
        .W(W),
        .SHARES(SHARES),
        .SLICES_PARALLEL(SLICES_PARALLEL),
        .ABSORB_LANES(ABSORB_LANES),
        .RESET_ITERATIVE(RESET_ITERATIVE),
        .ABSORB_ITERATIVE(ABSORB_ITERATIVE),
        .THETA_ITERATIVE(THETA_ITERATIVE),
        .RHO_PI_ITERATIVE(RHO_PI_ITERATIVE),
        .CHI_IOTA_ITERATIVE(CHI_IOTA_ITERATIVE),
        .CHI_DOUBLE_CLK(CHI_DOUBLE_CLK),
        .LESS_RAND(LESS_RAND),
        .DOM_PIPELINE(DOM_PIPELINE)
    )
    DUT (
        .ClkxCI,
        .RstxRBI,
        .RandomnessAvailablexSI(1'b1),
        .StartAbsorbxSI,
        .StartSqueezexSI,
        .ReadyxSO,
        //.AbsorbLanesxDI,
        .AbsorbSlicesxDI,
        .ZxDI,
        .DataxDO
    );

task choose_absorb_data (input int lane_nr, input int slice_nr);
    for(int i = 0; i < SHARES; i++) begin
        for(int j = 0; j < ABSORB_LANES; j++) begin
            automatic int x = (lane_nr + j) % 5;
            automatic int y = (lane_nr + j) / 5;
            // $display("lane_nr +j = %2d (x=%1d,y=%1d,z=%2d, Bit: %8x)", lane_nr+j,x,y,slice_nr, AbsorbStatexD[i][x][y][slice_nr +: ABSORB_SLICES]);
            assert(lane_nr + j < RATE/W) else $fatal(1, "Testbench error");
            AbsorbSlicesxDI[i][(lane_nr + j)%ABSORB_LANES] = AbsorbStatexD[i][x][y][slice_nr +: ABSORB_SLICES];
        end
    end
endtask


task check(
    input State2D_t expected,
    input State2D_t[SHARES-1:0] to_check
    );
    automatic State2D_t received = '0;
    for (int i = 0; i < SHARES; i++) begin
        received ^= to_check[i];
    end

    if(received !== expected)begin
        #3;
        $fdisplay(STDERR, "Expected: %h", expected);
        $fdisplay(STDERR, "Received: %h", received);
        $fatal(1, "State check failed");
    end
endtask

//typedef bit[(SHARES*SHARES-SHARES)/2 - 1:0][4:0][4:0][CHI_SLICES-1:0] Rand_t;
function Rand_t random_vec();
    automatic Rand_t result;
    for(int i=0; i<(SHARES*SHARES-SHARES)/2; i++)
        for(int x=0; x<5; x++)
            for(int y=0; y<5; y++)
                for(int z=0; z<(W/32+1); z++)
                    result[i][x][y] = {result[i][x][y], $random()};
    return result;
endfunction

Rand_t ZxDP;
always @(posedge ClkxCI) begin
    ZxDP <= random_vec();
end
assign ZxDI = ZxDP;

initial begin
    static int state_nr = 0;
    static string state_name = "";
    static State2D_t state_data = '0;
    static State2D_t received = '0;
    static int assigns = 0;

    // Reset
    AbsorbStatexD = '0;
    StartAbsorbxSI = 0;
    StartSqueezexSI = 0;

    ClkxCI = 0;
    RstxRBI = 0;
    repeat(2) @(posedge ClkxCI) #1;
    RstxRBI = 1;
    @(posedge ClkxCI) #1;

    data_file = $fopen(TEST_FILE, "r");
    if (data_file == 0) begin
        $fatal(1, "[ERROR] data_file handle was NULL");
    end
    
    $display("Configuration");
    $display("RATE = %4d", RATE);
    $display("W = %2d", W);
    $display("SHARES = %2d", SHARES);
    $display("ABSORB_LANES = %2d", ABSORB_LANES);
    $display("RESET_ITERATIVE = %1d", RESET_ITERATIVE);
    $display("ABSORB_ITERATIVE = %1d", ABSORB_ITERATIVE);
    $display("THETA_ITERATIVE = %1d", THETA_ITERATIVE);
    $display("RHO_PI_ITERATIVE = %1d", RHO_PI_ITERATIVE);
    $display("CHI_IOTA_ITERATIVE = %1d", CHI_IOTA_ITERATIVE);
    $display("SLICES_PARALLEL = %1d", SLICES_PARALLEL);
    $display("CHI_DOUBLE_CLK = %1d", CHI_DOUBLE_CLK);
    $display("LESS_RAND = %1d", LESS_RAND);
    $display("DOM_PIPELINE = 1%d", DOM_PIPELINE);
    while (!$feof(data_file)) begin
        assigns = $fscanf(data_file, "%s %h %d\n", state_name, state_data, state_nr);
        if(assigns < 1)begin
            $fdisplay(STDERR, "%s %h %d", state_name, state_data, state_nr);
            $fatal(1, "Couldn't read input");
        end

        case(state_name)
        "reset": begin
            $display("reset");
            RstxRBI = 0;
            @(posedge ClkxCI) #1;
            RstxRBI = 1;
            @(posedge ClkxCI) #1;
            wait(DUT.KECCAK_CONTROL.CtrlStatexDP === DUT.KECCAK_CONTROL.IDLE) #1;
        end
        "inputshare": begin
            // transform to slice based structure
            for(int lane_nr=0; lane_nr < RATE/W; lane_nr++) begin
                AbsorbStatexD[state_nr][lane_nr%5][lane_nr/5] = state_data[RATE/W - 1 - lane_nr];
            end
            $display("inputshare %0d: %h", state_nr, AbsorbStatexD[state_nr]);
        end
        "absorb": begin
            // absorb lanes
            for(int lane_nr = 0; lane_nr < (RATE/W); lane_nr+=ABSORB_LANES) begin
                for(int slice_nr = 0; slice_nr < W; slice_nr+=ABSORB_SLICES) begin
//                    while($random() % 2) begin
//                        @(posedge ClkxCI) #1; // random delay
//                    end
                    choose_absorb_data(lane_nr, slice_nr);
                    StartAbsorbxSI = 1;
                    wait(ReadyxSO == 1) @(posedge ClkxCI) #1;
                    StartAbsorbxSI = 0;
                    AbsorbSlicesxDI = $random();
                end
            end
            ReadyCheck: assert(ReadyxSO == 0) else $fatal(1, "[ERROR] Still ready...");

            StartAbsorbxSI = 0;
            AbsorbStatexD = '0;

            if(!CONNECT_ABSORB_CHI && !ABSORB_ITERATIVE) begin
                $display("absorb: %h", state_data);
                wait(DUT.KECCAK_CONTROL.CtrlStatexDP !== DUT.KECCAK_CONTROL.IDLE) #1;
                check(state_data, DUT.StatexD);
            end
        end
        "theta": begin
            if(CONNECT_ABSORB_CHI) begin
                $display("theta:  %h", state_data);
                wait(DUT.KECCAK_CONTROL.CtrlStatexDP === DUT.KECCAK_CONTROL.RHOPI) #1;
                check(state_data, DUT.StatexD);
                wait(DUT.KECCAK_CONTROL.CtrlStatexDP !== DUT.KECCAK_CONTROL.RHOPI);
            end
        end
        "rho_pi": begin
            // Just pass through. Write checks here in case something doesn't 
            // work as expected ;)
        end
        "chi": begin
            // Chi and Iota are done in the same cycle. Just pass through and 
            // check Iota step
        end
        "iota": begin
            if(!CONNECT_ABSORB_CHI) begin
                $display("iota:   %h", state_data);
                wait(DUT.KECCAK_CONTROL.enableRoundCountxS) @(posedge ClkxCI) #1;
                check(state_data, DUT.StatexD);
            end
        end
        default: begin
            $fatal(1, "[ERROR] unknown state '%s'", state_name);
        end
        endcase;
    end
    $fdisplay(STDERR, "[SUCCESS] Done! All tests passed");
    $finish();
end


endmodule
`default_nettype wire
