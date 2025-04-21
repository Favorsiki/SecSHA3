// module StateMachine(
//     input CLK, RESET, ENABLE,
//     output DONE,
//     output CONST
// );
//     reg ENABLE_LFSR, RESET_LFSR;
//     reg [7:0] LFSR;
//     reg [2:0] state, next_state;

//     localparam S_RESET = 3'd0,S_IDLE=3'd1, S_ROUND=3'd2, S_ROUND2=3'd3, S_ROUND3=3'd4, S_DONE = 3'd4;

//     always @(posedge CLK) begin
//         if (RESET_LFST) LFSR <= 8'h0;
//         else if (ENABLE_LFSR) LFSR <= {LFSR[6:0], (LFSR[7] ^ LFSR[5] ^ LFSR[4] ^ LFSR[3])};
//     end 

//     always @(LFSR) begin 
//         case(LFSR)
//             8'h01  : CONST <= 64'h0000000000000001;
//             8'h02  : CONST <= 64'h0000000000008082;
//             8'h04  : CONST <= 64'h800000000000808a;
//             8'h08  : CONST <= 64'h8000000080008000;
//             8'h11  : CONST <= 64'h000000000000808b;
//             8'h23  : CONST <= 64'h0000000080000001;
//             8'h47  : CONST <= 64'h8000000080008081;
//             8'h8e  : CONST <= 64'h8000000000008009;
//             8'h1c  : CONST <= 64'h000000000000008a;
//             8'h38  : CONST <= 64'h0000000000000088;
//             8'h71  : CONST <= 64'h0000000080008009;
//             8'he2  : CONST <= 64'h000000008000000a;
//             8'hc4  : CONST <= 64'h000000008000808b;
//             8'h89  : CONST <= 64'h800000000000008b;
//             8'h12  : CONST <= 64'h8000000000008089;
//             8'h25  : CONST <= 64'h8000000000008003;
//             8'h4b  : CONST <= 64'h8000000000008002;
//             8'h97  : CONST <= 64'h8000000000000080;
//             8'h2e  : CONST <= 64'h000000000000800a;
//             8'h5c  : CONST <= 64'h800000008000000a;
//             8'hb8  : CONST <= 64'h8000000080008081;
//             8'h70  : CONST <= 64'h8000000000008080;
//             8'he0  : CONST <= 64'h0000000080000001;
//             8'hc0  : CONST <= 64'h8000000080008008;             
//             default: CONST <= 64'h0000000000000000;
//         endcase
//     end 

    
//     always @(posedge CLK) begin
//         if (RESET)  state <= S_RESET;
//         else        state <= next_state;
//     end 

//     always @(*) begin
//         ENABLE_LFSR <= 0;
//         RESET_LFSR  <= 0;
//         DONE        <= 0;
//         next_state  <= state;
        
//         case (state)
//             S_RESET : begin 
//                 ENABLE_LFSR <= 0;
//                 RESET_LFSR <= 1;
//                 next_state <= S_IDLE;
//             end 
//             S_IDLE : begin
//                 ENABLE_LFSR <= 0;
//                 RESET_LFSR  <= 0;
//                 DONE        <= 0;
//                if (ENABLE) next_state <= S_ROUND;
//             end
//             S_ROUND : begin
//                 ENABLE_LFSR <= 1;
//                 RESET_LFSR  <= 0;
//                 DONE        <= 0;
//                 next_state <= S_ROUND2;
//             end
//             S_ROUND2 : begin
//                 ENABLE_LFSR <= 0;
//                 RESET_LFSR  <= 0;
//                 DONE        <= 0;
//                 if (lfsr == 8'hc0) next_state <= S_DONE;
//                 else next_state <= S_ROUND3;
//             end
//             S_ROUND3 : begin
//                 ENABLE_LFSR <= 0;
//                 RESET_LFSR  <= 0;
//                 DONE        <= 0;
//                 next_state <= S_ROUND;
//             end
//             S_DONE : begin
//                 ENABLE_LFSR <= 0;
//                 RESET_LFSR  <= 1;
//                 DONE        <= 1;
//                 next_state <= S_IDLE;
//             end 
//         endcase
//     end 

// endmodule