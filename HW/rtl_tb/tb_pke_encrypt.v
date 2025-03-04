`timescale 1ns / 1ns

module tb_pke_encrypt();
	reg clk, rst, en, wen;
	reg [31:0] din;
	wire [31:0] dout0, dout1;
	wire valid_o, done;

	always #5 clk = ~clk;
	
	reg [31:0] dina [0:255];
	reg [31:0] doua [0:255];
	reg [31:0] fout [0:255];
	
	initial begin
		$readmemh("E:/workstation/hw-sw_co-design/kyber_cw/kyber_v2/kyber_v2.srcs/sources_1/imports/kyber_cw/kyber_top/tb_data/KYBER_PKE_ENC_DIN.txt", dina);
		$readmemh("E:/workstation/hw-sw_co-design/kyber_cw/kyber_v2/kyber_v2.srcs/sources_1/imports/kyber_cw/kyber_top/tb_data/KYBER_PKE_ENC_DOUT.txt", doua);
	end 
	
	initial begin
		clk = 1;
		rst = 0;
		#100;
		rst = 1;
		#10 ;
		rst = 0;
		#100;
	end

	integer k, m, e;
	initial begin
		e = 0;
		m = 0;
		wen = 0;
		din = 0;
		en = 0;
		#200;
		en = 1;
		#10;
		en = 0;
		#10;
		
		for (k = 0; k < 224; k = k + 1) begin
			wen = 1;
			din = dina[k];
			#10;
		end 
		wen = 0;
		din = 0;
		#1000;
		
		for (m = 0 ; m < 192; m = m + 1) begin
			while (valid_o == 1'b0) begin
				#10;
			end 
			fout[m] = dout0 ^ dout1;
			#10;
		end 
		
		// check result
		for (m = 0; m < 192; m = m + 1) begin
			if(fout[m] == doua[m]) begin
				e = e+1;
			end
			else begin
				$display("Wrong result -- index:%d, expected:%h --> calculated:%h",m,doua[m],fout[m]);
			end
		end
		
		if(e == 256)
			$display("PKE_ENC -- Correct!");
		else
			$display("PKE_ENC -- Incorrect!");

		#50;
		$stop;	
	end 

	kyber_enc_core uut(
		.clk(clk),
		.rst(rst),
		.en(en),
		.wen(wen),
		.data_i(din),
		.dout0(dout0),
		.dout1(dout1),
		.valid_o(valid_o),
		.done(done)
	);

endmodule
