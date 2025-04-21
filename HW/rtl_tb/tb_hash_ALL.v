
`timescale 1 ns / 1 ps

module tb_hash_ALL();
    reg clk, rst_n, input_rst_n;
    reg [19:0] args;
    reg [10:0] inlen, master_outlen;
    reg [3:0] hash_mode;
    
    wire i_tready, i_tlast, i_tvalid;
    wire o_tready, o_tlast, o_tvalid;
    wire [31:0] i_tdata, o_tdata, din;
    wire [3:0] i_tstrb, o_tstrb;

    wire [31:0] dout;
    wire dout_req, valid, squeeze_start, done;
    /*
        parameter SHA3_256=3'd0, SHA3_512=3'd1;
        parameter SHAKE_128=3'd2, SHAKE_256=3'd3;
        parameter SHA3_224=3'd4, SHA3_384=3'd5;
    */

    // reg [31:0] dout0[63:0];
    // reg [31:0] dout1[63:0];

    initial begin
        clk = 0;
        rst_n = 0;
        input_rst_n = 0;
        args = 20'h0;
        hash_mode = 0;
        inlen = 0;
        master_outlen = 16;
        #100 rst_n = 1; input_rst_n = 1; #1000;
        
        // [1] : h_mode=0 , len =0x20 (hash_h)
        hash_mode = 4'h0; inlen = 11'h20;
        #100 args = {16'h800, hash_mode}; master_outlen = {2'b00,inlen[10:2]};
        // absorb
        #100 args = {4'h4,1'b0,inlen,hash_mode}; 
        #100 input_rst_n = 0; #100 input_rst_n = 1; #100;
        while (done == 1'b0) begin
            #10;
        end
        // padding
        #100 args = {16'h2000, hash_mode};
        while (done == 1'b0) begin
            #10;
        end
        // squeeze 
        #100 args = {16'h1000, hash_mode};
        while (done == 1'b0) begin
            #10;
        end
        // [5] : h_mode=2 , len =0x22 (xof_absorb)
        hash_mode = 4'h2; inlen = 11'h22;
        #100 args = {16'h800, hash_mode}; master_outlen = {2'b00,9'd9};
        // absorb
        #100 args = {4'h4,1'b0,inlen,hash_mode};
        #100 args = {16'h0, hash_mode}; 
        #100 input_rst_n = 0; #100 input_rst_n = 1; #100;
        while (done == 1'b0) begin
            #10;
        end
        // padding
        #100 args = {16'h2000, hash_mode};
        while (done == 1'b0) begin
            #10;
        end
        #10 args = {16'h0, hash_mode};
        // squeeze 
        #100 args = {16'h1000, hash_mode};
        #100 args = {16'h0, hash_mode};
        while (done == 1'b0) begin
            #10;
        end
        // squeeze 
        #100 args = {16'h1000, hash_mode};
        #100 args = {16'h0, hash_mode};
        while (done == 1'b0) begin
            #10;
        end
        // squeeze 
        #100 args = {16'h1000, hash_mode};
        #100 args = {16'h0, hash_mode};
        while (done == 1'b0) begin
            #10;
        end
        
        #1000 $stop;
    end 

    always #5 clk = ~clk;
    
    
    M_AXIS i_master(
        master_outlen,
        clk,
        input_rst_n,
        i_tvalid,
        i_tdata,
        i_tstrb,
        i_tlast,
        i_tready
    );
    
    
    demo_hash_interface hash_if(
        wen,
        dout_req,
        din,
        dout,
        valid,
        done,
        squeeze_start,
        clk,
        rst_n,
        i_tready,
        i_tdata,
        i_tstrb,
        i_tlast, 
        i_tvalid,
        clk,
        rst_n,
        o_tvalid,
        o_tdata,
        o_tstrb,
        o_tlast,
        o_tready   
    );
    

    S_AXIS o_slave(
        clk,
        rst_n,
        o_tready,
        o_tdata,
        o_tstrb,
        o_tlast, 
        o_tvalid
    );

    demo_hash_core hash(clk, rst_n, wen, dout_req, args, din, dout, valid, squeeze_start,done);
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
    
    demo_hash_core hash(clk, rst_n, wen_r, dout_req_r, args_r, din_r, dout, valid, squeeze_start, done);

endmodule