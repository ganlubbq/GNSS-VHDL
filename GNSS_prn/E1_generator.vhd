--------------------------------------------------------------------------------------
-- E1B and E1C codes generator (1 bit outputs). They are memory codes stored in ROMs.
--
-- Galileo: 27 satellites
-- PRN E1B, E1C: 4092 chips length.
-- Two ROMs of 110592 (4096 * 27) positions depth and 1 bit width are needed.
-- stuff with 4 "0" between codes.
--
--    SAT 1          SAT 2   
-- 0      4091    4096   8186 
-- +++++++++++0000+++++++++++0000 ... etc
--
--------------------------------------------------------------------------------------
-- **** INPUTS ****
-- sat --> Sat number: 
--			0 = PRN 1, 1 = PRN 2,...,26 = PRN 27
-- enable --> freeze
--
-- **** OUTPUTS  ****
-- E1B, E1C  --> PRN signals
-- valid --> PRNs valid
-- epoch --> PRNs repeat
-- sat_changed --> Flag to indicated a new satellite update
--------------------------------------------------------------------------------------
-- Diary:	09/06/2015	Start 
--				15/06/2016	Version 1.0	Dani
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

entity E1_generator is
	Port (clk : in STD_LOGIC;
			rst	: in STD_LOGIC;		-- signal to start	
			E1B : out STD_LOGIC;			-- 1 bit output
			E1C : out STD_LOGIC;			-- 1 bit output
			ENABLE : in STD_LOGIC;		-- enable high
			valid_out : out std_logic;
			epoch : out STD_LOGIC;
			SAT : in STD_LOGIC_VECTOR(5-1 downto 0); -- 27 Galileo
			SAT_change : out STD_LOGIC); 	-- Satellite changed flag
end E1_generator;

architecture Behavioral of E1_generator is

	signal E1B_out : std_logic_vector(0 downto 0);
	signal E1C_out : std_logic_vector(0 downto 0);

	signal valid : STD_LOGIC;

	signal read_ROM, read_ROM_d , read_ROM_d2 : std_logic;
	signal addr : STD_LOGIC_VECTOR(17-1 downto 0); --27*4096 --> 17b
	signal cont : STD_LOGIC_VECTOR(12-1 downto 0);  --4092

	signal cont_epoch	: STD_LOGIC_VECTOR (12-1 downto 0);	-- PRN period of 4092 clocks
	
	signal SAT_int, SAT_int_old: integer range 0 to 126976; --31 *4096
	-----------------------------------------------------------------------------------	
	------- DECLARATIONS --------------------------------------------------------------	
	COMPONENT PRN_E1B
		PORT (clka : IN STD_LOGIC;
			addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
			douta : OUT STD_LOGIC_VECTOR(0 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT PRN_E1C
		PORT (clka : IN STD_LOGIC;
			addra : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
			douta : OUT STD_LOGIC_VECTOR(0 DOWNTO 0));
	END COMPONENT;	
	-----------------------------------------------------------------------------------	
	begin
		------- INSTANTATIONS ----------------------------------------------------------
		PRN_E1B_inst : PRN_E1B
			PORT MAP (clka => clk,
				addra => addr,
				douta => E1B_out);	
				
		PRN_E1C_inst : PRN_E1C
			PORT MAP (clka => clk,
				addra => addr,
				douta => E1C_out);
				
		valid_out <= valid;					
		--------------------------------------------------------------------------------
		------- PROCESSES --------------------------------------------------------------					
		proc: process(clk)
			begin		
				if (rising_edge(clk)) then
					if (rst = '1') then
						read_ROM <= '0';			
						read_ROM_d  <= '0';	
						read_ROM_d2  <= '0';							
						addr <= (others =>'0');
						cont <= "111111111011";	--4092-1
						E1B <= '0';
						E1C <= '0';
						valid <='0';	
						epoch <= '0';	
						cont_epoch <= "111111111011";	--4092-1
						
						SAT_int <= 0;
						SAT_int_old <= 0;

						SAT_change <= '0';
					else 
					
						if (ENABLE = '0') then -- Freeze everything
							read_ROM <= '0';			
							read_ROM_d  <= '0';	
							read_ROM_d2  <= '0';	
							valid <= '0';
						else	

							SAT_int <= to_integer(unsigned(SAT))*4096;
							SAT_int_old <= SAT_int;
							
							if ((SAT_int_old /= SAT_int) or (read_ROM='0'))  then -- Restart
								valid <= '0';
								read_ROM	<= '1';
								epoch <= '0';
								
								cont <= "111111111011";	
								cont_epoch <= "111111111011";	
								
								read_ROM_d  <= '0';	
								read_ROM_d2  <= '0';	
								valid <= '0';		
								SAT_change <= '0';
							else				

								read_ROM_d <= read_ROM;
								read_ROM_d2 <= read_ROM_d;
								valid <= read_ROM_d2;								
							
								-- Report SAT change
								if (read_ROM_d2 ='1') and (valid='0') then
									SAT_change <= '1';
								else
									SAT_change <= '0';
								end if;							
							
								-- Create PRNs
								E1B <= E1B_out(0);
								E1C <= E1C_out(0);

								-- Counter epoch
								if read_ROM_d2 = '1' then
									if cont_epoch = 4092-1 then
										cont_epoch <= (others => '0');
										epoch<= '1';
									else
										cont_epoch <= cont_epoch+1;							
										epoch<= '0';
									end if;
								end if;		
								
								-- Read ROMs
								if cont = 4092-1 then
									addr <= std_logic_vector(to_unsigned(SAT_int, addr'length));							
									cont <= (others =>'0');
								else
									addr <= addr+1;
									cont <= cont+1;
								end if;									
							end if; -- Restart
						end if; --enable
					end if; --reset
				end if; --clock	
		end process proc;	
end Behavioral;