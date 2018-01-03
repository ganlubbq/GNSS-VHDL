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
 
 
ENTITY E1_generator_tb IS
END E1_generator_tb;
 
ARCHITECTURE behavior OF E1_generator_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT E1_generator
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         E1B : OUT  std_logic;
         E1C : OUT  std_logic;
         ENABLE : IN  std_logic;
         valid_out : OUT  std_logic;
         epoch : OUT  std_logic;
         SAT : IN  std_logic_vector(4 downto 0);
			addr_out : out STD_LOGIC_VECTOR(17-1 downto 0));			
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '1';
   signal ENABLE : std_logic := '1';
   signal SAT : std_logic_vector(4 downto 0) := "01011";

 	--Outputs
   signal E1B : std_logic;
   signal E1C : std_logic;
   signal valid_out : std_logic;
   signal epoch : std_logic;
	
	signal addr_out : STD_LOGIC_VECTOR(17-1 downto 0);			


   -- Clock period definitions
   constant clk_period : time := 5 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: E1_generator PORT MAP (
          clk => clk,
          rst => rst,
          E1B => E1B,
          E1C => E1C,
          ENABLE => ENABLE,
          valid_out => valid_out,
          epoch => epoch,
          SAT => SAT,
			 addr_out => addr_out);

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

			 if (valid_out = '1') then
				write(buff_prn_real, E1C); 
				writeline(file_prn_real, buff_prn_real);	
			 end if;
			end if;
	end process;	

END;
