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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;

 
ENTITY TB_Keccak IS
END TB_Keccak;
 
ARCHITECTURE behavior OF TB_Keccak IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Keccak1600
    PORT(
         CLK : IN  std_logic;
         RESET : IN  std_logic;
         ENABLE : IN  std_logic;
         DONE : OUT  std_logic;
         MESSAGE1 : IN  std_logic_vector(1087 downto 0);
         MESSAGE2 : IN  std_logic_vector(1087 downto 0);
         RESULT1 : OUT  std_logic_vector(1087 downto 0);
         RESULT2 : OUT  std_logic_vector(1087 downto 0)
        );
    END COMPONENT;
    
   -- Clock period definitions
   constant CLK_period : time := 10 ns;

   --Inputs
   signal CLK : std_logic := '0';
   signal RESET : std_logic := '0';
   signal ENABLE : std_logic := '0';
   signal MESSAGE1 : std_logic_vector(1087 downto 0) := (others => '0');
   signal MESSAGE2 : std_logic_vector(1087 downto 0) := (others => '0');
   signal MESSAGE3 : std_logic_vector(1087 downto 0) := (others => '0');

 	--Outputs
   signal DONE : std_logic;
   signal RESULT1 : std_logic_vector(1087 downto 0);
   signal RESULT2 : std_logic_vector(1087 downto 0);
   signal RESULT3 : std_logic_vector(1087 downto 0);
	
   signal out_32 : std_logic_vector(31 downto 0);
   
   signal MYOUTPUT, MYINPUT                       : std_logic_vector(1087 downto 0);
   signal Mask1 : std_logic_vector(1087 downto 0) := (others => '0');
	signal Mask2 : std_logic_vector(1087 downto 0) := (others => '0');
   
   signal TESTVECTOR : std_logic_vector(1087 downto 0);

 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Keccak1600 PORT MAP (
          CLK => CLK,
          RESET => RESET,
          ENABLE => ENABLE,
          DONE => DONE,
          MESSAGE1 => MESSAGE1,
          MESSAGE2 => MESSAGE2,
          RESULT1 => RESULT1,
          RESULT2 => RESULT2
   );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
 
 
 	MESSAGE1 <= MYINPUT xor Mask1;
	MESSAGE2 <= Mask1;

	
	MYOUTPUT <= RESULT1 xor RESULT2;
	out_32	<= MYOUTPUT(31 downto 0);

   -- Stimulus process
   stim_proc: process
		variable my_line : line;  -- type 'line' comes from textio   
   begin		
   

      MYINPUT    <= X"B771D5CEF5D1A41A93D15643D7181D2A2EF0A8E84D91812F20ED21F147BEF732BF3A60EF4067C3734B85BC8CD471780F10DC9E8291B58339A677B960218F71E793F2797AEA349406512829065D37BB55EA796FA4F56FD8896B49B2CD19B43215AD967C712B24E5032D065232E02C127409D2ED4146B9D75D763D52DB98D949D3B0FED6A8052FBB81";
      --MYINPUT    <= (others => '0');
      
      testvector <= X"BD6F5492582A7C1B116304DE28314DF9FFFE95B0DA11AF52FE9440A717A348591B310A14F855DAB869F67F61D1938FF091C9BB8935CC058C9D5FC865E0AEA8C562FFBC2A8AEE4746F966D51341C36865A6DA57D779E7A7A70EB45E8AFE8593F9B11A1054CC6FEBE71AEC5B47D47499171E80C7064DFE1A9A804D494EDD92FCDC71256BF5FE7ECA00";

      RESET       <= '1';
         WAIT FOR 100 NS;
      RESET       <= '0';

      ENABLE      <= '1';
         WAIT UNTIL (DONE = '1');
      ENABLE      <= '0';
      
      WAIT FOR 10 NS;
      
      
      
		if (MYOUTPUT = testvector) then
			report "---------- Passed ----------";
         write(my_line, string'("Output = "));
			hwrite(my_line, MYOUTPUT); 
			writeline(output, my_line);
		else
			report "---------- Failed ----------";
			write(my_line, string'("Output = "));
			hwrite(my_line, MYOUTPUT); 
			writeline(output, my_line);
         
         write(my_line, string'("Testve = "));
			hwrite(my_line, TESTVECTOR); 
			writeline(output, my_line);
      end if;         

      wait;
   end process;

END;
