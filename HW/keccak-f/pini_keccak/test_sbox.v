module test_sbox();
    reg clk;
    wire [9:0] din_share;
    reg [4:0] din_0, din_1;
    assign din_share = {din_0, din_1};
    reg [9:0]  rand_data;
    wire [9:0] dout_share, dout_share_1;
    wire [4:0] dout_0, dout_1, dout_2, dout_3, test_a0, test_a1;
    assign dout_0 = dout_share[4:0];
    assign dout_1 = dout_share[9:5];
    assign dout_2 = dout_share_1[4:0];
    assign dout_3 = dout_share_1[9:5];
    assign test_a0 = dout_0 ^ dout_1;
    assign test_a1 = dout_2 ^ dout_3;

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        din_0 = 0;
        din_1 = 0;
        rand_data = 0;
        #100;
        din_0 = 5'h0a;
        din_1 = 5'h11;
        rand_data = 10'h37ef;
        #100
        din_0 = 5'h17;
        din_1 = 5'h0f;
        rand_data = 10'h37ef;
        #100
        $stop;
    end
    reg [9:0] din_share_r, din_share_r1;

    always @(posedge clk) begin
        din_share_r <= din_share;
        din_share_r1 <= din_share_r;
    end 

    keccak_sbox uut(
        .clk(clk),
        .din_share(din_share_r1),
        .dout_share(dout_share),
        .rand_data(rand_data)
    );

    keccak_sbox_another uut1(
        .din_share(din_share_r1),
        .dout_share(dout_share_1)
    );

endmodule

module test_chi();
    reg clk;
    reg [1599:0] din_0, din_1;
    reg [1599:0] din_0_r1, din_1_r1;
    reg [1599:0] din_0_r2, din_1_r2;
    reg [3199:0] rand_data;
    wire [1599:0] u0_dout0, u0_dout1, u1_dout0, u1_dout1, u2_dout0, u2_dout1;
    wire [1599:0] rcs0_y, rcs1_y, ircs0_x, ircs1_x;
    wire [1599:0] test_a0, test_a1, test_a2;
    assign test_a0 = u0_dout0 ^ u0_dout1;
    assign test_a1 = u1_dout0 ^ u1_dout1;
    assign test_a2 = u2_dout0 ^ u2_dout1;

    always #5 clk = ~clk;

    always @(posedge clk) begin
        din_0_r1 <= din_0;
        din_1_r1 <= din_1;
        din_0_r2 <= din_0_r1;
        din_1_r2 <= din_1_r1;
    end 

    initial begin
        clk = 0;
        din_0 = 0;
        din_1 = 0;
        rand_data = 0;
        #100;
        din_0 = 1600'hFB7C700E5E8C851A6AB8A0425D554B9A63D57453F5F27CC0A41EC7951CA27B17AD2C7FD22DB7BDB9C39FD46F92B5415C983376558CAF594EB552CE9E688D0177D12BDA9B0354A6955FC4334266F653126B0E37D91A01E4365D56ED2BBCF494EC640BB5A5AAC3EE4CEA0803619F03CC8CA1E9EF47FAA2590CE2759E5032E51A1A7B29D67A4C9AE25C5910EACBDF6E45C2EA7F577728F65345CEBBB95DE2BB32C55DF4E480FBA014A1;
        din_1 = 1600'hE58BDC72E44B4B94240ACDE53E3AD62A0695840DDAEFC92B5BAA6025C71015B8E8EF5DDBD660301A57E4AC447607CFFB656BCA97E8C133A3EB5A5BDABEE4A94D8428186FD086407DBE9CA86AE7562148D60502110C761E450F287C7E66A2296FBC30B1990C9D63E83173DE7629F7FA1768406486C24C02D235296BBE3742D8799970202EDFF6C789266E371D5BF118E247A65E88BFF10D044298C0FDE278EEA9C97930BA7CF0504F;
        rand_data = 3200'hfffffeeeffaaa334490cdf;
        #100;
        din_0 = 1600'h2CEEE3C6611171DACDBF417B5953BF76B2EF9FE7B26F1AF4F50B2799DDC8AC81C982FDE7078E88D59C7E3AECDAE6434DA1623BF8A9833049D1B8BA5DEA5EBA35D437A359C358206FA7FF84BADC0A259D51E0B417FB37AF7D5AE400D7D6F412ADEC6D0830B7E50A87E6594B7F42313544DF25FD773D8FED1E491A04C055223965C3E36CA909720AEC1B2919B7413C5E03FFC0023CB9B173543B6AFC145B873D7225DD33FAD1449BBF;
        din_1 = 1600'hABB274A92ACEE034D3BAEE5C7BFAEDC2A7FAAAC404F37C9A3B15BCB3;
        rand_data = 3200'hE2E0126DEABE70EC0AD5CD95B548C14A08C95D2C065F784F3CE28A6F5832EE6D3060DA0C9CEC4C31B3491B40EA91C358EBB06A9C6D48333EC28CEBC68B8BAACCEDA69997034281556BE9114A221D8DA110749BD96632351F4586C68F5589EAAAACAB898CC61FC231F25B11C9ABD4677314CA073F3845EFA00F5F989A8FD902E702ABC191FE5ADF0C51BC0462DA4007CFC23D2F0FC2D221A89D786A72956721B818BF20BD53F42C1C;
        #100;
        din_0 = 1600'h6AAC023A7638C32E1DDA26D6BC460678FB0BFE36832CEE0C6D15130F07F7653720A7CA694913FBDB9F7E1744D4D694D9EC3EA541243015E1D50FDE3A1E68382216DB61902DA540C5B0A6C80A1FDA6E1694F8CF29D7350285F5900B280BB440A4D9A9CF80CCB149C241535CC0D33502809F9BE45E20B0DD6660B9A4369AD94EEB6C4B703C8BDD115BB4EE895472924727ACEF7F00AAA7EB85AE3E796EDCDC3E89C1D9CBFE5CB0F9AC;
        din_1 = 1600'h5BCA6F2D153B025B2DF41698DD8B512A4485AB86047C64507E08945BA83E15D0356981C3949FE9366530C77453802D87B95F276A0043251190A0EC2F22F170A7B1AA62E999EC9E9752F00123C8D9AFC96AB5A7D010AB4DFAE435004A9EC14211C52E8EB2C59393E45C0DC3C340D0B100D3299B5999C0F95441B80C2D700AD41C943FE14E46061A64F7F8749E11326853B9C5FF4691D588D4482FB8538339BC978CB5C55A68A9F7ED;
        rand_data = 3200'hfffffeeeffaaa334490cdf;
        #100;
        $stop;
    end 

    ReOrderChiSquence rcs0(
        .orgin(din_0_r2),
        .reorder(rcs0_y)
    );
    ReOrderChiSquence rcs1(
        .orgin(din_1_r2),
        .reorder(rcs1_y)
    );

    InvReOrderChiSquence ircs0(
        .reorder(test_a0),
        .orgin(ircs0_x)
    );
    InvReOrderChiSquence ircs1(
        .reorder(test_a1),
        .orgin(ircs1_x)
    );

    keccak_chi_pini uut0(
        .clk(clk),
        .din_0(rcs0_y),
        .din_1(rcs1_y),
        .rand_data(rand_data),
        .dout_0(u0_dout0),
        .dout_1(u0_dout1)
    );

    keccak_chi_another uut1(
        .din_0(rcs0_y),
        .din_1(rcs1_y),
        .dout_0(u1_dout0),
        .dout_1(u1_dout1)
    );

    keccak_chi_third uut2(
        .clk(clk),
        .I_x0(din_0_r2),
        .I_x1(din_1_r2),
        .I_r(rand_data[1599:0]),
        .O_z0(u2_dout0),
        .O_z1(u2_dout1)
    );

endmodule


module keccak_sbox_another(
    input [9:0] din_share,
    input [9:0] dout_share
);
    wire din0, din1, din2, din3, din4;
    assign din0 = din_share[0] ^ din_share[5];
    assign din1 = din_share[1] ^ din_share[6];
    assign din2 = din_share[2] ^ din_share[7];
    assign din3 = din_share[3] ^ din_share[8];
    assign din4 = din_share[4] ^ din_share[9];
    assign dout_share[0] = din0;
    assign dout_share[1] = din1;
    assign dout_share[2] = din2;
    assign dout_share[3] = din3;
    assign dout_share[4] = din4;
    assign dout_share[5] = (~din1) & din2;
    assign dout_share[6] = (~din2) & din3;
    assign dout_share[7] = (~din3) & din4;
    assign dout_share[8] = (~din4) & din0;
    assign dout_share[9] = (~din0) & din1;

endmodule


module keccak_chi_another #(parameter SBOX_NUM = 320) (
    input [1599  : 0] din_0, din_1,
    output [1599 : 0] dout_0, dout_1
);
    genvar i;
    generate for (i = 0; i < SBOX_NUM; i = i + 1) begin : k_sbox
        keccak_sbox_another inst(
            .din_share({din_0[i*5+4 : i*5], din_1[i*5+4 : i*5]}),
            .dout_share({dout_0[i*5+4 : i*5], dout_1[i*5+4 : i*5]})
        );
    end
    endgenerate
endmodule 


`define x1 (x0 == 4 ? 0 : x0 + 1)
`define x2 (x0 == 3 ? 0 : (x0 == 4 ? 1 : x0 + 2))
`define Idx(x,y) ((5 * y + x) * 64)

module keccak_chi_third (
    input clk, 
    input [1599:0] I_x0, I_x1,
    input [1599:0] I_r,
    output [1599:0] O_z0, O_z1
);

    wire [1599:0] FFxDN00, FFxDN01, FFxDN10, FFxDN11;
    wire [1599:0] result0, result1;

genvar x0, y;
generate
    for (x0 = 0; x0 < 5; x0 = x0 + 1) begin
        // Chi
        for (y = 0; y < 5; y = y + 1) begin
            assign FFxDN00[`Idx(x0,y)+:64] = I_x0[`Idx(x0,y)+:64] ^ (~I_x0[`Idx(`x1,y)+:64] & I_x0[`Idx(`x2,y)+:64]);
            assign FFxDN11[`Idx(x0,y)+:64] = I_x1[`Idx(x0,y)+:64] ^ (~I_x1[`Idx(`x1,y)+:64] & I_x1[`Idx(`x2,y)+:64]);
            assign FFxDN01[`Idx(x0,y)+:64] = (I_x0[`Idx(`x1,y)+:64] & I_x1[`Idx(`x2,y)+:64]) ^ I_r[`Idx(x0,y)+:64];
            assign FFxDN10[`Idx(x0,y)+:64] = (I_x1[`Idx(`x1,y)+:64] & I_x0[`Idx(`x2,y)+:64]) ^ I_r[`Idx(x0,y)+:64];
        end
    end
endgenerate
	assign result0 = FFxDN00 ^ FFxDN01;
	assign result1 = FFxDN10 ^ FFxDN11;

// Iota
assign O_z0 = result0;
assign O_z1 = result1;

endmodule