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

entity nand_HPC2 is
	generic (
		security_order : integer := 2; -- d
      pipeline			: integer := 1); -- 0/1
	port (
		a 		: in  std_logic_vector(security_order downto 0);
		b 		: in  std_logic_vector(security_order downto 0);
		r		: in  std_logic_vector(((((security_order + 1) * security_order) / 2) - 1) downto 0); -- (d+1)*d /2
		clk	: in  std_logic;
		c 		: out std_logic_vector(security_order downto 0));
end nand_HPC2;

architecture Behavioral of nand_HPC2 is

	component reg is
	PORT ( 
		clk 	: IN  STD_LOGIC;
		d 		: IN  STD_LOGIC;
		q 		: OUT  STD_LOGIC);
	end component;

	type matrix 		is array(security_order downto 0)  of std_logic_vector(security_order downto 0);
	type sum_matrix 	is array(security_order downto 0)  of std_logic_vector((security_order+1) downto 0);

	signal r_m, s_in, s_out, p_0_in, p_1_in, p_0_out, p_1_out, u_in, z : matrix := (others => (others => '0'));
	signal p_0_pipe_out : matrix := (others => (others => '0'));
	signal mul,a_reg, mul_s1_out, mul_s2_out : std_logic_vector(security_order downto 0) := (others => '0');
	signal z_sum : sum_matrix := (others => (others => '0'));

begin 

	-- ordering fresh masks

	process(r)
	variable C : natural := 0;
	begin
		C := 0;
		gen_r_m_i : for I in 0 to security_order loop
			 gen_r_m_j : for J in (I + 1) to security_order loop
				  r_m(I)(J) <= r(C);
				  r_m(J)(I) <= r(C);
				  C := C + 1;
			 end loop;
		end loop;
	end process;

	gen_i : for I in 0 to security_order generate
		--signal connection
		mul(I) <= a(I) and b(I);
		Z(I)(I) <= mul_s2_out(I);
		
		--pipeline
		mul_pipe_s1 : reg port map (clk => clk, d => mul(I), q => mul_s1_out(I));
		mul_pipe_s2 : reg port map (clk => clk, d => mul_s1_out(I), q => mul_s2_out(I));
		a_i : reg port map(clk => clk, d => a(I), q => a_reg(I));

		gen_j : for J in 0 to security_order generate
			gen_i_neq_j : if (I /= J) generate
				-- signal connection
				s_in(I)(J) <= b(J) xor r_m(I)(J);
				p_0_in(I)(J) <= (not a(I)) and r_m(I)(J);
				p_1_in(I)(J) <= s_out(I)(J) and a_reg(I);
				z(I)(J) <= p_0_pipe_out(I)(J) xor p_1_out(I)(J);

				-- registers
				s_reg: reg port map (clk => clk, d => s_in(I)(J), q => s_out(I)(J));
				p_0_reg: reg port map (clk => clk, d => p_0_in(I)(J), q => p_0_out(I)(J));
				p_1_reg: reg port map (clk => clk, d => p_1_in(I)(J), q => p_1_out(I)(J));

				-- pipeline
				p_0_pipe : reg port map (clk => clk, d => p_0_out(I)(J), q => p_0_pipe_out (I)(J));

			end generate gen_i_neq_j;
		end generate gen_j;
	end generate gen_i;

	-- pre-output

	gen_po_i : for I in 0 to security_order generate
		gen_po_j : for J in 0 to security_order generate
			z_sum(I)(J+1) <= z_sum(I)(J) xor z(I)(J); 
		end generate;
	end generate;

	-- output

	c(0) <= not z_sum(0)(security_order + 1);

	gen_o_i : for I in 1 to security_order generate
		c(I) <= z_sum(I)(security_order + 1);
	end generate;

end Behavioral;
