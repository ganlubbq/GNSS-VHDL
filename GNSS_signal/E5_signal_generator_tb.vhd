--------------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------
-- Diary:	18/07/2016	Start 
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

library MIR_pkg;
use MIR_pkg.MIR_lib.all; 

ENTITY E5_signal_generator_tb IS
END E5_signal_generator_tb;

ARCHITECTURE behavior OF E5_signal_generator_tb IS 
 
	COMPONENT E5_signal_generator
		Generic(Width : integer := 8; -- Output width
			N : integer := 50);
		PORT(clk : in STD_LOGIC;
			rst	: in STD_LOGIC;
			PRN : in STD_LOGIC_VECTOR(4-1 downto 0);	
--			E5I : out STD_LOGIC_VECTOR(8-1 downto 0);
--			E5Q : out STD_LOGIC_VECTOR(8-1 downto 0);			
			E5I : out STD_LOGIC_VECTOR(Width-1 downto 0);
			E5Q : out STD_LOGIC_VECTOR(Width-1 downto 0);
			valid : out STD_LOGIC;
			enable : in std_logic;
			addr : in std_logic_vector(14-1 downto 0);
			strobe_in : in std_logic;
			strobe_out : out std_logic;
			addr_new : in std_logic);
	END COMPONENT;
    
   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '1';
   signal PRN : std_logic_vector(3 downto 0) ;
	signal enable : std_logic := '1';
	signal addr : std_logic_vector(14-1 downto 0):=  "10011111110101"; --10229
	signal strobe_in : std_logic := '0';
	signal addr_new : std_logic := '0';

 	-- Outputs
   signal E5I : std_logic_vector(7 downto 0);
   signal E5Q : std_logic_vector(7 downto 0);
	signal valid : std_logic;
	signal strobe_out : std_logic;
	
	-- Aux
	signal PRN_aux : std_logic_vector(7-1 downto 0):=  (others => '1');
	signal strobe_boc_aux : std_logic := '1';
	signal strobe_prn_aux : std_logic := '1';
	signal strobe_prn : std_logic := '0';
	signal addr_new_aux : std_logic := '0';
	signal addr_new_aux_d : std_logic := '0';
	signal addr_aux : std_logic_vector(14-1 downto 0):=  "10011111110101"; --10229
	signal polla_maxima :std_logic := '0';

	--constant clk_period : time := 5 ns; -- 200 MHz
	constant clk_period : time := 2.5 ns; -- 400 MHz

	BEGIN
 
		uut: E5_signal_generator 
			generic map(Width=>8,
				--N=> 60)  --Make sure to update the strobe_in properly!
				--N=> 24)
				--N=> 61)
				--N=> 120)
				--N=> 15)
				--N=> 50)
				--N=> 8)
				--N=> 10)
				--N=> 25)
				--N=> 100)
				  N=> 200)
			PORT MAP (clk => clk,
				rst => rst,
				PRN => PRN,
				E5I => E5I,
				E5Q => E5Q,
				valid => valid,
				enable => enable,
				addr => addr,
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
			file file_E5I : text open write_mode is "C:\Users\DaNi\Dropbox\FPGA\results\E5I_signal.txt";			
			file file_E5Q : text open write_mode is "C:\Users\DaNi\Dropbox\FPGA\results\E5Q_signal.txt";			
			
			begin		
				file_close(file_E5I); file_close(file_E5Q);
			
				wait for 100 ns;	
				rst<= '0';
				wait for clk_period/2;
				addr_new_aux <= '1';
				wait for clk_period;
				addr_new_aux <= '0';					
				
--				wait for clk_period*10230*5+clk_period*109; --make sure to sync with strobe_prn
--				polla_maxima <= '1';			
--				addr_new_aux <= '1';
--				wait for clk_period;
--				addr_new_aux <= '0';					
				
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
					--wait for 1*clk_period; -- 100 MHz @ 200 MHz
					--wait for 3*clk_period; -- 50 MHz @ 200 MHz
					--wait for 24*clk_period; -- 8 MHz @ 200 MHz
					--wait for 19*clk_period; -- 10 MHz @ 200 MHz
					--wait for 7*clk_period; -- 25 MHz @ 200 MHz
					wait for 1*clk_period; -- 200 MHz @ 400 MHz
		end process;		
		
		-- Create strobe PRN signal
		process
			begin
				if strobe_prn_aux = '1' then
					wait for clk_period/2;
					strobe_prn_aux <= '0';
				end if;
			
				strobe_prn <= '1';
				wait for clk_period;
				strobe_prn <= '0';
				--wait for 19*clk_period; -- 10 MHz @ 200 MHz
				wait for 39*clk_period; -- 10 MHz @ 400 MHz
		end process;	
		
		-- Read process
		process (clk)
		
			variable buff_E5aI, buff_E5aQ, buff_E5bI, buff_E5bQ : line;
			variable aux_E5aI, aux_E5aQ, aux_E5bI, aux_E5bQ  : integer;
		
			-- Input file
			file file_E5aI  : text open read_mode is "C:\Users\DaNi\Dropbox\Phd\Matlab\codeE5aI.txt";				
			file file_E5aQ  : text open read_mode is "C:\Users\DaNi\Dropbox\Phd\Matlab\codeE5aQ.txt";				
			file file_E5bI  : text open read_mode is "C:\Users\DaNi\Dropbox\Phd\Matlab\codeE5bI.txt";				
			file file_E5bQ  : text open read_mode is "C:\Users\DaNi\Dropbox\Phd\Matlab\codeE5bQ.txt";				
			
			begin
			
				if (rising_edge(clk)) then  
					 if (rst = '0') then	
						if strobe_prn = '1' then
							
							readline(file_E5aI,buff_E5aI);
							read(buff_E5aI,aux_E5aI);
							
							readline(file_E5aQ,buff_E5aQ);
							read(buff_E5aQ,aux_E5aQ);						
							
							readline(file_E5bI,buff_E5bI);
							read(buff_E5bI,aux_E5bI);												
							
							readline(file_E5bQ,buff_E5bQ);
							read(buff_E5bQ,aux_E5bQ);	

							if aux_E5bQ = 1 then -- +1		
								PRN(0)<= '1';
							else							
								PRN(0)<= '0';
							end if;
							
							if aux_E5aQ = 1 then -- +1		
								PRN(1)<= '1';
							else							
								PRN(1)<= '0';
							end if;

							if aux_E5bI = 1 then -- +1		
								PRN(2)<= '1';
							else							
								PRN(2)<= '0';
							end if;			

							if aux_E5aI = 1 then -- +1		
								PRN(3)<= '1';
							else							
								PRN(3)<= '0';
							end if;								
							
							
						end if; --strobe_prn
					end if; -- rst			 
				end if; -- clk
		end process;

		-- Write process
		process (clk)
			
			variable buff_E5I : line;		
			variable buff_E5Q : line;

			--Output files			
			file file_E5I : text open append_mode is "C:\Users\DaNi\Dropbox\FPGA\results\E5I_signal.txt";			
			file file_E5Q : text open append_mode is "C:\Users\DaNi\Dropbox\FPGA\results\E5Q_signal.txt";			
		
			begin
				if (rising_edge(clk)) then 
					if (valid ='1') then
					
						if  strobe_out= '1' then
						
							write(buff_E5I, E5I); 
							writeline(file_E5I, buff_E5I);	
							
							write(buff_E5Q, E5Q); 
							writeline(file_E5Q, buff_E5Q);	
							
						end if;
					end if;
				end if;
		end process;
		
		-- Main process
		process (clk)
			begin
				if (rising_edge(clk)) then  
					 if (rst = '0') then
					 
						addr_new_aux_d <= addr_new_aux;
						addr_new <= addr_new_aux_d;
						addr <= addr_aux;
					 
						if strobe_prn = '1' then
							
							if addr_new_aux = '0' then
								if addr_aux = 10229 then
									addr_aux <= (others => '0');
								else
									addr_aux <= addr_aux+1;
								end if;
							else
								if polla_maxima = '0' then
									addr_aux <= (others => '0');
								else
									--addr_aux <= "01010001110010"; --5234
									--addr_aux <= "01010001110011"; --5235							
									addr_aux <= "01010010001100"; --5260							
								end if;
							end if;
						 end if; --strobe
					 end if; --rst
				end if; --clk
		end process;		
end;