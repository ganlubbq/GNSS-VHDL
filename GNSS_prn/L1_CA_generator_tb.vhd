
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
use ieee.std_logic_textio.all;
use std.textio.all;
 
use IEEE.std_logic_unsigned.all; -- per les sumes
use ieee.numeric_std.all; --to_signed, etc

use IEEE.math_real.all; --funcions matematiques
 
ENTITY L1_CA_generator_tb IS
END L1_CA_generator_tb;
 
ARCHITECTURE behavior OF L1_CA_generator_tb IS 
 
    COMPONENT L1_CA_generator
		PORT(clk : IN  std_logic;
			rst : IN  std_logic;
			PRN : OUT  std_logic;
			ENABLE : IN  std_logic;
			valid_out : out std_logic;
			epoch : out STD_LOGIC;
			SAT : in integer range 0 to 31;
			SAT_change : out STD_LOGIC); 				  
    END COMPONENT;
    
   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '1';
   signal ENABLE : std_logic := '1';
	--signal SAT : integer := 2;
	signal SAT : integer := 0;

 	--Outputs
   signal PRN : std_logic;
	signal epoch : std_logic;
	signal valid_out : std_logic;
	signal SAT_change : std_logic;	

   -- Clock period definitions
   constant clk_period : time := 5 ns; --200 MHz
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: L1_CA_generator
		PORT MAP (clk => clk,
          rst => rst,
          PRN => PRN,
          ENABLE => ENABLE,
			 valid_out => valid_out ,
			 epoch => epoch,
			 SAT => SAT,
			 SAT_change => SAT_change);

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
	
		file file_prn_real : text open write_mode is "GNSS_prn/L1_CA_generator_output.txt";
	
		begin		
			
			file_close(file_prn_real);	 -- clean outputfile
			
			wait for 100 ns;	
			rst<='0';

			-- Disable/Enable
			wait for clk_period*100;
			ENABLE <= '0';
			wait for clk_period*100;
			ENABLE <= '1';
			
			-- Change PRN while Enabled
			wait for clk_period*1023*2;
			SAT <= 0;

			-- Disable+Change PRN/Enable
			wait for clk_period*1023*2;			
			ENABLE <= '0';
			SAT <= 1;
			wait for clk_period*100;
			ENABLE <= '1';
			
			-- Disable+Change PRN/Enable
			wait for clk_period*1023*2+clk_period;			
			ENABLE <= '0';
			SAT <= 20;
			wait for clk_period*2;
			ENABLE <= '1';			
			
			-- Disable/Change PRN/Enable
			wait for clk_period*1023*2;			
			ENABLE <= '0';
			wait for clk_period*10;
			SAT <= 4;
			wait for clk_period*100;
			ENABLE <= '1';			
			
			-- Disable/Change PRN+Enable
			wait for clk_period*1023*2;			
			ENABLE <= '0';
			wait for clk_period*10;
			SAT <= 5;
			ENABLE <= '1';					
			
			-- Disable/Change PRN/Change PRN (same as previous)/Enable [IMPORTANT]
			wait for clk_period*1023*2;			
			ENABLE <= '0';
			wait for clk_period*10;
			SAT <= 6;
			wait for clk_period*10;
			SAT <= 5;
			wait for clk_period*10;
			ENABLE <= '1';			

			-- Disable/Change PRN/Change PRN/Enable 
			wait for clk_period*1023*2;			
			ENABLE <= '0';
			wait for clk_period*10;
			SAT <= 6;
			wait for clk_period*10;
			SAT <= 7;
			wait for clk_period*10;
			ENABLE <= '1';						
			
			-- Change PRN/Change PRN
			wait for clk_period*1023*2;
			SAT <= 8;
			wait for clk_period*1;
			SAT <= 9;
			
			-- Change PRN/Change PRN
			wait for clk_period*1023*2;
			SAT <= 10;
			wait for clk_period*2;
			SAT <= 11;			

			
			wait;
   end process;

	-- Write process
	writing_process : process (clk)
		variable buff_prn_real : line;
		file file_prn_real : text open append_mode is "GNSS_prn/L1_CA_generator_output.txt";
		
		begin
			if (rising_edge(clk)) then  
				if (valid_out  = '1') then
					write(buff_prn_real, PRN); 
					writeline(file_prn_real, buff_prn_real);	
				end if;
			end if;
	end process;
END;