`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/09 16:00:06
// Design Name: 
// Module Name: hash_core_ykh
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// args[18:15]: absorb(1bit)||padding(1bit)||squeeze(1bit)||init(1bit)
// args[14:0] : mlen(11bit)||mask(1bit)||hash_mode(3bit)

// module SecKeccak_ctrl(
module demo_hash_core (
    input clk, rst_n, wen, dout_req,
    input [19:0] args,
    input [31:0] din,

    output reg [31:0] dout,
    output reg valid, squeeze_start, done
);
    // external control signals
    reg absorb_ff1, absorb_ff2;
    reg padding_ff1, padding_ff2;
    reg squeeze_ff1, squeeze_ff2;
    reg init_ff1, init_ff2;
    wire i_absorb, i_padding, i_squeeze, i_init;
    reg mask;
    reg [2:0] hash_mode;
    // the byte length of input/output data 
    reg [10:0] data_len;

    assign i_absorb   = absorb_ff1 && (!absorb_ff2);
    assign i_padding  = padding_ff1 && (!padding_ff2);
    assign i_squeeze  = squeeze_ff1 && (!squeeze_ff2);
    assign i_init     = init_ff1 && (!init_ff2);

    // hash core internal reset signal
    // The signal is used to reset internal registers
    wire    rst_init, rst; 
    assign  rst = ~rst_n; 
    assign  rst_init = rst | i_init;

    // Parse Args from input
    always @(posedge clk) begin
        absorb_ff1  <= args[18];
        absorb_ff2  <= absorb_ff1;
        padding_ff1 <= args[17];
        padding_ff2 <= padding_ff1;
        squeeze_ff1 <= args[16];
        squeeze_ff2 <= squeeze_ff1;
        init_ff1    <= args[15];
        init_ff2    <= init_ff1;

        if (rst_init) begin
            data_len <= 0;
        end else if (i_absorb || i_padding || i_squeeze) begin
            data_len <= args[14:4];
        end 

        if (rst) begin
            mask        <= 0;
            hash_mode   <= 0;
        end else if (i_init) begin // set signal when h_init is high
            mask        <= args[3];
            hash_mode   <= args[2:0];
        end 
    end 

    // internal control signals
    reg fifo_ren;
    // fifo0 control signals
    reg fifo0_wen;
    wire fifo0_ren, fifo0_full, fifo0_almost_full;
    wire fifo0_empty, fifo0_almost_empty;
    //wire [7:0] fifo0_data_count;
    reg [33:0] fifo0_din;
    wire [33:0] fifo0_dout;
    // fifo1 control signals 
    reg fifo1_wen;
    wire fifo1_ren, fifo1_full, fifo1_almost_full;
    wire fifo1_empty, fifo1_almost_empty;
    //wire [7:0] fifo1_data_count;
    reg [33:0] fifo1_din;
    wire [33:0] fifo1_dout;
    // keccak control signals
    reg k_go, k_squeeze, k_squeeze_indx, k_absorb, k_extend, reg_extend;
    reg [31:0] k_din0, k_din1;
    wire k_init, k_done, k_absorb_extend_done;// k_squeeze_extend_done;
    wire [31:0] k_dout;
    // internal operation signals
    // registers, delay the input
    reg [31:0] h_din_r;
    reg h_wen_r;
    // set high when completely read data in absor_state 
    reg read_done;
    // set high after several k_done rise
    reg absorb_done;
    // input data counter, Bytes
    reg [11:0] din_cnt;
    
    /****************************************************
                    Finite State Machine
    ****************************************************/
    // MAIN FSM state parameter
    parameter h_IDLE=4'd0, h_ABSORB_IDLE=4'd1,  h_ABSORB_EXEC=4'd2, h_ABSORB_DONE=4'd3;
    parameter h_PADDING=4'd4, h_PADDING_DONE=4'd5, h_SQUEEZE_IDLE=4'd6, h_SQUEEZE_EXEC=4'd7;
    parameter h_SQUEEZE_SH1_OUT=4'd8, h_SQUEEZE_SH2_OUT=4'd9, h_SQUEEZE_DONE=4'd10;// h_SQUEEZE_EXTEND=4'd11;
    // READ FSM state parameter
    parameter h_READ_IDLE=3'd0, h_READ_sh0=3'd1, h_READ_sh1=3'd2, h_READ_sh2=3'd3;
    parameter h_READ_ABSORB=3'd4, h_READ_PADDING0=3'd5, h_READ_PADDING1=3'd6;
    // FSM signals
    reg [3:0] h_state, h_next_state, h_state_r;
    reg [2:0] h_READ_CS, h_READ_NS, h_READ_CS_r;
    // set h_state and h_READ_CS
    always @(posedge clk) begin
        if (rst_init) h_state <= h_IDLE;
        else h_state <= h_next_state;

        if (rst_init) h_READ_CS <= h_READ_IDLE;
        else h_READ_CS <= h_READ_NS;

        h_state_r <= h_state;
        h_READ_CS_r <= h_READ_CS;
    end
    // READ FSM 
    always @(*) case(h_READ_CS)
        h_READ_IDLE     : h_READ_NS = i_absorb ? (mask ? h_READ_sh1 : h_READ_sh0) : (i_padding ? h_READ_PADDING0 : h_READ_IDLE); 
        h_READ_sh1      : h_READ_NS = read_done ? h_READ_sh0    : h_READ_sh1;
        h_READ_sh0      : h_READ_NS = read_done ? h_READ_ABSORB : h_READ_sh0;
        h_READ_ABSORB   : h_READ_NS = absorb_done ? h_READ_IDLE : h_READ_ABSORB;
        h_READ_PADDING0 : h_READ_NS = (h_byte_sum==k_parameter_b) ? h_READ_PADDING1 : h_READ_PADDING0;
        h_READ_PADDING1 : h_READ_NS = k_absorb_extend_done ? h_READ_IDLE : h_READ_PADDING1;
        default         : h_READ_NS = h_READ_IDLE;
    endcase 
    // MAIN FSM 
    always @(*) case(h_state)
        h_IDLE              : h_next_state = h_ABSORB_IDLE;
        h_ABSORB_IDLE       : h_next_state = i_absorb ? h_ABSORB_EXEC : (i_padding ? h_PADDING: h_ABSORB_IDLE);
        h_ABSORB_EXEC       : h_next_state = absorb_done ? h_ABSORB_DONE : h_ABSORB_EXEC; 
        h_ABSORB_DONE       : h_next_state = h_ABSORB_IDLE; 
        h_PADDING           : h_next_state = k_absorb_extend_done ? h_PADDING_DONE : h_PADDING;
        h_PADDING_DONE      : h_next_state = h_SQUEEZE_IDLE;
        h_SQUEEZE_IDLE      : h_next_state = i_squeeze ? h_SQUEEZE_EXEC : h_SQUEEZE_IDLE;
        h_SQUEEZE_EXEC      : h_next_state = k_done ? h_SQUEEZE_SH1_OUT : h_SQUEEZE_EXEC;
        h_SQUEEZE_SH1_OUT   : h_next_state = k_squeeze_sh_done ? h_SQUEEZE_SH2_OUT : h_SQUEEZE_SH1_OUT;
        h_SQUEEZE_SH2_OUT   : h_next_state = k_squeeze_sh_done ? h_SQUEEZE_DONE : h_SQUEEZE_SH2_OUT;
        h_SQUEEZE_DONE      : h_next_state = h_SQUEEZE_IDLE;
        default             : h_next_state = h_IDLE;
    endcase

    /****************************************************
             Implementation of READ FSM 
    ****************************************************/
    // delay the input
    always @(posedge clk) begin
        if (rst) begin
            h_din_r <= 32'h0;
            h_wen_r <= 0;
        end else begin
            h_din_r <= din;
            h_wen_r <= wen;
        end 
    end 
    // Optimize the compare "din_cnt >= data_len"
    wire flag_cmp;
    reg flag_cmp_r;
    wire signed [12:0]  Dcnt_SUB_Dlen;
    wire [11:0] din_cnt_next, h_wen_r_x4;
    assign h_wen_r_x4 = {9'b0, h_wen_r, 2'b0};
    assign din_cnt_next = din_cnt + h_wen_r_x4;
    // Dcnt_SUB_Dlen[12]==0 if din_cnt >= data_len
    assign Dcnt_SUB_Dlen = din_cnt - data_len;
    assign flag_cmp = Dcnt_SUB_Dlen[12];
    always @(posedge clk )begin
        flag_cmp_r <= flag_cmp;
    end 
    always @(posedge clk) case (h_READ_CS)
        //h_READ_IDLE : din_cnt <= 12'd4;
        h_READ_sh0, h_READ_sh1: begin
            if ((~flag_cmp) && h_wen_r ) din_cnt <= 12'd4;
            else din_cnt <= din_cnt_next;
        end 
        default : din_cnt <= 12'd4;
    endcase
    
    // set read_done high when complete the read operation
    always @(*) case(h_READ_CS)
        //h_READ_IDLE : read_done <= 0;
        h_READ_sh0, h_READ_sh1: begin // dlen <= dincnt
            read_done = ~flag_cmp;
        end 
        default : read_done = 0;
    endcase

    reg fifo_padding_wen;
    reg [33:0] fifo_padding_din_0, fifo_padding_din_1;
    wire [7:0] End_padding, End_padding_sel, h_byte_sum;
    assign h_byte_sum = sftreg_next_state_cnt + FIFO_data_cnt_next;
    assign End_padding_sel = k_parameter_b - h_byte_sum;
    assign End_padding = (h_byte_sum+1 == k_parameter_b) ? 8'h80 : 8'h0;
    always @(posedge clk) case(h_READ_CS)
        // Padding stage
        h_READ_PADDING0 : begin
            if (h_READ_CS != h_READ_CS_r) begin
                fifo_padding_wen          <= 1;
                fifo_padding_din_0[33:32] <= 2'd1;
                fifo_padding_din_0[31:8]  <= 24'd0;
                fifo_padding_din_0[7:0]   <= k_parameter_padding ^ End_padding;
                fifo_padding_din_1[33:32] <= 2'd1;
                fifo_padding_din_1[31:0]  <= 32'h0;
            end else if (h_byte_sum+4 < k_parameter_b) begin
                fifo_padding_wen          <= 1;
                fifo_padding_din_0        <= 34'h0;
                fifo_padding_din_1        <= 34'h0;
            end else if (h_byte_sum < k_parameter_b) begin
                fifo_padding_wen          <= 1;
                fifo_padding_din_1[31:0]  <= 32'h0;
                case (End_padding_sel[1:0])
                    2'b00 : begin fifo_padding_din_0 <= 34'h080000000; fifo_padding_din_1[33:32] <=2'd0; end 
                    2'b01 : begin fifo_padding_din_0 <= 34'h100000080; fifo_padding_din_1[33:32] <=2'd1; end
                    2'b10 : begin fifo_padding_din_0 <= 34'h200008000; fifo_padding_din_1[33:32] <=2'd2; end
                    2'b11 : begin fifo_padding_din_0 <= 34'h300800000; fifo_padding_din_1[33:32] <=2'd3; end
                endcase
            end else begin
                fifo_padding_wen   <= 0;
                fifo_padding_din_0 <= 34'h0;
                fifo_padding_din_1 <= 34'h0;
            end 
        end 
        default : begin
            fifo_padding_wen       <= 0;
            fifo_padding_din_0     <= 34'h0;
            fifo_padding_din_1     <= 34'h0;
        end 
    endcase
    
    /****************************************************
                adding paddings in fifo_din
    fifo_padding == 00 : 4 Bytes in h_din_r[31:0] is valid
    fifo_padding == 01 : 1 Bytes in h_din_r[31:0] is valid
    fifo_padding == 10 : 2 Bytes in h_din_r[31:0] is valid
    fifo_padding == 11 : 3 Bytes in h_din_r[31:0] is valid
    ****************************************************/
    wire [1:0] fifo_padding;
    wire fifo_wen;
    assign fifo_wen = flag_cmp | flag_cmp_r;
    assign fifo_padding = flag_cmp ? 2'b00 : data_len[1:0];
    always @(*) case(h_READ_CS)
        h_READ_sh0: begin
            fifo0_wen = fifo_wen ? h_wen_r : 0;
            fifo0_din = fifo_wen ? {fifo_padding, h_din_r} : 34'h0;
        end 
        // Padding stage, 组合电路?
        h_READ_PADDING0 : begin
            fifo0_wen = fifo_padding_wen;
            fifo0_din = fifo_padding_din_0;
        end 
        default : begin
            fifo0_wen = 0;
            fifo0_din = 34'h0;
        end 
    endcase
    always @(*) case(h_READ_CS)
        h_READ_sh1 : begin
            fifo1_wen = fifo_wen ? h_wen_r : 0;
            fifo1_din = fifo_wen ? {fifo_padding, h_din_r} : 34'h0;
        end 
        h_READ_PADDING0 : begin
            fifo1_wen = mask ? fifo_padding_wen : 0;
            fifo1_din = fifo_padding_din_1;
        end 
        default : begin
            fifo1_wen = 0;
            fifo1_din = 34'h0;
        end 
    endcase

    // FIFO0 data counter 
    reg [9:0] FIFO_data_cnt;
    //reg fifo0_dout_valid;
    wire[9:0] FIFO_data_cnt_next;
    wire [2:0] fifo_din_strb, fifo_dout_strb, wen_cnt, ren_cnt;
    assign FIFO_data_cnt_next = FIFO_data_cnt + wen_cnt - ren_cnt;
    assign fifo_din_strb  = (fifo0_din[33] |fifo0_din[32])  ? {1'b0, fifo0_din[33:32]}  : 3'd4;
    assign fifo_dout_strb = (fifo0_dout[33]|fifo0_dout[32]) ? {1'b0, fifo0_dout[33:32]} : 3'd4;
    assign wen_cnt = fifo0_wen ? fifo_din_strb : 3'b0;
    assign ren_cnt = fifo0_ren ? fifo_dout_strb: 3'b0;
    always @(posedge clk) begin
        //fifo0_dout_valid <= fifo0_ren;
    end
    always @(posedge clk) case (h_state)
        h_IDLE                      : FIFO_data_cnt <= 0;
        h_ABSORB_EXEC, h_PADDING    : FIFO_data_cnt <= FIFO_data_cnt_next;
        default                     : FIFO_data_cnt <= FIFO_data_cnt;
    endcase

    /****************************************************
            Implementation of ABSORB,PADDING,SQUEEZE 
        step1 : fsm to read fifo data
    ****************************************************/
    parameter SHA3_256=3'd0, SHA3_512=3'd1;
    parameter SHAKE_128=3'd2, SHAKE_256=3'd3;
    parameter SHA3_224=3'd4, SHA3_384=3'd5;
    parameter cSHAKE128=3'd6, cSHAKE256=3'd7;
    reg [7:0] k_parameter_b, k_parameter_padding;
    wire[7:0] k_parameter_c;
    reg keccak_busy;
    // Parse parameter b from 'hash_mode' signal
    always @(*) case(hash_mode)
        SHAKE_128   : k_parameter_b = 8'd168; // 200 - 32 
        SHA3_224    : k_parameter_b = 8'd144; // 200 - 56
        SHAKE_256   : k_parameter_b = 8'd136; // 200 - 64
        SHA3_256    : k_parameter_b = 8'd136; // 200 - 64
        SHA3_384    : k_parameter_b = 8'd104; // 200 - 96
        SHA3_512    : k_parameter_b = 8'd72;  // 200 - 128
        cSHAKE128   : k_parameter_b = 8'd168;
        cSHAKE256   : k_parameter_b = 8'd136;
        default     : k_parameter_b = 8'd00;
    endcase
    always @(*) case (hash_mode)
        SHAKE_128   : k_parameter_padding = 8'h1F;
        SHA3_224    : k_parameter_padding = 8'h06;
        SHAKE_256   : k_parameter_padding = 8'h1F;
        SHA3_256    : k_parameter_padding = 8'h06;
        SHA3_384    : k_parameter_padding = 8'h06;
        SHA3_512    : k_parameter_padding = 8'h06;
        cSHAKE128   : k_parameter_padding = 8'h00;
        cSHAKE256   : k_parameter_padding = 8'h00;
        default     : k_parameter_padding = 8'h00;
    endcase
    assign k_parameter_c = 8'd200 - k_parameter_b;

    // FSM for reading FIFO
    reg [2:0] sftreg_state_cnt, sftreg_next_state_cnt;
    always @(posedge clk) begin
        if (rst_init) sftreg_state_cnt <= 0;
        else sftreg_state_cnt <= sftreg_next_state_cnt;
    end 
    // state transition
    //wire [2:0] sftreg_state_change;
    //wire [1:0] fifo_strb;
    //assign fifo_strb = fifo0_dout[33:32];
    //assign sftreg_state_change = (fifo_strb[0]|fifo_strb[1]) ? {1'b0, fifo_strb} : 3'd4; 
    always @(*) case (h_state)
        h_ABSORB_EXEC, h_PADDING : begin
            sftreg_next_state_cnt = {1'b0, sftreg_state_cnt[1:0]} + ren_cnt;
        end 
        default : sftreg_next_state_cnt = sftreg_state_cnt;
    endcase 

    // use shift reg to caching keccak input
    reg [55:0] k_din_sftreg0, k_din_sftreg1;
    always @(posedge clk) begin
        case (h_state)
            h_IDLE : k_din_sftreg0 <= 56'h0;
            h_ABSORB_EXEC, h_PADDING : case (ren_cnt)
                3'b001 : k_din_sftreg0 <= {fifo0_dout[7 :0], k_din_sftreg0[55: 8]};
                3'b010 : k_din_sftreg0 <= {fifo0_dout[15:0], k_din_sftreg0[55:16]};
                3'b011 : k_din_sftreg0 <= {fifo0_dout[23:0], k_din_sftreg0[55:24]};
                3'b100 : k_din_sftreg0 <= {fifo0_dout[31:0], k_din_sftreg0[55:32]};
                default: k_din_sftreg0 <= k_din_sftreg0;
            endcase
        endcase 
        case (h_state)
            h_IDLE : k_din_sftreg1 <= 56'h0;
            // considering that the fifo1 is empty when mask=0
            h_ABSORB_EXEC, h_PADDING : case ({mask,ren_cnt}) 
                4'b1001 : k_din_sftreg1 <= {fifo1_dout[7 :0], k_din_sftreg1[55: 8]};
                4'b1010 : k_din_sftreg1 <= {fifo1_dout[15:0], k_din_sftreg1[55:16]};
                4'b1011 : k_din_sftreg1 <= {fifo1_dout[23:0], k_din_sftreg1[55:24]};
                4'b1100 : k_din_sftreg1 <= {fifo1_dout[31:0], k_din_sftreg1[55:32]};
                default : k_din_sftreg1 <= k_din_sftreg1;
            endcase
        endcase 
    end 
       
    /****************************************************
            Implementation of ABSORB,PADDING,SQUEEZE 
        step2 : set fifo control signal to read data
    ****************************************************/ 
    // keccak_busy is high when execute keccak_absorb
    wire signed [10:0] Fcnt_SUB_b;
    wire Fcnt_CMP_b;
    assign Fcnt_SUB_b = FIFO_data_cnt + sftreg_state_cnt - k_parameter_b;
    assign Fcnt_CMP_b = Fcnt_SUB_b[10];
    always @(posedge clk) case (h_state)
        h_IDLE : keccak_busy <= 0;
        h_ABSORB_EXEC, h_PADDING : begin
            // if ((FIFO_data_cnt >= k_parameter_b) && ~keccak_busy)
            if (~(Fcnt_CMP_b | keccak_busy)) begin 
                keccak_busy <= 1;
            end else if (k_done && keccak_busy) begin 
                keccak_busy <= 0;
            end
        end 
        h_SQUEEZE_EXEC : begin
            if (~keccak_busy) begin
                keccak_busy <= 1;
            end else if (k_absorb_extend_done) begin
                keccak_busy <= 0;
            end 
        end 
        default : keccak_busy <= 0;
    endcase 

    // READ FIFO 
    assign fifo0_ren = fifo_ren;
    assign fifo1_ren = mask ? fifo_ren : 0;
    always @(*) case(h_state)
        h_IDLE : fifo_ren = 0;
        h_ABSORB_EXEC, h_PADDING : begin
            if (keccak_busy && ((k_absorb_cnt<<2) < k_parameter_b)) begin
                fifo_ren = 1;
            end else begin
                fifo_ren = 0;
            end         
        end 
        default : fifo_ren = 0;
    endcase
    reg fifo_ren_r, fifo_ren_negedge;
    always @(posedge clk) begin
        fifo_ren_r <= fifo_ren;
        fifo_ren_negedge <= (~fifo_ren) && fifo_ren_r;
    end 

    // need to be debuged 
    reg [5:0] k_absorb_cnt;
    wire k_din_sftreg_valid;
    assign k_din_sftreg_valid = sftreg_next_state_cnt[2];
    always @(posedge clk) begin
        if (rst_init || ~keccak_busy) begin
            k_absorb_cnt <= 6'd0;
        end else begin
            k_absorb_cnt <= k_absorb_cnt + k_din_sftreg_valid;
        end
    end 

    reg [5:0] k_extend_cnt;
    wire[5:0] k_extend_cnt_next;
    wire k_squeeze_sh_done;
    assign k_absorb_extend_done  = (k_extend_cnt == k_parameter_c[7:2]);
    //assign k_squeeze_extend_done = (k_extend_cnt == k_parameter_c[7:2]);
    assign k_squeeze_sh_done     = (k_extend_cnt == 6'd50) && dout_req;
    //wire k_squeeze_done;
    //assign k_squeeze_done = (k_extend_cnt == k_parameter_b[7:2]);
    assign k_extend_cnt_next = k_extend_cnt + 1;
    // 注意: 及时置0
    always @(posedge clk) case (h_state)
        h_IDLE : k_extend_cnt <= 0;
        h_ABSORB_EXEC, h_PADDING : begin
            if (fifo_ren_negedge | reg_extend) k_extend_cnt <= k_extend_cnt_next;
            else k_extend_cnt <= 0;
        end 
        h_SQUEEZE_EXEC : k_extend_cnt <= 1;
        h_SQUEEZE_SH1_OUT, h_SQUEEZE_SH2_OUT : begin
            if (k_squeeze_sh_done) k_extend_cnt <= 1;
            else if (dout_req) k_extend_cnt <= k_extend_cnt_next;
        end 
        default : k_extend_cnt <= 0;
    endcase
    /****************************************************
            Implementation of ABSORB,PADDING,SQUEEZE 
        step3 : set keccakf1600 control signals 
    ****************************************************/ 
    // set 'k_init'
    assign k_init = i_init;

    // set 'k_din0' and 'k_din1'
    always @(*) case (h_state)
        h_ABSORB_EXEC, h_PADDING : case (sftreg_state_cnt)
            3'd4 : begin
                k_din0 = k_din_sftreg0[55:24];
                k_din1 = k_din_sftreg1[55:24];
            end 
            3'd5 : begin
                k_din0 = k_din_sftreg0[47:16];
                k_din1 = k_din_sftreg1[47:16];
            end 
            3'd6 : begin
                k_din0 = k_din_sftreg0[39:8];
                k_din1 = k_din_sftreg1[39:8];
            end 
            3'd7 : begin
                k_din0 = k_din_sftreg0[31:0];
                k_din1 = k_din_sftreg1[31:0];
            end 
            default : begin
                k_din0 = 32'h0;
                k_din1 = 32'h0;
            end 
        endcase 
        default : begin
            k_din0      = 32'h0;
            k_din1      = 32'h0;
        end 
    endcase

    // set 'k_absorb'
    always @(*) case(h_state)
        h_ABSORB_EXEC, h_PADDING : begin 
            case (sftreg_state_cnt)
            3'd4, 3'd5, 3'd6, 3'd7 : begin
                k_absorb = 1;
            end 
            default : begin
                k_absorb = 0;
            end 
            endcase
        end 
        default : begin
            k_absorb = 0;
        end 
    endcase

    // set 'k_squeeze' and 'k_squeeze_indx'
    always @(*) case (h_state)
        h_SQUEEZE_SH1_OUT : begin
            k_squeeze = dout_req;
            k_squeeze_indx = 0;
        end
        h_SQUEEZE_SH2_OUT : begin
            k_squeeze = dout_req;
            k_squeeze_indx = 1;
        end
        default : begin
            k_squeeze = 0;
            k_squeeze_indx = 0;
        end 
    endcase

    // set 'k_extend'
    always @(*) case (h_state)
        h_ABSORB_EXEC, h_PADDING : begin
            k_extend = reg_extend;
        end 
        default : begin
            k_extend = 0;
        end 
    endcase
    always @(posedge clk) case (h_state)
        h_IDLE : reg_extend <= 0;
        h_ABSORB_EXEC, h_PADDING : begin
            if (fifo_ren_negedge) reg_extend <= 1;
            else if (k_absorb_extend_done) reg_extend <= 0;
            else reg_extend <= reg_extend; 
        end
        default : reg_extend <= 0;
    endcase

    // set 'k_go'
    always @(posedge clk) case (h_state)
        h_IDLE : k_go <= 0;
        h_ABSORB_EXEC: begin
            if (k_absorb_extend_done) k_go <= 1;
            else k_go <= 0;
        end 
        h_SQUEEZE_EXEC : begin
            if (h_state == h_state_r) k_go <= 0;
            else k_go <= 1;
        end 
        default : k_go <= 0;
    endcase

    /****************************************************
            Implementation of ABSORB,PADDING,SQUEEZE
        step4 : rise absorb_done signal
    ****************************************************/ 
    always @(*) case (h_state)
        h_IDLE : absorb_done <= 0;
        h_ABSORB_EXEC : begin
            // if (h_READ_CS == h_READ_ABSORB) && (fifo0_data_count >= k_parameter_b)
            if ((h_READ_CS == h_READ_ABSORB) && Fcnt_CMP_b && ~keccak_busy) begin
                absorb_done <= 1;
            end else begin
                absorb_done <= 0;
            end 
        end
        default : absorb_done <= 0;
    endcase

    /****************************************************
             Hash_core Output Logic
    ****************************************************/
    always @(*) case (h_state)
        h_SQUEEZE_SH1_OUT, h_SQUEEZE_SH2_OUT : begin
            if (k_extend_cnt > k_parameter_b[7:2]) begin
                valid = k_squeeze;
                dout   = 1;
            end else begin
                valid = k_squeeze;
                dout   = k_dout;
            end 
            squeeze_start = 1;
        end 
        default : begin
            squeeze_start = 0;
            valid = 0;
            dout  = 1;
        end 
    endcase
    always @(posedge clk) case (h_state)
        h_ABSORB_DONE, h_PADDING_DONE, h_SQUEEZE_DONE: begin
            done <= 1;
        end
        default : begin
            done <= 0;
        end 
    endcase

    // 200x32 is enough, (128+50)*32
    // the FIFO is in FWFT mode
    // the FIFO need 'almost_full' and 'almost_empty' signal
    fifo_200x34_ram fifo0(
        .clk(clk), 
        .srst(rst_init), 
        .wr_en(fifo0_wen),
        .din(fifo0_din),
        .full(fifo0_full),
        .almost_full(fifo0_almost_full),
        .rd_en(fifo0_ren),
        .dout(fifo0_dout),
        .empty(fifo0_empty),
        .almost_empty(fifo0_almost_empty));
        
    fifo_200x34_ram fifo1(
        .clk(clk), 
        .srst(rst_init), 
        .wr_en(fifo1_wen),
        .din(fifo1_din),
        .full(fifo1_full),
        .almost_full(fifo1_almost_full),
        .rd_en(fifo1_ren),
        .dout(fifo1_dout),
        .empty(fifo1_empty),
        .almost_empty(fifo1_almost_empty));

    demo_keccakf1600 keccak(
        .clk(clk),
        .rst_n(rst_n),
        .init(k_init),
        .go(k_go),
        .absorb(k_absorb),
        .extend(k_extend),
        .squeeze(k_squeeze),
        .squeeze_indx(k_squeeze_indx),
        .din_0(k_din0),
        .din_1(k_din1),
        .done(k_done),
        .result(k_dout)
    );

    // ila_hc ila(
    //     .clk(clk),
    //     .probe0(i_init),
    //     .probe1(wen),
    //     .probe2(dout_req),
    //     .probe3(din),
    //     .probe4(dout),
    //     .probe5(k_extend_cnt),
    //     .probe6(squeeze_start),
    //     .probe7(done),
    //     .probe8(h_state),
    //     .probe9(args)
    // );

endmodule