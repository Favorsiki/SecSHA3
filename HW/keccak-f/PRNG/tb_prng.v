`timescale  1ns/1ps

module tb_prng();
    reg clk, rst_n, ren, ren_r;
    localparam bitlength = 1600;
    wire [bitlength-1 : 0] dout;

    always #5 clk = ~clk;
    always @(posedge clk) begin
        ren_r <= ren;
    end 
    initial begin
        clk = 0;
        rst_n = 1;
        ren = 0;
        #100 rst_n = 0;
        #100 rst_n = 1;
        #100;
        #10 ren = 1; #10 ren = 0;
        #100;
        #10 ren = 1; #10 ren = 0;
        #100;
        #10 ren = 1; #10 ren = 0;
        #100;
        #10 ren = 1; #10 ren = 0;
        #100;
        $stop;
    end

    prng #(.OUTLENGTH(bitlength)) uut(
        .clk(clk),
        .rst_n(rst_n),
        .ren(ren_r),
        .dout(dout)
    );

endmodule