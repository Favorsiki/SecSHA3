`timescale 1ns/1ns

module keccak_chi_iota #(
        parameter SHARES = 2,
        parameter SLICES = 1,
        parameter CHI_DOUBLE_CLK = 1,
        parameter LESS_RAND = 0,
        parameter DOM_PIPELINE = 0
    )
    (
        input wire ClkxCI,
        input wire EnablexSI,
        input wire RstxRBI,
        input wire[SHARES*25*SLICES-1:0] SlicesxDI,
        input wire[(SHARES*SHARES-SHARES)/2*25*SLICES-1:0] ZxDI,
        input wire[SLICES-1:0] IotaRCxDI,
        output reg[SHARES*25*SLICES-1:0] SlicesxDO
    );

localparam W = SLICES;
function integer Idx(input integer x, input integer y);
    Idx = (5*x+y)*W;
endfunction

generate
//-----------------------------------------------------------------------------
// Generate unprotected Chi step
if(SHARES == 1) begin
    always @(*) begin : CHI_UNPROTECTED_COMB
        integer x0, x1, x2, y;
        reg[25*W-1:0] S, result;

        S = SlicesxDI;
        result = {25*W{1'b0}};
        for(x0=0; x0 < 5; x0=x0+1) begin : SBOX_LOOP
            x1 = (x0 + 1) % 5;
            x2 = (x0 + 2) % 5;
            for(y=0; y < 5; y=y+1) begin
                //-------------------------------------------------------------
                // Chi step
                result[Idx(x0,y) +: W] = S[Idx(x0,y) +: W] ^ (~S[Idx(x1,y) +: W] & S[Idx(x2,y) +: W]);

                //-------------------------------------------------------------
                // Iota step
                if(x0 == 0 && y == 0) begin
                    result[0 +: W] = result[0 +: W] ^ IotaRCxDI;
                end
            end
        end
        SlicesxDO = result;
    end
end else if (1) begin
  //-----------------------------------------------------------------------------
  // Generate protected Chi step using individual S-Box instantiations
  genvar y, z;


  function integer RowIdx(input integer share_nr, input integer idx_x, input integer idx_y);
      RowIdx = share_nr*25*SLICES + (5*idx_x + idx_y)*SLICES;
  endfunction

  for(z = 0; z < SLICES; z=z+1) begin : GEN_SLICES
    for (y = 0; y < 5; y=y+1) begin : GEN_ROWS
      reg[SHARES*5-1 : 0] RowsInxD;
      wire[SHARES*5-1 : 0] RowsOutxD;
      reg[5*(SHARES*SHARES-SHARES)/2-1 : 0] RowsRandxD;

      always @(*) begin : ROW_SEL_IN
        integer i;
                    //S = SlicesxDI[i*25*W +: 25*W];
        for (i = 0; i < SHARES; i=i+1) begin
          RowsInxD[i*5 + 0] = SlicesxDI[RowIdx(i,0,y) + z];
          RowsInxD[i*5 + 1] = SlicesxDI[RowIdx(i,1,y) + z];
          RowsInxD[i*5 + 2] = SlicesxDI[RowIdx(i,2,y) + z];
          RowsInxD[i*5 + 3] = SlicesxDI[RowIdx(i,3,y) + z];
          RowsInxD[i*5 + 4] = SlicesxDI[RowIdx(i,4,y) + z];
        end
        RowsRandxD = ZxDI[25*z + 5*y +: 5*(SHARES*SHARES - SHARES)/2];
      end

      always @(*) begin : ROW_SEL_OUT
        integer i;
        for (i = 0; i < SHARES; i=i+1) begin
          SlicesxDO[RowIdx(i,0,y) + z] = RowsOutxD[i*5 + 0];
          SlicesxDO[RowIdx(i,1,y) + z] = RowsOutxD[i*5 + 1];
          SlicesxDO[RowIdx(i,2,y) + z] = RowsOutxD[i*5 + 2];
          SlicesxDO[RowIdx(i,3,y) + z] = RowsOutxD[i*5 + 3];
          SlicesxDO[RowIdx(i,4,y) + z] = RowsOutxD[i*5 + 4];
        end
        //integer i, y, z, x;
        //for (i = 0; i < SHARES; i=i+1) begin
        //  for (z = 0; z < SLICES; z=z+1) begin
        //    for (y = 0; y < 5; y=y+1) begin
        //      for (x = 0; x < 5; x=x+1) begin
        //        SlicesxDO[i*25*SLICES + 25*z + 5*x + y] = RowsOutxD[i*5 + x];
        //      end
        //    end
        //  end
        //end
      end

      if (y == 0) begin
        keccak_sbox
          #(.SHARES(SHARES)
          , .CHI_DOUBLE_CLK(CHI_DOUBLE_CLK)
          , .LESS_RAND(LESS_RAND)
          , .DOM_PIPELINE(DOM_PIPELINE)
          , .IOTA_XOR(1)
          ) sbox
          ( .ClkxCI(ClkxCI)
          , .RstxRBI(RstxRBI)
          , .EnablexSI(EnablexSI)
          , .IotaRCxDI(IotaRCxDI[z])
          , .InputxDI(RowsInxD)
          , .ZxDI(RowsRandxD)
          , .OutputxDO(RowsOutxD)
          );
      end else begin
        keccak_sbox
          #(.SHARES(SHARES)
          , .CHI_DOUBLE_CLK(CHI_DOUBLE_CLK)
          , .LESS_RAND(LESS_RAND)
          , .DOM_PIPELINE(DOM_PIPELINE)
          , .IOTA_XOR(0)
          ) sbox
          ( .ClkxCI(ClkxCI)
          , .RstxRBI(RstxRBI)
          , .EnablexSI(EnablexSI)
          , .IotaRCxDI(1'b0)
          , .InputxDI(RowsInxD)
          , .ZxDI(RowsRandxD)
          , .OutputxDO(RowsOutxD)
          );
      end

    end
  end
end
//-----------------------------------------------------------------------------
// Generate protected Chi step
else begin

    localparam NUM_FF = DOM_PIPELINE ? (SHARES*SHARES)*25*W
                                     : (SHARES*SHARES - SHARES)*25*W;
    reg[NUM_FF-1:0] FFxDN, FFxDP;
    if(CHI_DOUBLE_CLK) begin
        always @(negedge ClkxCI or negedge RstxRBI) begin
            if(~RstxRBI) FFxDP <= {NUM_FF{1'b0}};
            else if(EnablexSI) FFxDP <= FFxDN;
        end
    end
    else begin
        always @(posedge ClkxCI or negedge RstxRBI) begin
            if(~RstxRBI) FFxDP <= {NUM_FF{1'b0}};
            else if(EnablexSI) FFxDP <= FFxDN;
        end
    end

    always @(*) begin : SBOXES
        integer i, j, x0, x1, x2, y, ff_idx;
        reg[W-1:0] result;
        reg[25*W-1:0] S, T;
        reg[SHARES*25*W-1:0] SlicesxD;

        FFxDN = {NUM_FF{1'b0}};

        for(x0=0; x0 < 5; x0=x0+1) begin
            x1 = (x0 + 1) % 5;
            x2 = (x0 + 2) % 5;
            for(y=0; y < 5; y=y+1) begin
                for(i=0; i < SHARES; i=i+1) begin

                    //---------------------------------------------------------
                    // Chi step
                    result = {W{1'b0}};
                    S = SlicesxDI[i*25*W +: 25*W];
                    for(j=0; j < SHARES; j=j+1) begin
                        T = SlicesxDI[j*25*W +: 25*W];
                        if(i==j) begin
                            // inner domain term

                            if(DOM_PIPELINE) begin
                                ff_idx = i*SHARES+i;
                                if(LESS_RAND && i >= SHARES-2) begin
                                    FFxDN[ff_idx*25*W + Idx(x0,y) +: W] = (~S[Idx(x1,y) +: W] & S[Idx(x2,y) +: W]);
                                end
                                else begin
                                    FFxDN[ff_idx*25*W + Idx(x0,y) +: W] = S[Idx(x0,y) +: W] ^ (~S[Idx(x1,y) +: W] & S[Idx(x2,y) +: W]);
                                end
                                result = result ^ FFxDP[ff_idx*25*W + Idx(x0,y) +: W];
                            end
                            else begin
                                if(LESS_RAND && i >= SHARES-2) begin
                                    // Don't XOR the A_xi part if that is done in the cross-domain term
                                    result = result ^ (~S[Idx(x1,y) +: W] & S[Idx(x2,y) +: W]);
                                end
                                else begin
                                    result = result ^ S[Idx(x0,y) +: W] ^ (~S[Idx(x1,y) +: W] & S[Idx(x2,y) +: W]);
                                end
                            end
                        end
                        else if(i < j) begin
                            // cross domain term
                            if(DOM_PIPELINE)
                                ff_idx = i*SHARES + j;
                            else
                                ff_idx = i*(SHARES-1) + j-1;

                            if(LESS_RAND && (i + j*(j-1)/2) == (SHARES*SHARES-SHARES)/2-1) begin
                                FFxDN[ff_idx*25*W + Idx(x0,y) +: W]
                                    = (S[Idx(x1,y) +: W] & T[Idx(x2,y) +: W]) ^ S[Idx(x0,y) +: W];
                            end
                            else begin
                                FFxDN[ff_idx*25*W + Idx(x0,y) +: W]
                                    = (S[Idx(x1,y) +: W] & T[Idx(x2,y) +: W])
                                    ^ ZxDI[(i + j*(j-1)/2)*25*W + Idx(x0,y) +: W];
                            end

                            result = result ^ FFxDP[ff_idx*25*W + Idx(x0,y) +: W];

                            //---------------------------------------------------------
                            // Iota step
                            if(i == 0 && x0 == 0 && y == 0 && (i + j*(j-1)/2)==0) begin
                                FFxDN[ff_idx*25*W + Idx(x0,y) +: W] = IotaRCxDI ^ FFxDN[ff_idx*25*W + Idx(x0,y) +: W];
                            end
                        end
                        else if(i > j) begin
                            // cross domain term
                            if(DOM_PIPELINE)
                                ff_idx = i*SHARES + j;
                            else
                                ff_idx = i*(SHARES-1) + j;

                            if(LESS_RAND && (j + i*(i-1)/2) == (SHARES*SHARES-SHARES)/2-1) begin
                                FFxDN[ff_idx*25*W + Idx(x0,y) +: W]
                                    = (S[Idx(x1,y) +: W] & T[Idx(x2,y) +: W]) ^ S[Idx(x0,y) +: W];
                            end
                            else begin
                                FFxDN[ff_idx*25*W + Idx(x0,y) +: W]
                                    = (S[Idx(x1,y) +: W] & T[Idx(x2,y) +: W])
                                    ^ ZxDI[(j + i*(i-1)/2)*25*W + Idx(x0,y) +: W];
                            end

                            result = result ^ FFxDP[ff_idx*25*W + Idx(x0,y) +: W];
                        end
                    end
                    SlicesxDO[i*25*W + Idx(x0,y) +: W] = result;

                end
            end
        end

    end

end

endgenerate

endmodule
