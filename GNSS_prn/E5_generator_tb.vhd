LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
use ieee.std_logic_textio.all;
use std.textio.all;
 
use IEEE.std_logic_unsigned.all; -- per les sumes
use ieee.numeric_std.all; --to_signed, etc

use IEEE.math_real.all; --funcions matematiques
 
 
ENTITY E5_generator_tb IS
END E5_generator_tb;
 
ARCHITECTURE behavior OF E5_generator_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT E5_generator
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         E5aI : OUT  std_logic;
         E5aQ : OUT  std_logic;
         E5bI : OUT  std_logic;
         E5bQ : OUT  std_logic;
         ENABLE : IN  std_logic;
         valid : OUT  std_logic;
         epoch : OUT  std_logic;
         SAT : IN  std_logic_vector(4 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '1';
   signal ENABLE : std_logic := '1';
   signal SAT : std_logic_vector(4 downto 0) := (others => '0');

 	--Outputs
   signal E5aI : std_logic;
   signal E5aQ : std_logic;
   signal E5bI : std_logic;
   signal E5bQ : std_logic;
   signal valid : std_logic;
   signal epoch : std_logic;

   -- Clock period definitions
   constant clk_period : time := 5 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: E5_generator PORT MAP (
          clk => clk,
          rst => rst,
          E5aI => E5aI,
          E5aQ => E5aQ,
          E5bI => E5bI,
          E5bQ => E5bQ,
          ENABLE => ENABLE,
          valid => valid,
          epoch => epoch,
          SAT => SAT
        );

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
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		rst<='0';

      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;
	
   process
		--clean output file									
		file file_prn_real : text open write_mode is "C:\Users\DaNi\Dropbox\FPGA\results\prn_real.txt";

			begin		
				file_close(file_prn_real);	
				wait;
		end process;

	writing_process : process (clk)
		variable buff_prn_real : line;
		file file_prn_real : text open append_mode is "C:\Users\DaNi\Dropbox\FPGA\results\prn_real.txt";
		
		begin
			if (rising_edge(clk)) then  

			 if (valid = '1') then
				--write(buff_prn_real, E5aI); 
				write(buff_prn_real, E5bI); 
				writeline(file_prn_real, buff_prn_real);	
			 end if;
			end if;
	end process;	

END;
