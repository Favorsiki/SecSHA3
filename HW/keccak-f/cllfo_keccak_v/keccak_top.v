// keccak_top, the top module of the first-order masked keccak design.
// Copyright (C) 2024, Cankun Zhao, Leibo Liu. All rights reserved.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTERS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// INCLUDING NEGLIGENCE OR OTHERWISE ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Please see LICENSE and README for license and further instructions.
//
// Contact: zhaock97@gmail.com


module keccak_top (
  input             clk,
  input             rst_n,
  input  [   2-1:0] random_i, // fresh randomness input
  input  [1600-1:0] din_share0_i,
  input  [1600-1:0] din_share1_i,

  output wire [1600-1:0] dout_share0_o,
  output wire [1600-1:0] dout_share1_o,
  output wire            dout_vld_o // high-level active
);

  // Control
  wire [64-1:0] iota_round_constant;
  wire          round_in_select;

  keccak_control control_inst(
    .clk                  (clk),
    .rst_n                (rst_n),
    .iota_round_constant_o(iota_round_constant),
    .round_in_select_o    (round_in_select),
    .dout_vld_o           (dout_vld_o)
  );

  // Data input & output
  wire [2*1600-1:0] state_round_in, state_round_out;

  assign state_round_in = round_in_select ? {din_share1_i, din_share0_i} : state_round_out;
  assign dout_share0_o = state_round_out[1*1600-1:0*1600];
  assign dout_share1_o = state_round_out[2*1600-1:1*1600];

  // Theta & rho & pi
  wire [2*1600-1:0] state_pi2chi;
  wire [ 2*320-1:0] state_pseudorandom;

  keccak_theta_rho_pi theta_rho_pi_share0 (
    .state_round_in_i(state_round_in[1600-1:0]),
    .state_pi2chi_o(state_pi2chi[1600-1:0])
  );

  keccak_theta_rho_pi theta_rho_pi_share1 (
    .state_round_in_i(state_round_in[2*1600-1:1600]),
    .state_pi2chi_o(state_pi2chi[2*1600-1:1600])
  );

  // Bypass theta
  keccak_rho_pi rho_pi_share0 (
    .state_round_in_y0_i(state_round_in[320-1:0]), // x=0...4, y=0, z=0...63
    .state_pseudorandom_o(state_pseudorandom[320-1:0])
  );

  keccak_rho_pi rho_pi_share1 (
    .state_round_in_y0_i(state_round_in[1600+320-1:1600]), // x=0...4, y=0, z=0...63
    .state_pseudorandom_o(state_pseudorandom[2*320-1:320])
  );

  // Chi pre-reg
  wire [4*1600-1:0] state_d;

  keccak_chi_pr chi_pr_inst (
    .random_i            (random_i),
    .state_pi2chi_i      (state_pi2chi),
    .state_pseudorandom_i(state_pseudorandom),
    .state_do            (state_d)
  );

  // State registers
  wire [4*1600-1:0] state_q;

  keccak_state state_inst (
    .clk     (clk),
    .state_di(state_d),
    .state_qo(state_q)
  );

  // Compression & iota
  keccak_comp_iota comp_iota_inst(
    .state_qi             (state_q),
    .iota_round_constant_i(iota_round_constant),
    .state_round_out_o    (state_round_out)
  );

endmodule








