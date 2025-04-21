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
ENTITY pi is
    PORT ( X : IN  STD_LOGIC_VECTOR(1599 DOWNTO 0);
           Y : OUT STD_LOGIC_VECTOR(1599 DOWNTO 0));
END pi;



-- ARCHITECTURE : DATAFLOW
----------------------------------------------------------------------------------
ARCHITECTURE Dataflow OF pi IS

BEGIN

    -- Y = 0
    Y(  63 DOWNTO    0) <= X(  63 DOWNTO    0);
    Y( 127 DOWNTO   64) <= X( 447 DOWNTO  384);
    Y( 191 DOWNTO  128) <= X( 831 DOWNTO  768);
    Y( 255 DOWNTO  192) <= X(1215 DOWNTO 1152);
    Y( 319 DOWNTO  256) <= X(1599 DOWNTO 1536);
    
    -- Y = 1
    Y( 383 DOWNTO  320) <= X( 255 DOWNTO  192);
    Y( 447 DOWNTO  384) <= X( 639 DOWNTO  576);
    Y( 511 DOWNTO  448) <= X( 703 DOWNTO  640);
    Y( 575 DOWNTO  512) <= X(1087 DOWNTO 1024);
    Y( 639 DOWNTO  576) <= X(1471 DOWNTO 1408);

    -- Y = 2    
    Y( 703 DOWNTO  640) <= X( 127 DOWNTO   64);
    Y( 767 DOWNTO  704) <= X( 511 DOWNTO  448);
    Y( 831 DOWNTO  768) <= X( 895 DOWNTO  832);
    Y( 895 DOWNTO  832) <= X(1279 DOWNTO 1216);
    Y( 959 DOWNTO  896) <= X(1343 DOWNTO 1280);   

    -- Y = 3
    Y(1023 DOWNTO  960) <= X( 319 DOWNTO  256);
    Y(1087 DOWNTO 1024) <= X( 383 DOWNTO  320);
    Y(1151 DOWNTO 1088) <= X( 767 DOWNTO  704);
    Y(1215 DOWNTO 1152) <= X(1151 DOWNTO 1088);
    Y(1279 DOWNTO 1216) <= X(1535 DOWNTO 1472);   
 
    -- Y = 4   
    Y(1343 DOWNTO 1280) <= X( 191 DOWNTO  128);
    Y(1407 DOWNTO 1344) <= X( 575 DOWNTO  512);
    Y(1471 DOWNTO 1408) <= X( 959 DOWNTO  896);
    Y(1535 DOWNTO 1472) <= X(1023 DOWNTO  960);
    Y(1599 DOWNTO 1536) <= X(1407 DOWNTO 1344);   

END Dataflow;
