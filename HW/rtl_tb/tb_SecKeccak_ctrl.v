`timescale  1ns/1ps
module tb_SecKeccak_ctrl();
    reg clk, rst_n, wen, dout_req;
    reg [19:0] args;
    reg [31:0] din;

    wire [31:0] dout;
    wire valid, squeeze_start, done;
    /*
        parameter SHA3_256=3'd0, SHA3_512=3'd1;
        parameter SHAKE_128=3'd2, SHAKE_256=3'd3;
        parameter SHA3_224=3'd4, SHA3_384=3'd5;
    */

    //reg [31:0] dout0[63:0];
    //reg [31:0] dout1[63:0];

    initial begin
        clk = 0;
        rst_n = 0;
        wen = 0;
        dout_req = 0;
        args = 20'h0;
        din = 32'h0;
        #100;
        rst_n = 1;
        // [1] SHA3-512 unmasked
        // d = 0x 7C9935A0 B07694AA 0C6D10E4 DB6B1ADD 2FD81A25 CCB14803 2DCD7399 36737F2D ;
        // G(d) = 65EAFD465FC64A0C 5F8F3F9003489415899D59A543D8208C54A3166529B53922 ABB274A92ACEE034D3BAEE5C7BFAEDC2A7FAAAC404F37C9A3B15BCB3 CFF80803
        #1000 args = 20'h08001; // G_un_mask, SHA3_512
        #1000 args = 20'h40201;
        #100 ;
        #10 wen = 1; din = 32'hA035997C; 
		#10 wen = 1; din = 32'hAA9476B0;
		#10 wen = 1; din = 32'hE4106D0C;
		#10 wen = 1; din = 32'hDD1A6BDB;
		#10 wen = 1; din = 32'h251AD82F;
		#10 wen = 1; din = 32'h0348B1CC;
		#10 wen = 1; din = 32'h9973CD2D;
		#10 wen = 1; din = 32'h2D7F7336; // 8
        #10 wen = 1; din = 32'h098f3134;
        #1000 wen = 0;
        #1000;
        #1000 args = 20'h00001;
        #1000 args = 20'h20001;
        #1000;
        #1000 args = 20'h00001;
        #1000 args = 20'h10001;
        #2000;
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h00001;
        #1000;
        // [2] SHA3-512 masked
        #1000 args = 20'h08009; // SHA3_512
        #1000 args = 20'h40209;
        #100 ;
        #10 wen = 1; din = 32'hA035997C ^ 32'h80; 
		#10 wen = 1; din = 32'hAA9476B0 ^ 32'h80;
		#10 wen = 1; din = 32'hE4106D0C ^ 32'h80;
		#10 wen = 1; din = 32'hDD1A6BDB ^ 32'h80;
		#10 wen = 1; din = 32'h251AD82F ^ 32'h80;
		#10 wen = 1; din = 32'h0348B1CC ^ 32'h80;
		#10 wen = 1; din = 32'h9973CD2D ^ 32'h80;
		#10 wen = 1; din = 32'h2D7F7336 ^ 32'h80; // 8
        #10 wen = 1; din = 32'h80;
        #2000 wen = 0;
        #1000;
        #1000 args = 20'h00009;
        #1000 args = 20'h20009;
        #1000;
        #1000 args = 20'h00009;
        #1000 args = 20'h10009;
        #2000;
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h00009;
        #1000;
        // [3]  SHA3-512 masked, input 30 bytes
        #1000 args = 20'h08009; // G_un_mask, SHA3_512
        #1000 args = 20'h401e9;
        #100 ;
        #10 wen = 1; din = 32'hA035997C ^ 32'h80; 
		#10 wen = 1; din = 32'hAA9476B0 ^ 32'h80;
		#10 wen = 1; din = 32'hE4106D0C ^ 32'h80;
		#10 wen = 1; din = 32'hDD1A6BDB ^ 32'h80;
		#10 wen = 1; din = 32'h251AD82F ^ 32'h80;
		#10 wen = 1; din = 32'h0348B1CC ^ 32'h80;
		#10 wen = 1; din = 32'h9973CD2D ^ 32'h80;
		#10 wen = 1; din = 32'h2D7F7336 ^ 32'h80; // 8
        #10 wen = 1; din = 32'h80;
        #2000 wen = 0;
        #1000;
        #1000 args = 20'h00009;
        #1000 args = 20'h20009;
        #1000;
        #1000 args = 20'h00009;
        #1000 args = 20'h10009;
        #2000;
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h00009;
        #1000;
        // [4] SHA3-512 masked, input 71 Bytes
        #1000 args = 20'h08009; // G_un_mask, SHA3_512
        #1000 args = 20'h40479;
        #100 din = 0;
        repeat (40) begin
            #10 wen = 1; din = din + 32'd100;
        end 
        #10 wen = 0;
        #100 args = 20'h00009;
        #1000 args = 20'h20009;
        #1000;
        #1000 args = 20'h00009;
        #1000 args = 20'h10009;
        #2000;
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h00009;
        #1000;
        // [5] SHA3-512 masked, input 72 Bytes
        #1000 args = 20'h08009; // SHA3_512
        #1000 args = 20'h40489;
        #100 din = 0;
        repeat (40) begin
            #10 wen = 1; din = din + 32'd100;
        end 
        #10 wen = 0;
        #2000 args = 20'h00009;
        #1000 args = 20'h20009;
        #1000;
        #1000 args = 20'h00009;
        #1000 args = 20'h10009;
        #2000;
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h00009;
        #1000; 
        // [6] SHA3-512 masked, input 511 bytes
        #10 din = 0;
        #1000 args = 20'h08009; // G_un_mask, SHA3_512
        #1000 args = 20'h41FF9;
        #100 ;
        repeat (260) begin
            #10 wen = 1; din = din + 1; 
        end 
        #10  wen = 0; din = 0;
        #8000 args = 20'h00009;
        #1000 args = 20'h20009;
        #1000;
        #1000 args = 20'h00009;
        #1000 args = 20'h10009;
        #2000;
        while (squeeze_start == 0) begin
            #10;
        end 
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h00009;
        #1000;
        // [7] SHA3-512 masked, input 512 bytes
        #10 din = 0;
        #1000 args = 20'h08009; // G_un_mask, SHA3_512
        #1000 args = 20'h42009;
        #100 ;
        repeat (260) begin
            #10 wen = 1; din = din + 1; 
        end 
        #10  wen = 0; din = 0;
        #8000 args = 20'h00009;
        #1000 args = 20'h20009;
        #1000;
        #1000 args = 20'h00009;
        #1000 args = 20'h10009;
        #2000;
        while (squeeze_start == 0) begin
            #10;
        end 
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h00009;
        #1000;
        
        // [8] SHA3-512 masked, input 512+512 bytes
        #10 din = 0;
        #1000 args = 20'h08009; // SHA3_512
        #1000 args = 20'h42009;
        #100 ;
        repeat (260) begin
            #10 wen = 1; din = din + 1; 
        end 
        #10  wen = 0; din = 0;
        #8000 args = 20'h00009;
        #1000 args = 20'h42009;
        #100 ;
        repeat (260) begin
            #10 wen = 1; din = din + 1; 
        end 
        #10  wen = 0; din = 0;
        #8000 args = 20'h00009;
        #1000 args = 20'h20009;
        #1000;
        #1000 args = 20'h00009;
        #1000 args = 20'h10009;
        #2000;
        while (squeeze_start == 0) begin
            #10;
        end 
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h00009;
        #1000;
        #1000 args = 20'h10009;
        #2000;
        while (squeeze_start == 0) begin
            #10;
        end 
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h00009;
        #1000;  

        // [9] SHA3-512 masked, input 512+64 bytes
        #10 din = 0;
        #1000 args = 20'h08009; // SHA3_512
        #1000 args = 20'h42009;
        #100 ;
        repeat (260) begin
            #10 wen = 1; din = din + 1; 
        end 
        #10  wen = 0; din = 0;
        #8000 args = 20'h00009;
        #1000 args = 20'h40409;
        #100 ;
        repeat (40) begin
            #10 wen = 1; din = din + 1; 
        end 
        #10  wen = 0; din = 0;
        #8000 args = 20'h00009;
        #1000 args = 20'h20009;
        #1000;
        #1000 args = 20'h00009;
        #1000 args = 20'h10009;
        #2000;
        while (squeeze_start == 0) begin
            #10;
        end 
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h00009;
        #1000;
        #1000 args = 20'h10009;
        #2000;
        while (squeeze_start == 0) begin
            #10;
        end 
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h00009;
        #1000;  
        
        
        // [10] SHA3-512 masked, input 512+63 bytes
        #10 din = 0;
        #1000 args = 20'h08009; // SHA3_512
        #1000 args = 20'h42009;
        #100 ;
        repeat (260) begin
            #10 wen = 1; din = din + 1; 
        end 
        #10  wen = 0; din = 0;
        #8000 args = 20'h00009;
        #1000 args = 20'h403F9;
        #100 ;
        repeat (40) begin
            #10 wen = 1; din = din + 1; 
        end 
        #10  wen = 0; din = 0;
        #8000 args = 20'h00009;
        #1000 args = 20'h20009;
        #1000;
        #1000 args = 20'h00009;
        #1000 args = 20'h10009;
        #2000;
        while (squeeze_start == 0) begin
            #10;
        end 
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h00009;
        #1000;
        #1000 args = 20'h10009;
        #2000;
        while (squeeze_start == 0) begin
            #10;
        end 
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h00009;
        #1000;  
        
        // [11] SHAKE-128 masked, input 512+159 bytes
        #10 din = 0;
        #1000 args = 20'h0800A; // SHAKE-128
        #1000 args = 20'h4200A;
        #100 ;
        repeat (260) begin
            #10 wen = 1; din = din + 1; 
        end 
        #10  wen = 0; din = 0;
        #8000 args = 20'h0000A;
        #1000 args = 20'h409FA;
        #100 ;
        repeat (90) begin
            #10 wen = 1; din = din + 1; 
        end 
        #10  wen = 0; din = 0;
        #8000 args = 20'h0000A;
        #1000 args = 20'h2000A;
        #1000;
        #1000 args = 20'h0000A;
        #1000 args = 20'h1000A;
        #2000;
        while (squeeze_start == 0) begin
            #10;
        end 
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h0000A;
        #1000;
        #1000 args = 20'h1000A;
        #2000;
        while (squeeze_start == 0) begin
            #10;
        end 
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h0000A;
        #1000;  
        
        // [12] SHAKE-128 masked, input 512+160 bytes
        #10 din = 0;
        #1000 args = 20'h0800A; // SHAKE-128
        #1000 args = 20'h4200A;
        #100 ;
        repeat (260) begin
            #10 wen = 1; din = din + 1; 
        end 
        #10  wen = 0; din = 0;
        #8000 args = 20'h0000A;
        #1000 args = 20'h40A0A;
        #100 ;
        repeat (90) begin
            #10 wen = 1; din = din + 1; 
        end 
        #10  wen = 0; din = 0;
        #8000 args = 20'h0000A;
        #1000 args = 20'h2000A;
        #1000;
        #1000 args = 20'h0000A;
        #1000 args = 20'h1000A;
        #2000;
        while (squeeze_start == 0) begin
            #10;
        end 
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h0000A;
        #1000;
        #1000 args = 20'h1000A;
        #2000;
        while (squeeze_start == 0) begin
            #10;
        end 
        #10 dout_req = 1;
        #50 dout_req = 0;
        #100 dout_req = 1;
        #440 dout_req = 0;
        #100 dout_req = 1;
        #510 dout_req = 0;
        #100 args = 20'h0000A;
        #1000;  
        
        $stop;

    end 

    always #5 clk = ~clk;


    hash_core uut(clk, rst_n, wen, dout_req, args, din, dout, valid, squeeze_start,done);
endmodule

module hash_core(
    input clk, rst_n, wen, dout_req,
    input [19:0] args,
    input [31:0] din,

    output [31:0] dout,
    output valid, squeeze_start, done
);
    reg wen_r, dout_req_r;
    reg [19:0] args_r;
    reg [31:0] din_r;

    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            wen_r <= 0;
            dout_req_r <= 0;
            args_r <= 0;
            din_r <= 0;
        end else begin
            wen_r <= wen;
            dout_req_r <= dout_req;
            args_r <= args;
            din_r <= din;
        end 
    end 
    
    demo_hash_core uut(clk, rst_n, wen_r, dout_req_r, args_r, din_r, dout, valid, squeeze_start, done);

endmodule