--
-- -----------------------------------------------------------------
-- COMPANY : Ruhr University Bochum
-- AUTHOR  : Amir Moradi (amir.moradi@rub.de) Aein Rezaei Shahmirzadi (aein.rezaeishahmirzadi@rub.de)
-- DOCUMENT: "Second-Order SCA Security with almost no Fresh Randomness" (TCHES 2021, Issue 3)
-- -----------------------------------------------------------------
--
-- Copyright (c) 2021, Amir Moradi, Aein Rezaei Shahmirzadi
--
-- All rights reserved.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTERS BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-- Please see LICENSE and README for license and further instructions.
--


-- IMPORTS
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;



-- ENTITY
----------------------------------------------------------------------------------
ENTITY chiTI is
        PORT ( CLK		: IN  STD_LOGIC;
					X1 		: IN  STD_LOGIC_VECTOR(1599 DOWNTO 0);
				   X2 		: IN  STD_LOGIC_VECTOR(1599 DOWNTO 0);
               Y1 		: OUT STD_LOGIC_VECTOR(1599 DOWNTO 0);
					Y2 		: OUT STD_LOGIC_VECTOR(1599 DOWNTO 0));
END chiTI;



-- ARCHITECTURE : DATAFLOW
----------------------------------------------------------------------------------
ARCHITECTURE Dataflow OF chiTI IS

	COMPONENT Chi_NoFresh
	PORT(
		clk : IN std_logic;
		in1 : IN std_logic_vector(4 downto 0);
		in2 : IN std_logic_vector(4 downto 0);          
		out1 : OUT std_logic_vector(4 downto 0);
		out2 : OUT std_logic_vector(4 downto 0)
		);
	END COMPONENT;
	
	type FiveBit_ARRAY is array (integer range <>) of std_logic_vector(4 downto 0);
	type Byte_ARRAY    is array (integer range <>) of std_logic_vector(3 downto 0);
	
	signal InArray1  : FiveBit_ARRAY(319 downto 0);
	signal InArray2  : FiveBit_ARRAY(319 downto 0);
	signal InArray3  : FiveBit_ARRAY(319 downto 0);
	signal OutArray1 : FiveBit_ARRAY(319 downto 0);
	signal OutArray2 : FiveBit_ARRAY(319 downto 0);
	signal OutArray3 : FiveBit_ARRAY(319 downto 0);

BEGIN

    GENj : FOR j IN 0 TO 4 GENERATE
		GENi : FOR i IN 0 TO 63 GENERATE
			InArray1(64*j+i)     <= X1(320*j+256+i) & X1(320*j+192+i) & X1(320*j+128+i) & X1(320*j+64+i) & X1(320*j+i);
			InArray2(64*j+i)     <= X2(320*j+256+i) & X2(320*j+192+i) & X2(320*j+128+i) & X2(320*j+64+i) & X2(320*j+i);
			--InArray3(64*j+i)     <= X3(320*j+256+i) & X3(320*j+192+i) & X3(320*j+128+i) & X3(320*j+64+i) & X3(320*j+i);
			
			Y1(320*j+256+i) <= OutArray1(64*j+i)(4);
			Y1(320*j+192+i) <= OutArray1(64*j+i)(3);
			Y1(320*j+128+i) <= OutArray1(64*j+i)(2);
			Y1(320*j+64+i)  <= OutArray1(64*j+i)(1);
			Y1(320*j+i)		 <= OutArray1(64*j+i)(0);

			Y2(320*j+256+i) <= OutArray2(64*j+i)(4);
			Y2(320*j+192+i) <= OutArray2(64*j+i)(3);
			Y2(320*j+128+i) <= OutArray2(64*j+i)(2);
			Y2(320*j+64+i)  <= OutArray2(64*j+i)(1);
			Y2(320*j+i)		 <= OutArray2(64*j+i)(0);

--			Y3(320*j+256+i) <= OutArray3(64*j+i)(4);
--			Y3(320*j+192+i) <= OutArray3(64*j+i)(3);
--			Y3(320*j+128+i) <= OutArray3(64*j+i)(2);
--			Y3(320*j+64+i)  <= OutArray3(64*j+i)(1);
--			Y3(320*j+i)		 <= OutArray3(64*j+i)(0);
		END GENERATE Geni;
	END GENERATE Genj;


		
	GEN : FOR i IN 0 TO 319 GENERATE
		
		Inst_Chi_NoFresh: Chi_NoFresh 
		PORT MAP(
			clk => CLK,
			in1 => InArray1(i),
			in2 => InArray2(i),
			out1 => OutArray1(i),
			out2 => OutArray2(i) );
		
	END GENERATE;		
	
END Dataflow;
