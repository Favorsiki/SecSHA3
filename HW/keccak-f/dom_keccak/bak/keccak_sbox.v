`timescale 1ns/1ns

module keccak_sbox
  #(parameter SHARES = 2
  , parameter CHI_DOUBLE_CLK = 1
  , parameter LESS_RAND = 0
  , parameter DOM_PIPELINE = 0
  , parameter IOTA_XOR = 0
  )
  ( input  wire ClkxCI
  , input  wire RstxRBI
  , input  wire EnablexSI
  , input  wire IotaRCxDI
  , input  wire[SHARES*5-1:0] InputxDI
  , input  wire[(SHARES*SHARES-SHARES)/2*5-1:0] ZxDI
  , output  reg[SHARES*5-1:0] OutputxDO
  );

  localparam NUM_FF = DOM_PIPELINE ? (SHARES*SHARES)*5 : (SHARES*SHARES - SHARES)*5;

  reg[NUM_FF-1:0] FFxDN, FFxDP;

  always @(*) begin : SBOX
    integer i, j, x0, x1, x2, ff_idx, rand_idx;
    reg result;
    reg[4:0] S, T;

    FFxDN = {NUM_FF{1'b0}};

    for(x0 = 0; x0 < 5; x0=x0+1) begin
      x1 = (x0 + 1) % 5;
      x2 = (x0 + 2) % 5;
      for (i = 0; i < SHARES; i=i+1) begin
        result = 1'b0;
        S = InputxDI[i*5 +: 5];
        for (j = 0; j < SHARES; j=j+1) begin
          T = InputxDI[j*5 +: 5];

          if (i == j) begin
            // inner domain term
            if (DOM_PIPELINE) begin
              ff_idx = i*SHARES + i;
              if (LESS_RAND && i >= SHARES-2) begin
                // Don't XOR the A_xi part if that is done in the cross-domain term
                FFxDN[ff_idx*5 + x0] = ~S[x1] & S[x2];
              end else begin
                FFxDN[ff_idx*5 + x0] = S[x0] ^ (~S[x1] & S[x2]);
              end
              result = result ^ FFxDP[ff_idx*5 + x0];

            end else begin
              if (LESS_RAND && i >= SHARES-2) begin
                // Don't XOR the A_xi part if that is done in the cross-domain term
                result = result ^ (~S[x1] & S[x2]);
              end else begin
                result = result ^ S[x0] ^ (~S[x1] & S[x2]);
              end
            end
          end else if (i < j) begin
            // cross domain term
            rand_idx = i + j*(j-1)/2;
            if (DOM_PIPELINE) begin
              ff_idx = i*SHARES + j;
            end else begin
              ff_idx = i*(SHARES-1) + j-1;
            end

            //TODO kind of redundant with i > j
            if (LESS_RAND && rand_idx == (SHARES*SHARES-SHARES)/2-1) begin
              FFxDN[ff_idx*5 + x0] = (S[x1] & T[x2]) ^ S[x0];
            end else begin
              FFxDN[ff_idx*5 + x0] = (S[x1] & T[x2]) ^ ZxDI[rand_idx*5 + x0];
            end

            result = result ^ FFxDP[ff_idx*5 + x0];

            //---------------------------------------------------------
            // Iota step
            if (IOTA_XOR && i == 0 && x0 == 0 && rand_idx==0) begin
              FFxDN[ff_idx*5 + x0] = IotaRCxDI ^ FFxDN[ff_idx*5 + x0];
            end
          end else if (i > j) begin
            // cross domain term
            rand_idx = j + i*(i-1)/2;
            if (DOM_PIPELINE) begin
              ff_idx = i*SHARES + j;
            end else begin
              ff_idx = i*(SHARES-1) + j;
            end

            if (LESS_RAND && rand_idx == (SHARES*SHARES-SHARES)/2-1) begin
              FFxDN[ff_idx*5 + x0] = (S[x1] & T[x2]) ^ S[x0];
            end else begin
              FFxDN[ff_idx*5 + x0] = (S[x1] & T[x2]) ^ ZxDI[rand_idx*5 + x0];
            end

            result = result ^ FFxDP[ff_idx*5 + x0];
          end
        end

        OutputxDO[i*5 + x0] = result;
      end
    end
  end

  if(CHI_DOUBLE_CLK) begin
    always @(negedge ClkxCI or negedge RstxRBI) begin
      if(~RstxRBI)       FFxDP <= {NUM_FF{1'b0}};
      else if(EnablexSI) FFxDP <= FFxDN;
    end
  end
  else begin
    always @(posedge ClkxCI or negedge RstxRBI) begin
      if(~RstxRBI)       FFxDP <= {NUM_FF{1'b0}};
      else if(EnablexSI) FFxDP <= FFxDN;
    end
  end

endmodule
