`timescale  1ns/1ns

module keccakf1600(
  input clk, reset,
  input init, go, absorb, absorb_extend,
  input squeeze_extend_0, squeeze_extend_1,
  input [31:0] din_0, din_1,
  output done,
  output [31:0] result_out
);
  reg busy;
  reg [7:0] random_8bit;
  wire rst_n, uut_valid;
  reg [1599:0] din_sftreg0, din_sftreg1;
  wire [1599:0] din_share0, din_share1, dout_0, dout_1;
  assign rst_n = ~go;
  assign din_share0 = busy ? din_sftreg0 : 1600'h0;
  assign din_share1 = busy ? din_sftreg1 : 1600'h0;
  assign result_out = squeeze_extend_0 ? din_sftreg0[31:0] : (squeeze_extend_1 ? din_sftreg1[31:0] : din_sftreg0[31:0]);
  assign done = uut_valid;

  always @(posedge clk) begin
    if (reset | init) busy <= 0;
    else if (go) busy <= 1;
    else if (uut_valid) busy <= 0;
    else busy <= busy;
  end

  wire [31:0] din_mux_0, din_mux_1;
  assign din_mux_0 = absorb ? din_0 : 32'h0;
  assign din_mux_1 = absorb ? din_1 : 32'h0;
  //assign din_mux_0 = squeeze_extend_0 ? din_sftreg0[31:0] : (absorb ? din_sftreg0[31:0]^din_0 : din_0);
  //assign din_mux_1 = squeeze_extend_0 ? din_sftreg1[31:0] : (absorb ? din_sftreg1[31:0]^din_1 : din_1);
  

  always @(posedge clk) begin
    if (reset | init) din_sftreg0 <= 0;
    else if (absorb_extend | squeeze_extend_0) din_sftreg0 <= {din_mux_0^din_sftreg0[31:0], din_sftreg0[1599:32]};
    else if (uut_valid) din_sftreg0 <= dout_0;
    
    if (reset | init) din_sftreg1 <= 0;
    else if (absorb_extend | squeeze_extend_1) din_sftreg1 <= {din_mux_1^din_sftreg1[31:0], din_sftreg1[1599:32]};
    else if (uut_valid) din_sftreg1 <= dout_1;
  end

  always @(posedge clk) begin
    if (reset) random_8bit <= 8'he5;
    else if (busy | go) random_8bit <= {random_8bit[5:0], random_8bit[4]^random_8bit[0], random_8bit[5]^random_8bit[1]};
  end 

  // CLLFO-SHA-3
  keccak_top CLLFO_SHA_3(
    .clk(clk), 
    .rst_n(rst_n),
    .random_i(random_8bit[1:0]),
    .din_share0_i(din_share0),
    .din_share1_i(din_share1),
    .dout_share0_o(dout_0),
    .dout_share1_o(dout_1),
    .dout_vld_o(uut_valid)
  );

endmodule