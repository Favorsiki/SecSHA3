/*
* -----------------------------------------------------------------
* COMPANY : Ruhr University Bochum
* AUTHOR  : Amir Moradi (amir.moradi@rub.de) Aein Rezaei Shahmirzadi (aein.rezaeishahmirzadi@rub.de)
* DOCUMENT: "Second-Order SCA Security with almost no Fresh Randomness" (TCHES 2021, Issue 3)
* -----------------------------------------------------------------
*
* Copyright (c) 2021, Amir Moradi, Aein Rezaei Shahmirzadi
*
* All rights reserved.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTERS BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Please see LICENSE and README for license and further instructions.
*/

module Chi_NoFresh(
	 input clk,
	 input [4:0] in1,
    input [4:0] in2,
    output [4:0] out1,
    output [4:0] out2
    );

	wire [4:0] q1;
	wire [4:0] q2;
	wire [19:0] CF_Out;
	reg [19:0] CF_Reg;
	
	reg [2:1] a;
	reg [2:1] b;
	reg [2:1] c;
	reg [2:1] d;
	reg [2:1] e;
	
	always @(*) begin
		a = {in2[4],in1[4]};
		b = {in2[3],in1[3]};
		c = {in2[2],in1[2]};
		d = {in2[1],in1[1]};
		e = {in2[0],in1[0]};
	end

	genvar i;
   generate
		//NonLinear Layer
      for (i=0; i < 20; i=i+1) 
      begin: Inst
         NF_CF #(.num(i)) CF_Inst (
				.a(a), 
				.b(b), 
				.c(c), 
				.d(d), 
				.e(e), 
				.q(CF_Out[i])
			);
      end
		
		//Compression
		for (i=0; i < 5; i=i+1) 
      begin: InstXOR
			XOR_2 Compression1  ( .x0(CF_Reg[4*i]), 	.x1(CF_Reg[4*i+1]), .q(q1[i]) );
			XOR_2 Compression2  ( .x0(CF_Reg[4*i+2]), .x1(CF_Reg[4*i+3]), .q(q2[i]) );
      end
   endgenerate
	
	always @(posedge clk) begin
	//always @(*) begin
		CF_Reg <= CF_Out;
	end
	
	assign out1 = {q1[0], q1[1], q1[2], q1[3], q1[4]};
	assign out2 = {q2[0], q2[1], q2[2], q2[3], q2[4]};

endmodule
