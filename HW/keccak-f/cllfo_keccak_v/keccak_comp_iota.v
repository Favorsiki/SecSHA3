// keccak_comp_iota, compression operations following the registers and the iota step function.
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

module keccak_comp_iota (
  input       [4*1600-1:0] state_qi,
  input       [    64-1:0] iota_round_constant_i,
  output wire [2*1600-1:0] state_round_out_o
);
  wire [2*1600-1:0] state_chi2iota;

  assign state_chi2iota[1*1600-1:0*1600] = state_qi[1*1600-1:0*1600] ^ state_qi[2*1600-1:1*1600];
  assign state_chi2iota[2*1600-1:1*1600] = state_qi[3*1600-1:2*1600] ^ state_qi[4*1600-1:3*1600];

  assign state_round_out_o[    64-1: 0] = state_chi2iota[64-1:0] ^ iota_round_constant_i;
  assign state_round_out_o[2*1600-1:64] = state_chi2iota[2*1600-1:64];

endmodule
