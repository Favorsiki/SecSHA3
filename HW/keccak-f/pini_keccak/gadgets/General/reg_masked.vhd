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

entity reg_masked is
	generic (
		low_latency   : integer := 1;  -- dummy
		security_order: integer := 1;  -- dummy
		pipeline      : integer := 1); -- dummy
	port (
		clk	: in  std_logic;
		D 	: in  std_logic_vector(security_order downto 0);
		Q 	: out std_logic_vector(security_order downto 0));
end reg_masked;

architecture Behavioral of reg_masked is

	component reg is
	PORT ( 
		clk 	: IN  STD_LOGIC;
		D 	: IN  STD_LOGIC;
		Q 	: OUT STD_LOGIC);
	end component;

begin 

	gen_o : for I in 0 to security_order generate
		s_reg: reg port map (clk => clk, D => D(I), Q => Q(I));
	end generate gen_o;

end Behavioral;
