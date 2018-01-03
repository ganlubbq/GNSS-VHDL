--------------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------
-- Diary:	20/07/2016	Start 
--------------------------------------------------------------------------------------
-- Author: Daniel Pascual (daniel.pascual@tsc.upc.edu)
--
-- This work is licensed under the Creative Commons Attribution 4.0 International 
-- License. To view a copy of this license, visit 
-- http://creativecommons.org/licenses/by/4.0/.
--------------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.std_logic_signed.all; 	-- Additions

use ieee.std_logic_textio.all;   -- Write to file
use std.textio.all;
 
ENTITY E1OS_signal_generator_tb IS
END E1OS_signal_generator_tb;
 
ARCHITECTURE behavior OF E1OS_signal_generator_tb IS 
 
	COMPONENT E1OS_signal_generator
		Generic(Width : integer := 8;			-- Output width
				N : integer := 12);	
		PORT(clk : IN  std_logic;
			rst : IN  std_logic;
         PRN : IN  std_logic_vector(1 downto 0);
         E1OS : OUT  std_logic_vector(7 downto 0);
			valid : out std_logic;
			enable : in std_logic;
			strobe_in : in std_logic;
			strobe_out : out std_logic;
			addr_new : in std_logic);				
    END COMPONENT;
    
	-- Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '1';
	signal PRN : std_logic_vector(1 downto 0);
	signal enable : std_logic := '1';
	signal strobe_in : std_logic := '0';
	signal addr_new : std_logic := '0';

 	-- Outputs
   signal E1OS : std_logic_vector(7 downto 0);
	signal valid : std_logic;
	signal strobe_out : std_logic;
	
	-- Aux
	signal strobe_boc_aux : std_logic := '1';
	signal strobe_prn_aux : std_logic := '1';
	signal strobe_prn : std_logic := '0';	

   -- Clock period definitions
   constant clk_period : time := 5 ns; -- 200 MHZ
 
	BEGIN
 
		-- Instantiate the Unit Under Test (UUT)
		uut: E1OS_signal_generator 
			generic map(Width=>8,
				--N=> 12) 	
				--N=> 10) 	
				--N=> 8) 	
				--N=> 20) 	
				N=> 50) 	
			PORT MAP (clk => clk,
				rst => rst,
				PRN => PRN,
				E1OS => E1OS,
				valid => valid,
				enable => enable,
				strobe_in => strobe_in,
				strobe_out => strobe_out,
				addr_new => addr_new);			
				
		-- Clock process definitions
		clk_process :process
			begin
				clk <= '0';
				wait for clk_period/2;
				clk <= '1';
				wait for clk_period/2;
		end process;
	 
		-- Stimulus process
		stim_proc: process

			-- clean output files		
			file file_E1 : text open write_mode is "C:\Users\DaNi\Dropbox\FPGA\results\E1OS_signal.txt";				
			
			begin		
				file_close(file_E1);
			
				-- hold reset state for 100 ns.
				wait for 100 ns;	
				rst <= '0';
				wait for clk_period*10;

				wait;
		end process;
		
		-- Create strobe BOC signal
		process
			begin
				if strobe_boc_aux = '1' then
					wait for 41*clk_period/2;
					strobe_boc_aux <= '0';
				end if;
			
					strobe_in <= '1';
					wait for clk_period;
					strobe_in <= '0';
					--wait for 19*clk_period; -- 10 MHz @ 200 MHz
					--wait for 24*clk_period; -- 8 MHz	@ 200 MHz 				
					--wait for 9*clk_period; -- 20 MHz	@ 200 MHz 				
					wait for 3*clk_period; -- 50 MHz	@ 200 MHz 				
		end process;		

		-- Create strobe PRN signal
		process
			begin
				if strobe_prn_aux = '1' then
					wait for 41*clk_period/2;
					strobe_prn_aux <= '0';
				end if;
			
				strobe_prn <= '1';
				wait for clk_period;
				strobe_prn <= '0';
				wait for 199*clk_period; -- 1 MHz
		end process;		
		
		-- Read process
		process (clk)
		
			variable buff_E1B, buff_E1C : line;
			variable aux_E1B, aux_E1C : integer;
			
			-- Input file
			file file_E1B  : text open read_mode is "C:\Users\DaNi\Dropbox\Phd\Matlab\codeE1B.txt";				
			file file_E1C  : text open read_mode is "C:\Users\DaNi\Dropbox\Phd\Matlab\codeE1C.txt";				
			
			begin
			
				if (rising_edge(clk)) then  
					 if (rst = '0') then	
						if strobe_prn = '1' then
							
							readline(file_E1B,buff_E1B);
							read(buff_E1B,aux_E1B);
							
							readline(file_E1C,buff_E1C);
							read(buff_E1C,aux_E1C);							

							if aux_E1B = 1 then -- +1		
								PRN(1)<= '1';
							else							
								PRN(1)<= '0';
							end if;
							
							if aux_E1C = 1 then -- +1		
								PRN(0)<= '1';
							else							
								PRN(0)<= '0';
							end if;
						end if; --strobe_prn
					end if; -- rst			 
				end if; -- clk
		end process;		
		
		-- Write process
		process (clk)
			
			variable buff_E1OS : line;		

			--Output files			
			file file_E1OS : text open append_mode is "C:\Users\DaNi\Dropbox\FPGA\results\E1OS_signal.txt";			
		
			begin
				if (rising_edge(clk)) then 
					if (valid ='1') then
					
						if  strobe_out= '1' then
						
							write(buff_E1OS, E1OS); 
							writeline(file_E1OS, buff_E1OS);	
							
						end if;
					end if;
				end if;
		end process;		
		
		-- Main process		
		process (clk)
			begin
				if (rising_edge(clk)) then  

				 if (rst = '0') then

				 end if;
			
				end if;
		end process;	

END;
