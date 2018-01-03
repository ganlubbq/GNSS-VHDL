--------------------------------------------------------------------------------------
-- E5aI, E5aQ, E5bI, E5bQ code generator (1 bit outputs)
--
-- All vectors are reversed as they appear in the ICD document (Galileo OS SIS ICD).
-- Each of the four components is generated with two LSFR (so 8 LSFRs are needed).
-- Both LSFR have fixed taps and phases for all satellites, but different for each
-- component. One LSFR has fixed seed (all ones) for all satellites and components,
-- while the other LSFR has a different seed for each satellite and component.
-- 
-- PRN aI, aQ, bI, bQ: 10230 lenght.
--------------------------------------------------------------------------------------
-- **** INPUTS ****
-- sat --> Sat number: 
--			0 = PRN 1, 1 = PRN 2,...,26 = PRN 27
-- enable --> freeze
--
-- **** OUTPUTS  ****
-- E5aI, E5aQ, E5bI, E5bQ  --> PRN signals
-- valid --> PRNs valid
-- epoch --> PRNs repeat
-- sat_changed --> Flag to indicated a new satellite update
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
use IEEE.std_logic_signed.all;-- addition
use ieee.numeric_std.all;		-- to_signed, etc
use IEEE.math_real.all; 		-- maths

entity E5_generator is
	Port (clk : in STD_LOGIC;
			rst	: in STD_LOGIC;		-- signal to start	
			E5aI : out STD_LOGIC;		-- 1 bit output
			E5aQ : out STD_LOGIC;		-- 1 bit output
			E5bI : out STD_LOGIC;		-- 1 bit output
			E5bQ : out STD_LOGIC;		-- 1 bit output			
			ENABLE : in STD_LOGIC;		-- enable high
			valid_out : out std_logic;
			epoch : out STD_LOGIC;
			SAT : in STD_LOGIC_VECTOR(5-1 downto 0); -- 27 Galileo
			SAT_change : out STD_LOGIC); 	-- Satellite changed flag
end E5_generator;

architecture Behavioral of E5_generator is

	-- Registers
	signal E5aI_seed_2	: STD_LOGIC_VECTOR (13 downto 0);	-- second register seeds
	signal E5aQ_seed_2	: STD_LOGIC_VECTOR (13 downto 0);		
	signal E5bI_seed_2	: STD_LOGIC_VECTOR (13 downto 0);		
	signal E5bQ_seed_2	: STD_LOGIC_VECTOR (13 downto 0);	
	signal E5aI_out : STD_LOGIC;
	signal E5aQ_out : STD_LOGIC;
	signal E5bI_out : STD_LOGIC;
	signal E5bQ_out : STD_LOGIC;	
	signal PRN_valid : STD_LOGIC;	-- just one needed because they are sync
	
	signal valid : STD_LOGIC;
	
	signal ENABLE_LSFR, ENABLE_LSFR_d : STD_LOGIC;
	
	signal reset_LSFR, rst_LSFR : STD_LOGIC;	
	signal rst_LSFR_d : STD_LOGIC;
		
	signal cont_epoch	: STD_LOGIC_VECTOR (14-1 downto 0);	-- PRN period of 10230 clocks
	
	signal SAT_int, SAT_int_old : integer range 0 to 31;	-- 27 Galileo
	-----------------------------------------------------------------------------------	
	begin
		------- INSTANTATIONS ----------------------------------------------------------
		E5aI_gen : entity work.E5_component_generator(Behavioral)
			generic map(WIDTH => 14)
			port map(clk => clk,
				rst => reset_LSFR,
				seed_2	=> E5aI_seed_2,
				tap_1 => "10000010100001",	-- same for all PRNs	
				tap_2 => "10100011011000",	-- same for all PRNs
				PRN => E5aI_out,
				ENABLE => ENABLE_LSFR_d,
				valid => PRN_valid);
				
		E5aQ_gen : entity work.E5_component_generator(Behavioral)
			generic map(WIDTH => 14)
			port map(clk => clk,
				rst => reset_LSFR,
				seed_2	=> E5aQ_seed_2,
				tap_1 => "10000010100001",	-- same for all PRNs		
				tap_2 => "10100011011000",	-- same for all PRNs	
				PRN => E5aQ_out,
				ENABLE => ENABLE_LSFR_d,					
				valid => open);				-- all are sync

		E5bI_gen : entity work.E5_component_generator(Behavioral)
			generic map(WIDTH => 14)
			port map(clk => clk,
				rst => reset_LSFR,
				seed_2	=> E5bI_seed_2,
				tap_1 => "11010000001000",	-- same for all PRNs	
				tap_2 => "10100110010010",	-- same for all PRNs	
				PRN => E5bI_out,
				ENABLE => ENABLE_LSFR_d,
				valid => open);				-- all are sync			

		E5bQ_gen : entity work.E5_component_generator(Behavioral)
			generic map(WIDTH => 14)
			port map(clk => clk,
				rst => reset_LSFR,
				seed_2	=> E5bQ_seed_2,
				tap_1 => "11010000001000",	-- same for all PRNs
				tap_2 => "10001100110001",	-- same for all PRNs			
				PRN => E5bQ_out,
				ENABLE => ENABLE_LSFR_d,
				valid => open);				-- all are sync		
				
		reset_LSFR <= rst or rst_LSFR_d;
		valid_out <= valid;			
		--------------------------------------------------------------------------------
		------- PROCESSES --------------------------------------------------------------					
		proc: process(clk)
			begin		
				if (rising_edge(clk)) then
					if (rst = '1') then
						E5aI_seed_2	<= (others =>'0');
						E5aQ_seed_2	<= (others =>'0');
						E5bI_seed_2	<= (others =>'0');
						E5bQ_seed_2	<= (others =>'0');					
						E5aI <= '0';
						E5aQ <= '0';
						E5bI <= '0';
						E5bQ <= '0';
						valid <='0';	
						epoch <= '0';	
						cont_epoch <= "10011111110101";	--10230-1

						SAT_int <= 0;
						SAT_int_old <= 0;
						rst_LSFR <= '1';
						rst_LSFR_d  <= '1';
						
						ENABLE_LSFR <= '0';
						ENABLE_LSFR_d <= '0';					
						
						SAT_change <= '0';
					else 
						  
						rst_LSFR_d <= rst_LSFR;
						ENABLE_LSFR_d <= ENABLE_LSFR;
						  
						if (ENABLE = '0') then -- Freeze everything
							valid <= '0';
							ENABLE_LSFR <= '0';
						else		

							SAT_int <= to_integer(unsigned(SAT)); 
							SAT_int_old <= SAT_int;	

							if ((SAT_int_old /= SAT_int) or (ENABLE_LSFR='0'))  then -- Restart LSFR
								rst_LSFR<='1';
								valid <= '0';
								epoch <= '0';
								cont_epoch <= "10011111110101";
								ENABLE_LSFR <= '1';							
								SAT_change <= '0';
							else
								rst_LSFR<='0';							

								-- Report SAT change
								if (PRN_valid ='1') and (valid='0') then
									SAT_change <= '1';
								else
									SAT_change <= '0';
								end if;
								
								-- Create PRNs
								valid <= PRN_valid;												
								E5aI <= E5aI_out;
								E5aQ <= E5aQ_out;
								E5bI <= E5bI_out;
								E5bQ <= E5bQ_out;	

								-- LSFR_valid epoch
								if PRN_valid = '1' then
									if cont_epoch = 10230-1 then
										cont_epoch <= (others => '0');
										epoch<= '1';
									else
										cont_epoch <= cont_epoch+1;							
										epoch<= '0';
									end if;
								end if;						
							end if; -- Restart/enable LSFR										
						
							-- Second register seeds
							CASE SAT_int IS
								WHEN 0 => 
									E5aI_seed_2	<= "11000011000101"; 
									E5aQ_seed_2	<= "10101110101010";
									E5bI_seed_2	<= "00111010010000";
									E5bQ_seed_2	<= "00011011011001";
								WHEN 1 => 
									E5aI_seed_2	<= "01100010011100";
									E5aQ_seed_2	<= "00101001100010";
									E5bI_seed_2	<= "10110000100111";
									E5bQ_seed_2	<= "00110001100011";						
								WHEN 2 => 
									E5aI_seed_2	<= "10111010001011";
									E5aQ_seed_2	<= "10100111010011";
									E5bI_seed_2	<= "00000010101010";
									E5bQ_seed_2	<= "10101011010010";						
								WHEN 3 => 
									E5aI_seed_2	<= "10000101111111";
									E5aQ_seed_2	<= "11001111101001";
									E5bI_seed_2	<= "01111001110110";
									E5bQ_seed_2	<= "10011011111001";						
								WHEN 4 => 
									E5aI_seed_2	<= "10011011001010";
									E5aQ_seed_2	<= "10111011110110";
									E5bI_seed_2	<= "01100001110001";
									E5bQ_seed_2	<= "00000100001011";						
								WHEN 5 => 
									E5aI_seed_2	<= "11011100110011";
									E5aQ_seed_2	<= "10100110110000";
									E5bI_seed_2	<= "00010101100000";
									E5bQ_seed_2	<= "11110010011101";						
								WHEN 6 => 
									E5aI_seed_2	<= "01101110001100";
									E5aQ_seed_2	<= "11011110101101";
									E5bI_seed_2	<= "00001101011111";
									E5bQ_seed_2	<= "01111111101000";						
								WHEN 7 => 
									E5aI_seed_2	<= "01010101011111";
									E5aQ_seed_2	<= "10111100101000";
									E5bI_seed_2	<= "10110000010011";
									E5bQ_seed_2	<= "00100111100101";						
								WHEN 8 => 
									E5aI_seed_2	<= "00001101010111";
									E5aQ_seed_2	<= "00111110010110";
									E5bI_seed_2	<= "00001111010101";
									E5bQ_seed_2	<= "01011000000101";						
								WHEN 9 => 
									E5aI_seed_2	<= "11000010011110";
									E5aQ_seed_2	<= "00001111000101";
									E5bI_seed_2	<= "10000110011111";
									E5bQ_seed_2	<= "11111001100000";						
								WHEN 10 => 
									E5aI_seed_2	<= "10111011100100";
									E5aQ_seed_2	<= "01010111001111";
									E5bI_seed_2	<= "00010011110100";
									E5bQ_seed_2	<= "11000001101101";						
								WHEN 11 =>
									E5aI_seed_2	<= "00111010111010";
									E5aQ_seed_2	<= "11010001010010";
									E5bI_seed_2	<= "10111111011001";
									E5bQ_seed_2	<= "10000010011111";						
								WHEN 12 => 
									E5aI_seed_2	<= "11110011111111";
									E5aQ_seed_2	<= "01110000111101";
									E5bI_seed_2	<= "11000110100000";
									E5bQ_seed_2	<= "00011100110001";						
								WHEN 13 => 
									E5aI_seed_2	<= "01111000100110";
									E5aQ_seed_2	<= "01110110100100";
									E5bI_seed_2	<= "11100001111100";
									E5bQ_seed_2	<= "11001110110010";						
								WHEN 14 => 
									E5aI_seed_2	<= "00110100011100";
									E5aQ_seed_2	<= "11111101101110";
									E5bI_seed_2	<= "00110100110100";
									E5bQ_seed_2	<= "10111001100110";						
								WHEN 15 => 
									E5aI_seed_2	<= "01101100000101";
									E5aQ_seed_2	<= "00010100111111";
									E5bI_seed_2	<= "00111110111110";
									E5bQ_seed_2	<= "00101101100111";						
								WHEN 16 => 
									E5aI_seed_2	<= "10100010101010";
									E5aQ_seed_2	<= "00010010110101";
									E5bI_seed_2	<= "11010010011001";
									E5bQ_seed_2	<= "00010100101110";						
								WHEN 17 => 
									E5aI_seed_2	<= "01001110011001";
									E5aQ_seed_2	<= "00110100011000";
									E5bI_seed_2	<= "01000011101011";
									E5bQ_seed_2	<= "11000000001011";						
								WHEN 18 => 
									E5aI_seed_2	<= "10100111111110";
									E5aQ_seed_2	<= "10101000100110";
									E5bI_seed_2	<= "00000111101101";
									E5bQ_seed_2	<= "00000011010010";						
								WHEN 19 => 
									E5aI_seed_2	<= "00000110011000";
									E5aQ_seed_2	<= "01010111011101";
									E5bI_seed_2	<= "10110000111111";
									E5bQ_seed_2	<= "01000111110001";						
								WHEN 20 => 
									E5aI_seed_2	<= "01001101110000";
									E5aQ_seed_2	<= "00100010110010";
									E5bI_seed_2	<= "01001110100100";
									E5bQ_seed_2	<= "10110111110111";						
								WHEN 21 => 
									E5aI_seed_2	<= "01111010111010";
									E5aQ_seed_2	<= "01001010011000";
									E5bI_seed_2	<= "01001101011111";
									E5bQ_seed_2	<= "11110000000100";						
								WHEN 22 => 
									E5aI_seed_2	<= "10111100100101";
									E5aQ_seed_2	<= "00000000011111";
									E5bI_seed_2	<= "11101001001101";
									E5bQ_seed_2	<= "11000111001011";						
								WHEN 23 => 
									E5aI_seed_2	<= "11001111000010";
									E5aQ_seed_2	<= "00110001011111";
									E5bI_seed_2	<= "10000100101010";
									E5bQ_seed_2	<= "00111110110010";						
								WHEN 24 => 
									E5aI_seed_2	<= "01011000001010";
									E5aQ_seed_2	<= "00100011001010";
									E5bI_seed_2	<= "11100110100101";
									E5bQ_seed_2	<= "10001110001000";						
								WHEN 25 => 
									E5aI_seed_2	<= "01100100000001";
									E5aQ_seed_2	<= "10000110000110";
									E5bI_seed_2	<= "10101110110100";
									E5bQ_seed_2	<= "10000001011100";						
								WHEN 26 => 
									E5aI_seed_2	<= "11100111010111";
									E5aQ_seed_2	<= "01001001110010";
									E5bI_seed_2	<= "10001100000011";
									E5bQ_seed_2	<= "01001010110010";
								WHEN OTHERS =>  
									E5aI_seed_2	<= (others =>'0');
									E5aQ_seed_2	<= (others =>'0');
									E5bI_seed_2	<= (others =>'0');
									E5bQ_seed_2	<= (others =>'0');
							END CASE;	
						end if; --enable
					end if; --reset
				end if; --clock	
		end process proc;	
end Behavioral;