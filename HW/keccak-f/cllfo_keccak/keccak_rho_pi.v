// keccak_rho_pi, partial rho and pi operations, bypassing the theta
// operation for the y=0 plane and using it as randomness in chi
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

module keccak_rho_pi (
  // state_round_in_y0_i
  // [0*64 : 1*64-1]     [1*64 : 2*64-1]   ...  [4*64 : 5*64-1]
  // x=0, y=0, z=0...63  x=1,y=0,z=0...63  ...  x=4,y=0,z=0...63
  input      [320-1:0] state_round_in_y0_i,
  // state_pseudorandom_o
  // [0*64 : 1*64-1]     [1*64 : 2*64-1]   ...  [4*64 : 5*64-1]
  // x=0, y=0, z=0...63  x=0,y=1,z=0...63  ...  x=0,y=4,z=0...63
  output reg [320-1:0] state_pseudorandom_o
);

  localparam W = 64;

  // begin: rho
  localparam [25*6-1:0] ROTATION_OFFSETS = {
    6'd14, 6'd56, 6'd61, 6'd2,  6'd18,
    6'd8,  6'd21, 6'd15, 6'd45, 6'd41,
    6'd39, 6'd25, 6'd43, 6'd10, 6'd3,
    6'd20, 6'd55, 6'd6,  6'd44, 6'd36,
    6'd27, 6'd28, 6'd62, 6'd1,  6'd0
  };


  reg [320-1:0] state_rho2pi;
  /* verilator lint_off UNUSED */
  reg [2*W-1:0] shifted_value;
  /* verilator lint_on UNUSED */

  always @(*) begin : rho
    integer x;
    for (x = 0; x < 5; x = x + 1) begin
      shifted_value = {2{state_round_in_y0_i[x * W +: W]}} >>
          (W - ROTATION_OFFSETS[x * 6 +: 6]);
      state_rho2pi[x * W +: W] = shifted_value[W-1:0];
    end
  end
  // end: rho

  // begin: pi
  always @(*) begin : pi
    integer x;
    for (x = 0; x < 5; x = x + 1) begin
      state_pseudorandom_o[((2 * x) % 5) * W +: W] = state_rho2pi[x * W +: W];
    end
  end
  // end:pi

endmodule
