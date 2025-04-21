-----------------------------------------------------------------
-- COMPANY : Ruhr University Bochum
-- AUTHOR  : David Knichel david.knichel@rub.de and Amir Moradi amir.moradi@rub.de 
-- DOCUMENT: [Low-Latency Hardware Private Circuits] https://eprint.iacr.org/2022/507
-- -----------------------------------------------------------------
--
-- Copyright c 2022, David Knichel and  Amir Moradi
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ClockGatingController is
	generic (
		NumberOfStages : integer := 5);
	port (
		clk      : in  std_logic;
		rst      : in  std_logic;
		GatedClk : out std_logic;
		Synch    : out std_logic);
end ClockGatingController;

architecture Behavioral of ClockGatingController is
	
	signal ShiftRegister : std_logic_vector(1 to NumberOfStages);
	signal EnableClk     : std_logic;
	signal LatchedEnable : std_logic := '0';

begin 

	reg_gen: PROCESS(clk, rst)
	BEGIN
		IF RISING_EDGE(clk) THEN
			IF (rst = '1') THEN
				ShiftRegister(1)                   <= '1';
				ShiftRegister(2 to NumberOfStages) <= (others => '0');
			ELSE
				ShiftRegister <= ShiftRegister(NumberOfStages) & ShiftRegister(1 to NumberOfStages-1);
			END IF;
		END IF;
	END PROCESS;		

	EnableClk <= ShiftRegister(NumberOfStages) OR rst;
	
	PROCESS (clk, EnableClk)
	BEGIN
		IF (clk = '0') THEN
			LatchedEnable <= EnableClk;
			Synch         <= ShiftRegister(NumberOfStages);
		END IF;
	END PROCESS;		

	GatedClk <= clk AND LatchedEnable;

end Behavioral;
