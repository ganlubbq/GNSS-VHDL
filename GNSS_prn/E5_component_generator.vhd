--------------------------------------------------------------------------------------
-- E5 components generator (E5aI, E5aQ, E5bI, E5bQ)
--
-- All vectors are reversed as they appear in the ICD document (Galileo OS SIS ICD).
-- The PRN is generated with two LSFR. Both LSFR have fixed taps and phases for all 
-- satellites. One LSFR has fixed seed (all ones) for all satellites while the other 
-- LSFR has a different seed for each satellite.
--
-- Base register: 16383 lenght --> truncated at 10230
-- Second register: 16383 lenght --> truncated at 10230
-- PRN: 10230 lenght.
--------------------------------------------------------------------------------------
-- **** INPUTS ****
-- seed_2, tap_1, tap_2 --> Seeds and taps for the registers.
-- enable --> freeze
--
-- **** OUTPUTS  ****
-- prn  --> PRN signal
-- valid --> PRN valid
-- epoch --> PRN repeat
--------------------------------------------------------------------------------------
-- Diary:	03/06/2015	Start 
--				09/06/2016	Version 1.0	Dani
--------------------------------------------------------------------------------------
-- Author: Daniel Pascual (daniel.pascual@tsc.upc.edu)
--
-- This work is licensed under the Creative Commons Attribution 4.0 International 
-- License. To view a copy of this license, visit 
-- http://creativecommons.org/licenses/by/4.0/.
--------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity E5_component_generator is
	GENERIC(WIDTH : integer := 14);
	Port (clk : in STD_LOGIC;
			rst	: in STD_LOGIC;										-- signal to start	
			seed_2 : in STD_LOGIC_VECTOR (WIDTH-1 downto 0);	-- initial state of second register
			tap_1 : in STD_LOGIC_VECTOR (WIDTH-1 downto 0);		-- taps for base register
			tap_2 : in STD_LOGIC_VECTOR (WIDTH-1 downto 0);		-- taps for second register			
			PRN : out STD_LOGIC;											-- 1 bit output
			ENABLE : in STD_LOGIC;										-- enable to match the chip frequency
			valid : out STD_LOGIC);
end E5_component_generator;

architecture Behavioral of E5_component_generator is

	signal base_out :STD_LOGIC;
	signal second_out :STD_LOGIC;
	signal LSFR_valid :STD_LOGIC;	-- just one needed because they are sync
	-----------------------------------------------------------------------------------	
	begin
		------- INSTANTATIONS ----------------------------------------------------------
		Base : entity work.LFSR_generator(Behavioral)
			generic map(WIDTH => 14,
				WIDTH_CMP => 14)
			port map(clk => clk,
				rst => rst,
				seed	=> "11111111111111",			-- same for all PRNs and componet
				tap => tap_1,							-- same for all PRNs
				RESET => "00000000000000",			-- no reset
				output => "10000000000000",		-- just last one
				SEQ => base_out,
				count_cmp => "10011111110101", 	-- 10230-1
				ENABLE => ENABLE,
				valid => LSFR_valid);				
				
		Second : entity work.LFSR_generator(Behavioral)
			generic map(WIDTH => 14,
				WIDTH_CMP => 14)
			port map(clk => clk,
				rst => rst,
				seed	=> seed_2,						-- different for each PRN
				tap => tap_2,							-- same for all PRNs
				RESET => "00000000000000",			-- no reset
				output => "10000000000000",		-- just last one
				SEQ => second_out,
				count_cmp => "10011111110101", 	-- 10230-1
				ENABLE => ENABLE,
				valid => open);						-- both LSFR are sync
		--------------------------------------------------------------------------------
		------- PROCESSES --------------------------------------------------------------	
		proc: process(clk)
			begin
				if (rising_edge(clk)) then
					if (rst = '1') then
						PRN <= '0';
						valid <='0';
					else	
						-- Create PRN
						valid <= LSFR_valid;						
						PRN <= base_out xor second_out;
					end if; --rst
				end if; --clk
		end process proc;	
end Behavioral;