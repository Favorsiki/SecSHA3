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
ENTITY theta is
    PORT ( X : IN  STD_LOGIC_VECTOR(1599 DOWNTO 0);
           Y : OUT STD_LOGIC_VECTOR(1599 DOWNTO 0));
END theta;



-- ARCHITECTURE : DATAFLOW
----------------------------------------------------------------------------------
ARCHITECTURE Dataflow OF theta IS

    -- SIGNALS -------------------------------------------------------------------
    SIGNAL SUMS : STD_LOGIC_VECTOR(319 DOWNTO 0);

BEGIN

    SUMS <= X(1599 DOWNTO 1280) XOR X(1279 DOWNTO 960) XOR X(959 DOWNTO 640) XOR X(639 DOWNTO 320) XOR X(319 DOWNTO 0);
    
    GEN : FOR I IN 0 TO 4 GENERATE
        Y((I * 320) +  63 DOWNTO (I * 320) +   0) <= X((I * 320) +  63 DOWNTO (I * 320) +   0) XOR SUMS(319 DOWNTO 256) XOR (SUMS(126 DOWNTO  64) & SUMS(127));
        Y((I * 320) + 127 DOWNTO (I * 320) +  64) <= X((I * 320) + 127 DOWNTO (I * 320) +  64) XOR SUMS( 63 DOWNTO   0) XOR (SUMS(190 DOWNTO 128) & SUMS(191));
        Y((I * 320) + 191 DOWNTO (I * 320) + 128) <= X((I * 320) + 191 DOWNTO (I * 320) + 128) XOR SUMS(127 DOWNTO  64) XOR (SUMS(254 DOWNTO 192) & SUMS(255));
        Y((I * 320) + 255 DOWNTO (I * 320) + 192) <= X((I * 320) + 255 DOWNTO (I * 320) + 192) XOR SUMS(191 DOWNTO 128) XOR (SUMS(318 DOWNTO 256) & SUMS(319));
        Y((I * 320) + 319 DOWNTO (I * 320) + 256) <= X((I * 320) + 319 DOWNTO (I * 320) + 256) XOR SUMS(255 DOWNTO 192) XOR (SUMS( 62 DOWNTO   0) & SUMS( 63));
    END GENERATE;

END Dataflow;
