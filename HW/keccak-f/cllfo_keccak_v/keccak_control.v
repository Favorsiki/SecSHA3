// keccak_control, control module governing the operational flow.
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

module keccak_control (
  input                clk,
  input                rst_n,
  output wire [64-1:0] iota_round_constant_o,
  output reg           round_in_select_o,
  output wire          dout_vld_o
);

  // begin: FSM
  localparam StStart  = 3'h1,
             StRun    = 3'h2,
             StFinish = 3'h4;

  reg [2:0] control_state_d, control_state_q;
  wire      last_round;

  always @(*) begin
    case (control_state_q)
      StStart:  control_state_d = StRun;
      StRun:    control_state_d = last_round ? StFinish : StRun;
      StFinish: control_state_d = StFinish;
      default:  control_state_d = StFinish;
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      control_state_q <= StStart;
    end else begin
      control_state_q <= control_state_d;
    end
  end
  // end: FSM

  // begin: round counter
  reg [4:0] round_counter_d, round_counter_q;

  always @(*) begin
    case (control_state_q)
      StStart:  round_counter_d = 5'd0;
      StRun:    round_counter_d = round_counter_q + 5'd1;
      StFinish: round_counter_d = round_counter_q;
      default:  round_counter_d = round_counter_q;
    endcase
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      round_counter_q <= 5'd0;
    end else begin
      round_counter_q <= round_counter_d;
    end
  end
  // end: round counter

  // begin: control signals
  assign last_round = rst_n && (round_counter_q == 5'd22);
  assign dout_vld_o = (control_state_q == StFinish);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      round_in_select_o <= 1'b1;
    end else begin
      round_in_select_o <= 1'b0;
    end
  end
  // end: control signals

  // begin: iota round constants
  keccak_roundconstant rc_gen (
    .round_number_i  (round_counter_q),
    .round_constant_o(iota_round_constant_o)
  );
  // end: iota round constants

endmodule
