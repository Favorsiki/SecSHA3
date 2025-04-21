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
ENTITY Keccak1600 IS
    PORT ( CLK      : IN  STD_LOGIC;
           -- CONTROL SIGNAL PORTS ---------------------------
           RESET    : IN  STD_LOGIC;
           ENABLE   : IN  STD_LOGIC;
           DONE     : OUT STD_LOGIC;
           -- DATA SIGNAL PORTS ------------------------------
           MESSAGE1 : IN  STD_LOGIC_VECTOR(1599 DOWNTO 0);
           MESSAGE2 : IN  STD_LOGIC_VECTOR(1599 DOWNTO 0);
           RESULT1  : OUT STD_LOGIC_VECTOR(1599 DOWNTO 0);
           RESULT2  : OUT STD_LOGIC_VECTOR(1599 DOWNTO 0));
END Keccak1600;



-- ARCHITECTURE : STRUCTURAL
----------------------------------------------------------------------------------
ARCHITECTURE Structural OF Keccak1600 IS

    -- COMPONENTS ----------------------------------------------------------------

    COMPONENT StateMachine_nullfresh IS
        PORT ( CLK          : in STD_LOGIC;
               RESET        : IN  STD_LOGIC;
               ENABLE       : IN  STD_LOGIC;
               DONE         : OUT STD_LOGIC;
               CONST        : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
    END COMPONENT;

    -- SIGNALS -------------------------------------------------------------------
    SIGNAL RESET_RF, LOAD_RF, ENABLE_RF               : STD_LOGIC;
    SIGNAL REORDER_IN1,  REORDER_IN2,  REORDER_IN3    : STD_LOGIC_VECTOR(1599 DOWNTO 0);
    SIGNAL REORDER_OUT1, REORDER_OUT2, REORDER_OUT3   : STD_LOGIC_VECTOR(1599 DOWNTO 0);
    SIGNAL CONST                                      : STD_LOGIC_VECTOR(  63 DOWNTO 0);

BEGIN

    -- GEN : FOR I IN 0 TO 135 GENERATE
    --     REORDER_IN1(1087 - I * 8 DOWNTO 1080 - I * 8)    <=    MESSAGE1(    I * 8 + 7 DOWNTO I * 8);
    --     REORDER_IN2(1087 - I * 8 DOWNTO 1080 - I * 8)    <=    MESSAGE2(    I * 8 + 7 DOWNTO I * 8);
       
    --     RESULT1(    1087 - I * 8 DOWNTO 1080 - I * 8)    <=    REORDER_OUT1(I * 8 + 7 DOWNTO I * 8);
    --     RESULT2(    1087 - I * 8 DOWNTO 1080 - I * 8)    <=    REORDER_OUT2(I * 8 + 7 DOWNTO I * 8);

    -- END GENERATE;
    REORDER_IN1 <= MESSAGE1;
    REORDER_IN2 <= MESSAGE2;
    RESULT1 <= REORDER_OUT1;
    RESULT2 <= REORDER_OUT2;
    RoundFunction : entity work.KeccakRoundTI
    PORT MAP (
        CLK      => CLK,
        RESET    => RESET,
        ENABLE   => ENABLE,
        CONST    => CONST,
        INPUT1   => REORDER_IN1,
        INPUT2   => REORDER_IN2,
        OUTPUT1  => REORDER_OUT1,
        OUTPUT2  => REORDER_OUT2
    );

    FSM : StateMachine_nullfresh
    PORT MAP (
        CLK         => CLK,
        RESET       => RESET,
        ENABLE      => ENABLE,
        DONE        => DONE,
        CONST       => CONST
    );
    
END Structural;
