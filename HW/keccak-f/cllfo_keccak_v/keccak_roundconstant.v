// keccak_roundconstant, selection of round constants in the Keccak algorithm.
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

module keccak_roundconstant (
  input      [ 4:0] round_number_i,
  output reg [63:0] round_constant_o
);

  always @(*) begin
    case (round_number_i)
      5'd00:   round_constant_o = 64'h0000000000000001;
      5'd01:   round_constant_o = 64'h0000000000008082;
      5'd02:   round_constant_o = 64'h800000000000808A;
      5'd03:   round_constant_o = 64'h8000000080008000;
      5'd04:   round_constant_o = 64'h000000000000808B;
      5'd05:   round_constant_o = 64'h0000000080000001;
      5'd06:   round_constant_o = 64'h8000000080008081;
      5'd07:   round_constant_o = 64'h8000000000008009;
      5'd08:   round_constant_o = 64'h000000000000008A;
      5'd09:   round_constant_o = 64'h0000000000000088;
      5'd10:   round_constant_o = 64'h0000000080008009;
      5'd11:   round_constant_o = 64'h000000008000000A;
      5'd12:   round_constant_o = 64'h000000008000808B;
      5'd13:   round_constant_o = 64'h800000000000008B;
      5'd14:   round_constant_o = 64'h8000000000008089;
      5'd15:   round_constant_o = 64'h8000000000008003;
      5'd16:   round_constant_o = 64'h8000000000008002;
      5'd17:   round_constant_o = 64'h8000000000000080;
      5'd18:   round_constant_o = 64'h000000000000800A;
      5'd19:   round_constant_o = 64'h800000008000000A;
      5'd20:   round_constant_o = 64'h8000000080008081;
      5'd21:   round_constant_o = 64'h8000000000008080;
      5'd22:   round_constant_o = 64'h0000000080000001;
      5'd23:   round_constant_o = 64'h8000000080008008;
      default: round_constant_o = 64'h0000000000000000;
    endcase
  end

endmodule
