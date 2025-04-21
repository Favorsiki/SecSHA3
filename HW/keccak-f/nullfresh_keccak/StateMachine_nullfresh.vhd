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
ENTITY StateMachine_nullfresh IS
    PORT ( CLK          : in STD_LOGIC;
           RESET        : IN  STD_LOGIC;
           ENABLE       : IN  STD_LOGIC;
           DONE         : OUT STD_LOGIC;
           CONST        : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
END StateMachine_nullfresh;



-- ARCHITECTURE : FSM
----------------------------------------------------------------------------------
ARCHITECTURE FSM OF StateMachine_nullfresh IS

    -- STATES --------------------------------------------------------------------
    TYPE STATES IS (S_RESET,S_IDLE, S_ROUND, S_ROUND2, S_ROUND3, S_DONE);
    SIGNAL STATE, NEXT_STATE : STATES;

    -- SIGNALS -------------------------------------------------------------------
    SIGNAL ENABLE_LFSR              : STD_LOGIC;
    SIGNAL RESET_LFSR               : STD_LOGIC;
    SIGNAL LFSR                     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL CONST_internal           : STD_LOGIC_VECTOR(63 DOWNTO 0);
    
BEGIN

    -- LFSR ----------------------------------------------------------------------
    PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF (RESET_LFSR = '1') THEN
                LFSR <= (0 => '1', OTHERS => '0');
            ELSIF (ENABLE_LFSR = '1') THEN
                LFSR <= LFSR(6 DOWNTO 0) & (LFSR(7) XOR LFSR(5) XOR LFSR(4) XOR LFSR(3));
            END IF;
        END IF;
    END PROCESS;
    
    PROCESS(LFSR)
    BEGIN
        CASE LFSR IS
            WHEN X"01"  => CONST_internal <= X"0000000000000001";
            WHEN X"02"  => CONST_internal <= X"0000000000008082";
            WHEN X"04"  => CONST_internal <= X"800000000000808A";
            WHEN X"08"  => CONST_internal <= X"8000000080008000";
            WHEN X"11"  => CONST_internal <= X"000000000000808B";
            WHEN X"23"  => CONST_internal <= X"0000000080000001";
            WHEN X"47"  => CONST_internal <= X"8000000080008081";
            WHEN X"8E"  => CONST_internal <= X"8000000000008009";
            WHEN X"1C"  => CONST_internal <= X"000000000000008A";
            WHEN X"38"  => CONST_internal <= X"0000000000000088";
            WHEN X"71"  => CONST_internal <= X"0000000080008009";
            WHEN X"E2"  => CONST_internal <= X"000000008000000A";
            WHEN X"C4"  => CONST_internal <= X"000000008000808B";
            WHEN X"89"  => CONST_internal <= X"800000000000008B";
            WHEN X"12"  => CONST_internal <= X"8000000000008089";
            WHEN X"25"  => CONST_internal <= X"8000000000008003";
            WHEN X"4B"  => CONST_internal <= X"8000000000008002";
            WHEN X"97"  => CONST_internal <= X"8000000000000080";
            WHEN X"2E"  => CONST_internal <= X"000000000000800A";
            WHEN X"5C"  => CONST_internal <= X"800000008000000A";
            WHEN X"B8"  => CONST_internal <= X"8000000080008081";
            WHEN X"70"  => CONST_internal <= X"8000000000008080";
            WHEN X"E0"  => CONST_internal <= X"0000000080000001";
            WHEN X"C0"  => CONST_internal <= X"8000000080008008";                
            WHEN OTHERS => CONST_internal <= X"0000000000000000";
        END CASE;
    END PROCESS;
    ------------------------------------------------------------------------------
    RegConxt: Entity work.regVariable 
	GENERIC MAP (64)
	PORT MAP(
		clk => CLK,
		D => CONST_internal,
		Q => CONST );
    -- STATE REGISTER PROCESS ----------------------------------------------------
    StateRegister : PROCESS(CLK)
    BEGIN
        IF RISING_EDGE(CLK) THEN
            IF (RESET = '1') THEN
                STATE    <= S_RESET;
            ELSE
                STATE <= NEXT_STATE;
            END IF;
        END IF;
    END PROCESS;
    ------------------------------------------------------------------------------
    
    
    -- OUTPUT SIGNALS AND STATE TRANSITION PROCESS -------------------------------
    OutputAndTransition : PROCESS(STATE, ENABLE, LFSR)
    BEGIN
        -- DEFAULT ASSIGNMENTS  --------------------------------------------------             
        ENABLE_LFSR     <= '0';
        RESET_LFSR      <= '0';
        DONE            <= '0';
        NEXT_STATE        <= STATE;
        
        -- CASE EVALUATION -------------------------------------------------------
        CASE STATE IS
            WHEN S_RESET    =>  ENABLE_LFSR <= '0';
                                RESET_LFSR  <= '1';
                                NEXT_STATE <= S_IDLE;
            ----------------------------------------------------------------------
            WHEN S_IDLE     =>  IF (ENABLE = '1') THEN
                                    NEXT_STATE  <= S_ROUND;
                                END IF;
                                ENABLE_LFSR     <= '0';
                                RESET_LFSR      <= '0';
            ----------------------------------------------------------------------
            WHEN S_ROUND    =>  ENABLE_LFSR     <= '1';
                                RESET_LFSR      <= '0';
								NEXT_STATE  		<= S_ROUND2;

			----------------------------------------------------------------------
            WHEN S_ROUND2    => ENABLE_LFSR     <= '0';
                                RESET_LFSR      <= '0';
                                NEXT_STATE  	<= S_ROUND3;
                                IF (LFSR = X"C0") THEN
                                    NEXT_STATE  <= S_DONE;
                                END IF;
            ----------------------------------------------------------------------
            WHEN S_ROUND3    => ENABLE_LFSR     <= '0';
                                RESET_LFSR      <= '0';
                                NEXT_STATE  	<= S_ROUND;
            ----------------------------------------------------------------------
            WHEN S_DONE     =>  DONE            <= '1';
                                RESET_LFSR      <= '1';
                                NEXT_STATE  <= S_IDLE;
        END CASE;        
        --------------------------------------------------------------------------
        
    END PROCESS;
    ------------------------------------------------------------------------------

END FSM;
