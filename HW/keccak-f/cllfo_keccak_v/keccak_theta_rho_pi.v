// keccak_theta_rho_pi, the theta, rho, and pi step functions of the Keccak algorithm.
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

module keccak_theta_rho_pi (
  input      [1600-1:0] state_round_in_i,
  output reg [1600-1:0] state_pi2chi_o
);

  localparam W = 64;

  function integer idx (input integer x, input integer y);
    idx = (x + 5 * y) * W;
  endfunction

  // begin: theta
  reg [ 5*W-1:0] theta_column_sum, theta_column_sum_z_rot, theta_two_columns;
  reg [25*W-1:0] state_theta2rho;

  always @(*) begin : theta
    integer x, y;

    for (x = 0; x < 5; x = x + 1) begin
      theta_column_sum[x*W +: W] = state_round_in_i[idx(x, 0) +: W] ^
          state_round_in_i[idx(x, 1) +: W] ^ state_round_in_i[idx(x, 2) +: W] ^
          state_round_in_i[idx(x, 3) +: W] ^ state_round_in_i[idx(x, 4) +: W];
      theta_column_sum_z_rot[x*W +: W] = {theta_column_sum[x*W +: W-1], theta_column_sum[x*W+W-1]};
    end

    for (x = 0; x < 5; x = x + 1) begin
      theta_two_columns[idx(x, 0) +: W] = theta_column_sum[idx((x + 4) % 5, 0) +: W] ^
            theta_column_sum_z_rot[idx((x + 1) % 5, 0) +: W];
    end

    for (y = 0; y < 5; y = y + 1) begin
      state_theta2rho[idx(0, y) +: 5*W] = state_round_in_i[idx(0, y) +: 5*W] ^ theta_two_columns;
    end
  end
  // end: theta

  // begin: rho
  localparam [25*6-1:0] ROTATION_OFFSETS = {
    6'd14, 6'd56, 6'd61, 6'd2,  6'd18,
    6'd8,  6'd21, 6'd15, 6'd45, 6'd41,
    6'd39, 6'd25, 6'd43, 6'd10, 6'd3,
    6'd20, 6'd55, 6'd6,  6'd44, 6'd36,
    6'd27, 6'd28, 6'd62, 6'd1,  6'd0
  };

  reg [25*W-1:0] state_rho2pi;
  /* verilator lint_off UNUSED */
  reg [2*W-1:0] shifted_value;
  /* verilator lint_on UNUSED */
  
  always @(*) begin : rho
    integer x, y;
    for (x = 0; x < 5; x = x + 1) begin
      for (y = 0; y < 5; y = y + 1) begin
        shifted_value = {2{state_theta2rho[idx(x, y) +: W]}} >> 
            (W - ROTATION_OFFSETS[(x + 5 * y) * 6 +: 6]);
        state_rho2pi[idx(x, y) +: W] = shifted_value[W-1 : 0];
      end
    end
  end
  // end: rho

  // begin: pi
  always @(*) begin : pi
    integer x, y;
    for (x = 0; x < 5; x = x + 1) begin
      for (y = 0; y < 5; y = y + 1) begin
        state_pi2chi_o[idx(y, (2 * x + 3 * y) % 5) +: W] = state_rho2pi[idx(x, y) +: W];
      end
    end
  end
  // end: pi

endmodule
