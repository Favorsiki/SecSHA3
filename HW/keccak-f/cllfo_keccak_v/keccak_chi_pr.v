// keccak_chi_pr, the preceding section of registers in masked chi operations.
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

module keccak_chi_pr (
  input      [     2-1:0] random_i,
  input      [2*1600-1:0] state_pi2chi_i,
  input      [ 2*320-1:0] state_pseudorandom_i,
  output reg [4*1600-1:0] state_do
);

  localparam W = 64;
  localparam log2W = 6;

  function integer idx (input integer x, input integer y, input integer sh);
    idx = (x + 5 * y) * W + sh * 25 * W;
  endfunction

  function integer yz2j (input integer y, input integer z);
    yz2j = y * W + z;
  endfunction

  function integer j2y (input integer j);
    j2y = ((j + 5 * W) >> log2W) % 5;
  endfunction

  function integer j2z (input integer j);
    j2z = (j + 5 * W) % W;
  endfunction


  reg [2*25*W-1:0] operand, operand_n;
  reg [4*25*W-1:0] product;
  reg [   5*W-1:0] guard_x0, guard_x1;

  always @(*) begin : chi_pr
    integer x, y, z, j;

    operand = state_pi2chi_i;
    operand_n = ~operand;

    // begin: guards
    for (y = 0; y < 5; y = y + 1) begin
      for (z = 0; z < 64; z = z + 1) begin
        j = yz2j(y, z);
        if (j == 0) begin
          guard_x0[j] = random_i[0];
          guard_x1[j] = random_i[1];
        end else begin
          guard_x0[j] = operand[idx(0, j2y(j - 11), 0) + j2z(j - 11)];
          guard_x1[j] = operand[idx(1, j2y(j - 11), 0) + j2z(j - 11)];
        end
      end
    end
    // end: guards
    
    // begin: chi_pr
    for (x = 0; x < 5; x = x + 1) begin
      for (y = 0; y < 5; y = y + 1) begin
        product[idx(x, y, 0) +: W] = operand_n[idx((x+1)%5, y, 0) +: W] &
                                       operand[idx((x+2)%5, y, 0) +: W];
        product[idx(x, y, 1) +: W] =   operand[idx((x+1)%5, y, 0) +: W] &
                                       operand[idx((x+2)%5, y, 1) +: W];
        product[idx(x, y, 2) +: W] =   operand[idx((x+1)%5, y, 1) +: W] &
                                       operand[idx((x+2)%5, y, 0) +: W];
        product[idx(x, y, 3) +: W] = operand_n[idx((x+1)%5, y, 1) +: W] &
                                       operand[idx((x+2)%5, y, 1) +: W];

        if (x == 0) begin
          state_do[idx(x, y, 0) +: W] = product[idx(x, y, 0) +: W] ^ guard_x0[y * W +: W] ^
                                        state_pseudorandom_i[y * W +: W];
          state_do[idx(x, y, 1) +: W] = product[idx(x, y, 1) +: W] ^ operand[idx(x, y, 0) +: W] ^
                                        state_pseudorandom_i[y * W +: W];
          state_do[idx(x, y, 2) +: W] = product[idx(x, y, 2) +: W] ^ operand[idx(x, y, 1) +: W] ^
                                        state_pseudorandom_i[320 + y * W +: W];
          state_do[idx(x, y, 3) +: W] = product[idx(x, y, 3) +: W] ^ guard_x0[y * W +: W] ^
                                        state_pseudorandom_i[320 + y * W +: W];
        end else if (x == 1) begin
          state_do[idx(x, y, 0) +: W] = product[idx(x, y, 0) +: W] ^ guard_x1[y * W +: W];
          state_do[idx(x, y, 1) +: W] = product[idx(x, y, 1) +: W] ^ operand[idx(x, y, 0) +: W];
          state_do[idx(x, y, 2) +: W] = product[idx(x, y, 2) +: W] ^ operand[idx(x, y, 1) +: W];
          state_do[idx(x, y, 3) +: W] = product[idx(x, y, 3) +: W] ^ guard_x1[y * W +: W];
        end else begin
          state_do[idx(x, y, 0) +: W] = product[idx(x, y, 0) +: W];
          state_do[idx(x, y, 1) +: W] = product[idx(x, y, 1) +: W] ^ operand[idx(x, y, 0) +: W];
          state_do[idx(x, y, 2) +: W] = product[idx(x, y, 2) +: W] ^ operand[idx(x, y, 1) +: W];
          state_do[idx(x, y, 3) +: W] = product[idx(x, y, 3) +: W];
        end
      end
    end
    // end: chi_pr
  end

endmodule
