`timescale  1ns/1ns

module cllfo_keccakf1600(
    input           clk,
    input           rst_n,
    input           init,
    input           go,
    input           absorb,
    input           extend,
    input           squeeze,
    input           squeeze_indx,
    input    [31:0] din_0, din_1,
    output          done,
    output   [31:0] result
);
  reg busy;
  wire [1:0] rand_data;
  wire uut_valid, cllfo_start;
  reg [1599:0] din_sftreg0, din_sftreg1;
  wire [1599:0] din_share0, din_share1, dout_0, dout_1;
  assign result = squeeze ? (squeeze_indx ? din_sftreg1[31:0] : din_sftreg0[31:0]) : din_sftreg1[31:0];
  assign done = uut_valid;

  reg go_ff1, go_ff2;
  always @(posedge clk) begin
    go_ff1 <= go;
    go_ff2 <= go_ff1;
  end 
  wire randGen_ren;
  assign randGen_ren = 1;
  //assign randGen_ren = go & (~go_ff1);
  assign cllfo_start = go_ff1 & (~go_ff2);

  always @(posedge clk) begin
    if (!rst_n | init) busy <= 0;
    else if (go) busy <= 1;
    else if (uut_valid) busy <= 0;
    else busy <= busy;
  end

  wire [31:0] din_mux_0, din_mux_1;
  assign din_mux_0 = absorb ? din_0 : 32'h0;
  assign din_mux_1 = absorb ? din_1 : 32'h0;
  //assign din_mux_0 = squeeze_extend_0 ? din_sftreg0[31:0] : (absorb ? din_sftreg0[31:0]^din_0 : din_0);
  //assign din_mux_1 = squeeze_extend_0 ? din_sftreg1[31:0] : (absorb ? din_sftreg1[31:0]^din_1 : din_1);
  
  wire squeeze_0, squeeze_1;
  assign squeeze_0 = (squeeze && (squeeze_indx == 1'b0));
  assign squeeze_1 = (squeeze && (squeeze_indx == 1'b1));
  

  always @(posedge clk) begin
    if (!rst_n | init) din_sftreg0 <= 0;
    else if (squeeze | extend | absorb) din_sftreg0 <= {din_mux_0^din_sftreg0[31:0], din_sftreg0[1599:32]};
    else if (uut_valid) din_sftreg0 <= dout_0;
    
    if (!rst_n | init) din_sftreg1 <= 0;
    else if (squeeze | extend | absorb) din_sftreg1 <= {din_mux_1^din_sftreg1[31:0], din_sftreg1[1599:32]};
    else if (uut_valid) din_sftreg1 <= dout_1;
  end

  assign din_share0 = busy ? din_sftreg0 : 1600'h0;
  assign din_share1 = busy ? din_sftreg1 : 1600'h0;

  // CLLFO-SHA-3
  keccak_top CLLFO_SHA_3(
    .clk(clk), 
    .rst_n(rst_n),
    .start(cllfo_start),
    .random_i(rand_data),
    .din_share0_i(din_share0),
    .din_share1_i(din_share1),
    .dout_share0_o(dout_0),
    .dout_share1_o(dout_1),
    .dout_vld_o(uut_valid)
  );

  prng #(.OUTLENGTH(2)) randGen_2(.clk(clk), .rst_n(rst_n), .ren(randGen_ren), .dout(rand_data));

endmodule