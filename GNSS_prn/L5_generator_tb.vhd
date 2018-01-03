--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:29:08 06/03/2016
-- Design Name:   
-- Module Name:   C:/Users/DaNi/Dropbox/FPGA/proves2016/prns_lsfr/L5_generator_tb.vhd
-- Project Name:  proves2016
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: L5_generator
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
 
use ieee.std_logic_textio.all;
use std.textio.all;
 
use IEEE.std_logic_unsigned.all; -- per les sumes
use ieee.numeric_std.all; --to_signed, etc

use IEEE.math_real.all; --funcions matematiques
 
ENTITY L5_generator_tb IS
END L5_generator_tb;
 
ARCHITECTURE behavior OF L5_generator_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT L5_generator
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         PRN_I : OUT  std_logic;
         PRN_Q : OUT  std_logic;
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
   signal SAT : std_logic_vector(4 downto 0) := "00001";

 	--Outputs
   signal PRN_I : std_logic;
   signal PRN_Q : std_logic;
   signal valid : std_logic;
   signal epoch : std_logic;

   -- Clock period definitions
   constant clk_period : time := 5 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: L5_generator PORT MAP (
          clk => clk,
          rst => rst,
          PRN_I => PRN_I,
          PRN_Q => PRN_Q,
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

      wait for clk_period*10400;
		wait for 1 ms;	
		wait for clk_period*100;
		
		ENABLE <= '0';
		--SAT <= "00000";		

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
				write(buff_prn_real, PRN_I); 
				writeline(file_prn_real, buff_prn_real);	
			 end if;
			end if;
	end process;		

END;
