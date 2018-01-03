--------------------------------------------------------------------------------------
-- 											THEORY
-- Create the E1OS signal with the CBOC(6,1,1/11) modulation with E1B and E1C codes:
--
-- E1OS = E1B*(b*BOCs(6,1)+a*BOCs(1,1)) - E1C*(-b*BOCs(6,1)+a*BOCs(1,1))
-- where a = sqrt(10/11), b = sqrt(1/11), and BOCs(X,Y) is a sine-phased BOC signal
-- with a sub-carrier rate S and a PRN chip frequency U:
-- BOCs(S,U) = sign(sin(2 pi S t)), and with the exception that sign(0) = 1. 
-- 
-- It can be computed with the next loop-up table
-- E1B   1		1		0		0
-- E1C	1		0		1		0
-- t
-- 0		2b		2a		-2a	-2b
-- 1		-2b	2a		-2a	2b			
-- 2		2b		2a		-2a	-2b	
-- 3		-2b	2a		-2a	2b
-- 4		2b		2a		-2a	-2b
-- 5		-2b	2a		-2a	2b
-- 6		2b		-2a	2a		-2b		
-- 7		-2b	-2a	2a		2b
-- 8		2b		-2a	2a		-2b
-- 9		-2b	-2a	2a		2b
-- 10		2b		-2a	2a		-2b
-- 11		-2b	-2a	2a		2b
--
-- where a=1 and b=1/sqrt(10) and t=mod(T,12), and T=mod(adress,4092)
-- With 8 bits- -> 2a=127, -2a= -127, 2b= 40, 2b=-40. (error of 0.4% in 2b)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 											SUB-SAMPLING
-- Fmin = M*1.023 MHz --> Minimum frequency to generate the complete "t" sequence.
--								  with M = 12.
-- F = N*1.023 MHz --> Frequency used to generate the "t" sequence, with N integer >=1.
-- L_N = N --> Lenght of the sub-sampled sequences in periods of N
--
-- The "t" sequence is generated with
-- t = floor( (12*Y) * mod(p/N,1/Y))   p=0...L_N-1
-- where Y = 1.
--
-- The "t" sequence is always syncrhonized with the PRN. Thus the initial t=0 for all
-- reference address.
--------------------------------------------------------------------------------------
-- **** INPUTS ****
-- PRN: PRN(0) = E1C, PRN(1) = E1B
-- enable --> Freeze everything when '0'
-- strobe_in --> "t" sequence generation strobe
-- addr_new --> New address set
-- N --> The sampling frequency (x 1.023 MHz) (i.e. the "t" frequency), not to be 
--	      confused with the PRN frequency.
--
-- **** OUTPUTS  ****
-- E1OS --> Signal
-- valid_out --> Signal valid
-- strobe_out --> New output sample
--------------------------------------------------------------------------------------
-- Diary:	10/06/2016	Start 
--				20/07/2016 	Version 1.0	Dani --> The PRNs MUST be generated at 1*1.023MHz
--															I am not sure about the behaviour if not
--------------------------------------------------------------------------------------
-- Author: Daniel Pascual (daniel.pascual@tsc.upc.edu)
--
-- This work is licensed under the Creative Commons Attribution 4.0 International 
-- License. To view a copy of this license, visit 
-- http://creativecommons.org/licenses/by/4.0/.
--------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all; 			-- to_signed, etc
use IEEE.std_logic_signed.all; 	-- additions
use IEEE.math_real.all; 			-- maths

entity E1OS_signal_generator is
		Generic(Width : integer := 8;			-- Output width
				N : integer := 12);		
		Port (clk : in STD_LOGIC;
			rst	: in STD_LOGIC;
			PRN : in STD_LOGIC_VECTOR(2-1 downto 0);	-- PRN(1) = E1B, PRN(0)= E1C
			E1OS : out STD_LOGIC_VECTOR(Width-1 downto 0);
			valid : out std_logic;
			enable : in std_logic;
			strobe_in : in std_logic;
			strobe_out : out std_logic;
			addr_new : in std_logic);			
end E1OS_signal_generator;

architecture Behavioral of E1OS_signal_generator is

	-- Signals
	signal t : std_logic_vector(4-1 downto 0);
	signal PRN_d : STD_LOGIC_VECTOR(2-1 downto 0);
	
	signal valid_aux, valid_aux_d : std_logic;
	
	signal strobe_in_d, strobe_in_d2 : std_logic;

	-- Constants
	constant alfa2_integer : integer := 2**(Width-1)-1; --127
	constant beta2_real : real :=  sqrt(real(1)/real(10));
	constant beta2_integer : integer := integer(beta2_real *real(alfa2_integer));
	
	signal alfa2: std_logic_vector (Width-1 downto 0)  := STD_LOGIC_VECTOR(to_unsigned(alfa2_integer,Width));
	signal beta2:  std_logic_vector (Width-1 downto 0)  := STD_LOGIC_VECTOR(to_unsigned(beta2_integer,Width));
	
	constant aux : integer := integer(ceil(log2(real(N))));
	constant aux2 : integer := integer(REALMAX(1.0,real(aux)));
	signal cont : std_logic_vector(aux2-1 downto 0);							-- Counter to update "t"	
	
	-- Types 
	type E1_array is array (0 to N-1) of std_logic_vector(4-1 downto 0); 	
	
	-- Functions
	function compute_v return E1_array is -- The VALUES of the sub-sampled "t" sequence
		variable v : E1_array;
		
		begin
			for j in 0 to N-1 loop
				v(j) := std_logic_vector(to_unsigned(integer(floor(((real(j)/real(N)) mod 1.0)*12.0*1.0)),4));
			end loop;			
			
			return v;
	end compute_v;		
	
	signal v : E1_array := compute_v;	-- The values of "t" to generate the sub-sampled sequence
	-----------------------------------------------------------------------------------	
	begin
		------- PROCESSES --------------------------------------------------			
		process(clk)
			begin
				if (rising_edge(clk)) then		
					if (rst = '1') then
						E1OS <= (others => '0');
						
						valid <= '0';
						valid_aux <= '0';
						valid_aux_d <= '0';		

						strobe_out <= '0';
						strobe_in_d  <= '0';	
						strobe_in_d2  <= '0';							
						
						t <= v(N-1);
						cont <=  std_logic_vector(to_unsigned(integer(N-1),aux2));						
						
						PRN_d <= (others => '0');
						
					else
					
						t <= v(to_integer(unsigned(cont)));
						
						PRN_d <= PRN;
						
						valid_aux_d <= valid_aux;
						valid <= valid_aux_d;

						strobe_in_d <= strobe_in;
						strobe_in_d2 <= strobe_in_d;
						strobe_out <= strobe_in_d2;						

						if enable = '0' then
							valid_aux <= '0';
						else					
					
							valid_aux <= '1'; 
							
							-- Counter for "t" management
							if (addr_new = '1') then
								cont <= (others => '0');
							else
								if strobe_in = '1' then
									if cont = (N-1) then
										cont <=  (others => '0');
									else
										cont<= cont+1;
									end if;
								end if;		
							end if;								
							
							-- Decode "t-PRN"
							if (unsigned(t)<= 11) then    
								if (PRN_d(0) = not PRN_d(1)) then  --"10" or "01"
									if  (unsigned(t) < 6) then
										if (PRN_d(0) = '1') then
											E1OS <= -alfa2; 
										else
											E1OS <= alfa2; 
										end if;
									else
										if (PRN_d(0) = '1') then
											E1OS <= alfa2; 
										else
											E1OS <= -alfa2; 
										end if;
									end if;
								else --"11" or "00"
									if PRN_d(0) = '1' then
										if t(0) = '0' then 
											E1OS <= beta2;
										else
											E1OS <= -beta2;
										end if;
									else
										if t(0) = '0' then 
											E1OS <= -beta2;
										else
											E1OS <= beta2;
										end if;
									end if;
								end if;
							else
								E1OS <= (others => '0');
							end if; -- E1OS
						end if; --enable
					end if; --rst
				end if; --clk
		end process;					
end Behavioral;