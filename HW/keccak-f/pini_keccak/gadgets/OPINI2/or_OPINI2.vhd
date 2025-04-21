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

entity or_OPINI2 is
	generic (
		security_order : integer := 2; -- d
      pipeline			: integer := 1); -- 0/1
	port (
		a 		: in  std_logic_vector(security_order downto 0);
		b 		: in  std_logic_vector(security_order downto 0);
		r		: in  std_logic_vector((((((security_order + 1) * security_order) / 2) + (security_order)) - 1) downto 0); -- (d+1)*d /2 + d
		clk	: in  std_logic;
		c 		: out std_logic_vector(security_order downto 0));
end or_OPINI2;

architecture Behavioral of or_OPINI2 is

	component reg is
	PORT ( 
		clk 	: IN  STD_LOGIC;
		d 		: IN  STD_LOGIC;
		q 		: OUT  STD_LOGIC);
	end component;
	
	
	component or_HPC2 is
        generic (
          security_order : integer := 2; -- d
          pipeline            : integer := 1); -- 0/1
        port (
            a         : in  std_logic_vector(security_order downto 0);
            b         : in  std_logic_vector(security_order downto 0);
            r        : in  std_logic_vector(((((security_order + 1) * security_order) / 2) - 1) downto 0); -- (d+1)*d /2
            clk    : in  std_logic;
            c         : out std_logic_vector(security_order downto 0));
    end component;
	
	signal s_sum : std_logic_vector(security_order downto 0) := (others => '0');
	signal s_regIn, s_regOut, s_regPipe, c_regIn, c_regOut: std_logic_vector(security_order downto 0) := (others => '0');
	signal d: std_logic_vector(security_order downto 0) := (others => '0');
	signal r_hpc: std_logic_vector(((((security_order + 1) * security_order) / 2) - 1) downto 0) := (others => '0');
	
	
	
	
begin 
    
    r_hpc <= r((((((security_order + 1) * security_order) / 2) + (security_order)) - 1) downto (security_order));
    s_regIn(security_order - 1 downto 0) <= r((security_order - 1) downto 0);
    
    hpc2: or_HPC2 generic map(security_order => security_order, pipeline => pipeline) port map(a => a, b => b, r=>r_hpc, clk=> clk, c=>d);
    
   -- generate sum s_(d-1)
   gen_i : for I in 0 to (security_order-1) generate
        s_sum(I+1) <= s_sum(I) xor s_regIn(I);
   end generate gen_i;

    s_regIn(security_order) <= s_sum(security_order);
    
    gen_i_1 : for I in 0 to security_order generate
    
         s_reg : reg port map(clk => clk, d => s_regIn(I), q => s_regOut(I));
         -- not pipeline
         s_regPipe(I) <= s_regOut(I);
         
         c_regIn(I) <= d(I) xor s_regPipe(I);
         c_reg : reg port map(clk => clk, d => c_regIn(I), q => c_regOut(I));
         c(I) <= c_regOut(I);
    end generate gen_i_1;
    

end Behavioral;
