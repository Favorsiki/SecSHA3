`timescale 1ns/1ns
module tb_keccak1600;
	reg clk, reset, init, go, squeeze_extend_0, squeeze_extend_1, absorb, absorb_extend;
	reg [31:0] din0, din1;
	wire done;
	wire [31:0] result;
	
	keccakf1600 hsh(clk, reset, init, go, absorb, absorb_extend, squeeze_extend_0, squeeze_extend_1, din0, din1, done, result);

	always #5 clk = ~clk;

	
	initial begin 
		clk = 1;
		init = 0;
		go = 0;
		absorb = 0;
		absorb_extend = 0;
		squeeze_extend_0 = 0;
		squeeze_extend_1 = 0;
		din0 = 0;	
		din1 = 0;
		
		
		// sigma = ABB274A9 2ACEE034 D3BAEE5C 7BFAEDC2 A7FAAAC4 04F37C9A 3B15BCB3 CFF80803;
		// PRF({sigma,8'h0}) = 
		// rnd1 : 8A152D07 3B12162F 4765DFF4CB658BE363173CE3969CF5E2F4E563CC3E55C6D7B2C2E30A904F3BA45838D896F795D98EDE4AA682AFD24618563CE292C53FB6B51A88192194BC0107E6921AC263043DF6089F5E08FBD5CC3F9D3913B4B054EEE5780512E6A86CDAEE4ACCD5369222ADE886D7BF5ABBEAF2D2437231B248857B9BA5CD26894A1B7834
		// rnd2 : 3076561A A4DC1FF2 DEC773CFD0737F248FD82E54FD90EBC2E3FBE56486E56288BE5F15BE51A5134D8CBFE4B33BACA2B41D9A2BF795F95E05AD6BF9AD7FD0D0AF5125906124D545DB8A9F5641C083A0E385E857BBE828272CD8754B423A8DA228A88041F177A9FC4FDCC9503189CC09084E36B892F3F743798DF10BD3D12E20C7BB9F0CE49F0E4951
		reset = 1;
		#40 reset = 0; init = 1;
        #10 init = 0;
		#40 din0 = 32'hA974B2AB; absorb = 1; absorb_extend = 1; 
		#10 din0 = 32'h34E0CE2A;
		#10 din0 = 32'h5CEEBAD3;
		#10 din0 = 32'hC2EDFA7B ^ 32'hD0737F24 ; din1 = 32'hD0737F24;
		#10 din0 = 32'hC4AAFAA7 ^ 32'hE3FBE564 ; din1 = 32'hE3FBE564;
		#10 din0 = 32'h9A7CF304; din1 = 0;
		#10 din0 = 32'hB3BC153B;
		#10 din0 = 32'h0308F8CF; // 8
		#10 din0 = 32'h00001F00 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; // 
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; // 18
		#10 din0 = 32'h00000000 ;  
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h80000000 ; //34
		#10 din0 = 32'h00000000 ; absorb = 0; absorb_extend = 1;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; 
		#10 absorb = 0; absorb_extend = 0;
		// --1--
		#40 go = 1;
		#10 go = 0;
		#300 squeeze_extend_0 = 1;
        #500 squeeze_extend_0 = 0;
        #100 squeeze_extend_1 = 1;
        #500 squeeze_extend_1 = 0;
        #20;
		// --2--
		#40 go = 1;
		#10 go = 0;
		#300 squeeze_extend_0 = 1;
        #500 squeeze_extend_0 = 0;
        #100 squeeze_extend_1 = 1;
        #500 squeeze_extend_1 = 0;
        #20;
		
		// rho = 65EAFD46 5FC64A0C 5F8F3F90 03489415 899D59A5 43D8208C 54A31665 29B53922 ;
		// XOF({rho,8'h0,8'h1}) =
		// rnd1 : FB7C700E5E8C851A6AB8A0425D554B9A63D57453F5F27CC0A41EC7951CA27B17AD2C7FD22DB7BDB9C39FD46F92B5415C983376558CAF594EB552CE9E688D0177D12BDA9B0354A6955FC4334266F653126B0E37D91A01E4365D56ED2BBCF494EC640BB5A5AAC3EE4CEA0803619F03CC8CA1E9EF47FAA2590CE2759E5032E51A1A7B29D67A4C9AE25C5910EACBDF6E45C2EA7F577728F65345CEBBB95DE2BB32C55DF4E480FBA014A1
		// rnd2 : E58BDC72E44B4B94240ACDE53E3AD62A0695840DDAEFC92B5BAA6025C71015B8E8EF5DDBD660301A57E4AC447607CFFB656BCA97E8C133A3EB5A5BDABEE4A94D8428186FD086407DBE9CA86AE7562148D60502110C761E450F287C7E66A2296FBC30B1990C9D63E83173DE7629F7FA1768406486C24C02D235296BBE3742D8799970202EDFF6C789266E371D5BF118E247A65E88BFF10D044298C0FDE278EEA9C97930BA7CF0504F
		// rnd3 : 2CEEE3C6611171DACDBF417B5953BF76B2EF9FE7B26F1AF4F50B2799DDC8AC81C982FDE7078E88D59C7E3AECDAE6434DA1623BF8A9833049D1B8BA5DEA5EBA35D437A359C358206FA7FF84BADC0A259D51E0B417FB37AF7D5AE400D7D6F412ADEC6D0830B7E50A87E6594B7F42313544DF25FD773D8FED1E491A04C055223965C3E36CA909720AEC1B2919B7413C5E03FFC0023CB9B173543B6AFC145B873D7225DD33FAD1449BBF
		#40 init = 1;
        #10 init = 0;
		#10 din0 = 32'h46FDEA65; absorb = 1; absorb_extend = 1;
		#10 din0 = 32'h0C4AC65F;
		#10 din0 = 32'h903F8F5F;
		#10 din0 = 32'h15944803;
		#10 din0 = 32'hA5599D89;
		#10 din0 = 32'h8C20D843;
		#10 din0 = 32'h6516A354;
		#10 din0 = 32'h2239B529; // 8
		#10 din0 = 32'h001F0100 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; // 
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; // 18
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; //34
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h80000000 ; // 42
		#10 din0 = 32'h00000000 ; absorb = 0; absorb_extend = 1;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 absorb = 0; absorb_extend = 0;
		// --1--
		#40 go = 1;
		#10 go = 0;
		#300 squeeze_extend_0 = 1;
        #500 squeeze_extend_0 = 0;
        #100 squeeze_extend_1 = 1;
        #500 squeeze_extend_1 = 0;
        #20;
		// --2--
		#40 go = 1;
		#10 go = 0;
		#300 squeeze_extend_0 = 1;
        #500 squeeze_extend_0 = 0;
        #100 squeeze_extend_1 = 1;
        #500 squeeze_extend_1 = 0;
        #20;
		// --3--
		#40 go = 1;
		#10 go = 0;
		#300 squeeze_extend_0 = 1;
        #500 squeeze_extend_0 = 0;
        #100 squeeze_extend_1 = 1;
        #500 squeeze_extend_1 = 0;
        #20;
		
		// d = 0x 7C9935A0 B07694AA 0C6D10E4 DB6B1ADD 2FD81A25 CCB14803 2DCD7399 36737F2D ;
		// G(d) = 65EAFD465FC64A0C 5F8F3F9003489415899D59A543D8208C54A3166529B53922 ABB274A92ACEE034D3BAEE5C7BFAEDC2A7FAAAC404F37C9A3B15BCB3 CFF80803
		#40 init = 1;
        #10 init = 0;
		#40 din0 = 32'hA035997C; absorb = 1; absorb_extend = 1;
		#10 din0 = 32'hAA9476B0;
		#10 din0 = 32'hE4106D0C;
		#10 din0 = 32'hDD1A6BDB;
		#10 din0 = 32'h251AD82F ^ 32'h04F37C9A ; din1 = 32'h04F37C9A;
		#10 din0 = 32'h0348B1CC ^ 32'h8CE67231 ; din1 = 32'h8CE67231;
		#10 din0 = 32'h9973CD2D; din1 = 0;
		#10 din0 = 32'h2D7F7336; // 8
		#10 din0 = 32'h00000006 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; // 
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h80000000 ; //18
		#10 din0 = 32'h00000000 ; absorb = 0; absorb_extend = 1;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 absorb = 0; absorb_extend = 0;
		#40 go = 1;
		#10 go = 0;
		#300 squeeze_extend_0 = 1;
        #500 squeeze_extend_0 = 0;
        #100 squeeze_extend_1 = 1;
        #500 squeeze_extend_1 = 0;
        #20;
					
		// rho = 65EAFD46 5FC64A0C 5F8F3F90 03489415 899D59A5 43D8208C 54A31665 29B53922 ;
		// XOF({rho,8'h0,8'h0}) =
		// rnd1 : E2E0126DEABE70EC0AD5CD95B548C14A08C95D2C065F784F3CE28A6F5832EE6D3060DA0C9CEC4C31B3491B40EA91C358EBB06A9C6D48333EC28CEBC68B8BAACCEDA69997034281556BE9114A221D8DA110749BD96632351F4586C68F5589EAAAACAB898CC61FC231F25B11C9ABD4677314CA073F3845EFA00F5F989A8FD902E702ABC191FE5ADF0C51BC0462DA4007CFC23D2F0FC2D221A89D786A72956721B818BF20BD53F42C1C
		// rnd2 : 6AAC023A7638C32E1DDA26D6BC460678FB0BFE36832CEE0C6D15130F07F7653720A7CA694913FBDB9F7E1744D4D694D9EC3EA541243015E1D50FDE3A1E68382216DB61902DA540C5B0A6C80A1FDA6E1694F8CF29D7350285F5900B280BB440A4D9A9CF80CCB149C241535CC0D33502809F9BE45E20B0DD6660B9A4369AD94EEB6C4B703C8BDD115BB4EE895472924727ACEF7F00AAA7EB85AE3E796EDCDC3E89C1D9CBFE5CB0F9AC
		// rnd3 : 5BCA6F2D153B025B2DF41698DD8B512A4485AB86047C64507E08945BA83E15D0356981C3949FE9366530C77453802D87B95F276A0043251190A0EC2F22F170A7B1AA62E999EC9E9752F00123C8D9AFC96AB5A7D010AB4DFAE435004A9EC14211C52E8EB2C59393E45C0DC3C340D0B100D3299B5999C0F95441B80C2D700AD41C943FE14E46061A64F7F8749E11326853B9C5FF4691D588D4482FB8538339BC978CB5C55A68A9F7ED
		#40 init = 1;
        #10 init = 0;
		#40 din0 = 32'h46FDEA65; absorb = 1; absorb_extend = 1;
		#10 din0 = 32'h0C4AC65F;
		#10 din0 = 32'h903F8F5F;
		#10 din0 = 32'h15944803;
		#10 din0 = 32'hA5599D89;
		#10 din0 = 32'h8C20D843;
		#10 din0 = 32'h6516A354;
		#10 din0 = 32'h2239B529; // 8
		#10 din0 = 32'h001F0000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; // 
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; // 18
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; //34
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h80000000 ; //42
		#10 din0 = 32'h00000000 ; absorb = 0; absorb_extend = 1;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 absorb = 0; absorb_extend = 0;
        // --1--
		#40 go = 1;
		#10 go = 0;
		#300 squeeze_extend_0 = 1;
        #500 squeeze_extend_0 = 0;
        #100 squeeze_extend_1 = 1;
        #500 squeeze_extend_1 = 0;
        #20;
        // --2--
		#40 go = 1;
		#10 go = 0;
		#300 squeeze_extend_0 = 1;
        #500 squeeze_extend_0 = 0;
        #100 squeeze_extend_1 = 1;
        #500 squeeze_extend_1 = 0;
        #20;
        // --3--
		#40 go = 1;
		#10 go = 0;
		#300 squeeze_extend_0 = 1;
        #500 squeeze_extend_0 = 0;
        #100 squeeze_extend_1 = 1;
        #500 squeeze_extend_1 = 0;
        #20;

        /*
		// m = 147C03F7 A5BEBBA4 06C8FAE1 874D7F13 C80EFE79 A3A9A874 CC09FE76 F6997615;
		// H(m) = 0A55A443 3DBAAC3B 616D6C43 38FCAEC4 A9685E8A A37D6A5B D74D6194 95CD3FED
		reset = 1;
		#4 reset = 0; init = 1;
		#4 in_ready = 1; din0 = 32'h147C03F7; init = 0; 
		#10 din0 = 32'hA5BEBBA4 ;
		#10 din0 = 32'h06C8FAE1 ;
		#10 din0 = 32'h874D7F13 ;
		#10 din0 = 32'hC80EFE79 ;
		#10 din0 = 32'hA3A9A874 ;
		#10 din0 = 32'hCC09FE76 ;
		#10 din0 = 32'hF6997615 ; // 8
		#10 din0 = 32'h06000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; // 
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; //
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000080 ; //34
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 in_ready = 0;
		#4 go = 1;
		#10 go = 0;
		#60 squeeze = 1;
		#16 squeeze = 0;
		#4		
		
		// m = 		CDE797DF 8CE67231 F6C5D158 11843E01 EB2AB84C 74909312 40822ADB DDD72046;
		// H(m) = 	2774F4E7 8EB59BB2 DC3421B1 2B5CE5A5 82E93D88 88F67A55 D3D3521E 7F6EB0C6
		reset = 1;
		#4 reset = 0; init = 1;
		#4 in_ready = 1; din0 = 32'hCDE797DF ; init = 0; 
		#10 din0 = 32'h8CE67231 ;
		#10 din0 = 32'hF6C5D158 ;
		#10 din0 = 32'h11843E01 ;
		#10 din0 = 32'hEB2AB84C ;
		#10 din0 = 32'h74909312 ;
		#10 din0 = 32'h40822ADB ;
		#10 din0 = 32'hDDD72046 ; // 8
		#10 din0 = 32'h06000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; // 
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; //18
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000080 ; //34
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 in_ready = 0;
		#4 go = 1;
		#10 go = 0;
		#60 squeeze = 1;
		#16 squeeze = 0;
		#4			
		
		// d = D60B9349 2A1D8C1C 7BA6FC0B 733137F3 406CEE81 10A93F17 0E7A7865 8AF326D9
		// G(d) = 96F13F56 BE785D94 2D7EAB01 1805CF35 04FCE325 B6A5EF1A AADBBB11 C662B9D2 61BB470760DAB9BEE525B7EAA67809C438779B783A73FFA391872B4A3A9D12048D7ADCB31C6E356B
		reset = 1;
		#4 reset = 0; init = 1;
		#4 in_ready = 1; din0 = 32'hD60B9349; init = 0; 
		#10 din0 = 32'h2A1D8C1C ;
		#10 din0 = 32'h7BA6FC0B ;
		#10 din0 = 32'h733137F3 ;
		#10 din0 = 32'h406CEE81 ;
		#10 din0 = 32'h10A93F17 ;
		#10 din0 = 32'h0E7A7865 ;
		#10 din0 = 32'h8AF326D9 ; // 8
		#10 din0 = 32'h06000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ; // 
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000080 ; //18
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 din0 = 32'h00000000 ;
		#10 in_ready = 0;
		#4 go = 1;
		#10 go = 0;
		#60 squeeze = 1;
		#32 squeeze = 0;
		#4
        */
		$stop;
	end 

endmodule
