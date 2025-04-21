--
-- -----------------------------------------------------------------
-- COMPANY : Ruhr University Bochum
-- AUTHOR  : Amir Moradi amir.moradi@rub.de Aein Rezaei Shahmirzadi aein.rezaeishahmirzadi@rub.de
-- DOCUMENT: "Second-Order SCA Security with almost no Fresh Randomness" TCHES 2021, Issue 3
-- -----------------------------------------------------------------
--
-- Copyright c 2021, Amir Moradi, Aein Rezaei Shahmirzadi
--
-- All rights reserved.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTERS BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- INCLUDING NEGLIGENCE OR OTHERWISE ARISING IN ANY WAY OUT OF THE USE OF THIS
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
ENTITY KeccakRoundTI IS
    PORT (  CLK       : IN  STD_LOGIC;
            RESET     : IN  STD_LOGIC;
            ENABLE    : IN  STD_LOGIC;
            INPUT1    : IN  STD_LOGIC_VECTOR(1599 DOWNTO 0);
		    INPUT2    : IN  STD_LOGIC_VECTOR(1599 DOWNTO 0);
            CONST     : IN  STD_LOGIC_VECTOR(  63 DOWNTO 0);
            OUTPUT1   : OUT STD_LOGIC_VECTOR(1599 DOWNTO 0);
		    OUTPUT2   : OUT STD_LOGIC_VECTOR(1599 DOWNTO 0));
END KeccakRoundTI;



-- ARCHITECTURE : STRUCTURAL
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF KeccakRoundTI IS

    -- COMPONENTS ----------------------------------------------------------------

    COMPONENT RegisterFDRE IS
        GENERIC (SIZE : POSITIVE := 1600);
        PORT ( CLK      : IN    STD_LOGIC;
               RESET    : IN    STD_LOGIC;
               ENABLE   : IN    STD_LOGIC;
               D        : IN    STD_LOGIC_VECTOR((SIZE - 1) downto 0);
               Q        : OUT   STD_LOGIC_VECTOR((SIZE - 1) downto 0));
    END COMPONENT;

    COMPONENT theta IS
        PORT ( X : IN  STD_LOGIC_VECTOR(1599 DOWNTO 0);
               Y : OUT STD_LOGIC_VECTOR(1599 DOWNTO 0));
    END COMPONENT;

    COMPONENT rho IS
        PORT ( X : IN  STD_LOGIC_VECTOR(1599 DOWNTO 0);
               Y : OUT STD_LOGIC_VECTOR(1599 DOWNTO 0));
    END COMPONENT;
    
    COMPONENT pi IS
        PORT ( X : IN  STD_LOGIC_VECTOR(1599 DOWNTO 0);
               Y : OUT STD_LOGIC_VECTOR(1599 DOWNTO 0));
    END COMPONENT;
    
    COMPONENT chiTI IS
        PORT ( CLK		: IN  STD_LOGIC;
					X1 		: IN  STD_LOGIC_VECTOR(1599 DOWNTO 0);
				   X2 		: IN  STD_LOGIC_VECTOR(1599 DOWNTO 0);
               Y1 		: OUT STD_LOGIC_VECTOR(1599 DOWNTO 0);
					Y2 		: OUT STD_LOGIC_VECTOR(1599 DOWNTO 0));
    END COMPONENT;
    
    COMPONENT iota IS
        PORT ( X : IN  STD_LOGIC_VECTOR(1599 DOWNTO 0);
               C : IN  STD_LOGIC_VECTOR(  63 DOWNTO 0);
               Y : OUT STD_LOGIC_VECTOR(1599 DOWNTO 0));
    END COMPONENT;
    
    -- SIGNALS -------------------------------------------------------------------
    SIGNAL TMP1_1, TMP2_1, TMP3_1, TMP4_1, TMP5_1 : STD_LOGIC_VECTOR(1599 DOWNTO 0);
    SIGNAL TMP1_2, TMP2_2, TMP3_2, TMP4_2, TMP5_2 : STD_LOGIC_VECTOR(1599 DOWNTO 0);
    SIGNAL TMP1_3, TMP2_3, TMP3_3, TMP4_3, TMP5_3 : STD_LOGIC_VECTOR(1599 DOWNTO 0);
    
    SIGNAL STATE1, STATE2 : STD_LOGIC_VECTOR(1599 DOWNTO 0);
	 SIGNAL Feedback1, Feedback2 : STD_LOGIC_VECTOR(1599 DOWNTO 0);
	 SIGNAL MuxInput1, MuxInput2 : STD_LOGIC_VECTOR(1599 DOWNTO 0);
    SIGNAL TMP3_1_Reg, TMP3_2_Reg     : STD_LOGIC_VECTOR(1599 DOWNTO 0);
    SIGNAL MUX1, MUX2     : STD_LOGIC_VECTOR(1599 DOWNTO 0);

BEGIN

    -- REGISTER ------------------------------------------------------------------
	Reg_chiInput1: Entity work.regVariable 
	GENERIC MAP (1600)
	PORT MAP(
		clk => clk,
		D => TMP3_1,
		Q => TMP3_1_Reg );
		
	Reg_chiInput2: Entity work.regVariable 
	GENERIC MAP (1600)
	PORT MAP(
		clk => clk,
		D => TMP3_2,
		Q => TMP3_2_Reg );
		
    -- MULTIPLEXER ---------------------------------------------------------------
	 MuxInput1 <= INPUT1;
	 MuxInput2 <= INPUT2;
	 
    MUX1 <= MuxInput1 WHEN (RESET = '1') ELSE Feedback1;
    MUX2 <= MuxInput2 WHEN (RESET = '1') ELSE Feedback2;
    ------------------------------------------------------------------------------
     StateReg1: Entity work.regVariable 
	GENERIC MAP (1600)
	PORT MAP(
		clk => clk,
		D => MUX1,
		Q => STATE1 );
		
	StateReg2: Entity work.regVariable 
	GENERIC MAP (1600)
	PORT MAP(
		clk => clk,
		D => MUX2,
		Q => STATE2 );
    -- SUB-FUNCTIONS -------------------------------------------------------------
    T1 : theta PORT MAP (X => STATE1,  Y => TMP1_1);
    R1 : rho   PORT MAP (X => TMP1_1,  Y => TMP2_1);
    P1 : pi    PORT MAP (X => TMP2_1,  Y => TMP3_1);
    I1 : iota  PORT MAP (X => TMP4_1,  C => CONST, Y => TMP5_1);
    
    T2 : theta PORT MAP (X => STATE2,  Y => TMP1_2);
    R2 : rho   PORT MAP (X => TMP1_2,  Y => TMP2_2);
    P2 : pi    PORT MAP (X => TMP2_2,  Y => TMP3_2);

	 -------------------------------------------------------------------------------
	
	 C : chiTI   PORT MAP (
	   CLK		=> CLK,
		X1 		=> TMP3_1_Reg,
		X2 		=> TMP3_2_Reg,
		Y1 		=> TMP4_1, --iota step only on one share
		Y2 		=> TMP5_2);
		
	Feedback1 <= TMP5_1;
	Feedback2 <= TMP5_2;
    
    -- RESULT --------------------------------------------------------------------
    OUTPUT1 <= TMP5_1;
    OUTPUT2 <= TMP5_2;
    ------------------------------------------------------------------------------
    
END Structural;
