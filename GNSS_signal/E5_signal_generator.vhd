--------------------------------------------------------------------------------------
-- 											THEORY
-- Create the E5 signal with the constant envelope AltBOC(15,10) modulation with the
-- E5aI, E5aQ, E5bI, E5bQ codes. The subcarrier signals have a rate Fb = Y*1.023 MHz
-- (Y = 15), and the codes Fc = X*1.023 MHz(X=10).
--
-- E5I = (E5aI+E5bI)*sd(t)+
--       (E5aQ-E5bQ)*sd(t-Tb/4)+
--       (E5aI*+E5bI*)*sp(t)+
--       (E5aQ*-E5bQ*)*sp(t-Tb/4).
-- E5Q = (E5aQ+E5bQ)*sd(t)+
--       (-E5aI+E5bI)*sd(t-Tb/4)+
--       (E5aQ*+E5bQ*)*sp(t)+
--       (-E5aI*+E5bI*)*sp(t-Tb/4).
--
-- where Tb is the period of the subcarrier = 1/Fb, and with
-- sd(t) = sqrt(2)/4*sign(cos(2 pi Fb t - pi/4 ))+0.5*sign(cos(2 pi Fb t))+sqrt(2)/4*sign(cos(2 pi Fb t + pi/4))
-- sp(t) = -sqrt(2)/4*sign(cos(2 pi Fb t - pi/4 ))+0.5*sign(cos(2 pi Fb t))-sqrt(2)/4*sign(cos(2 pi Fb t + pi/4))
-- 
-- The combination of these sequences result in 8 different values. E5I/E5Q can be 
-- created with the next loop-up table:
--
-- aI	0		0		0		0		0		0		0		0		1		1		1		1		1		1		1		1
-- bI	0		0		0		0		1		1		1		1		0		0		0		0		1		1		1		1
-- aQ	0		0		1		1		0		0		1		1		0		0		1		1		0		0		1		1
-- bQ	0		1		0		1		0		1		0		1		0		1	
-- t
-- 0  4     3     3     2     5     2     0     1     5     4     6     1     6     7     7     0
-- 1  4     3     7     2     1     2     0     1     5     4     6     5     6     3     7     0
-- 2  0     3     7     6     1     2     0     1     5     4     6     5     2     3     7     4
-- 3  0     7     7     6     1     2     0     5     1     4     6     5     2     3     3     4
-- 4  0     7     7     6     1     6     4     5     1     0     2     5     2     3     3     4
-- 5  0     7     3     6     5     6     4     5     1     0     2     1     2     7     3     4 
-- 6  4     7     3     2     5     6     4     5     1     0     2     1     6     7     3     0
-- 7  4     3     3     2     5     6     4     1     5     0     2     1     6     7     7     0
--
-- E5I/E5Q are then obtained with
-- 0 = a/a
-- 1 = 1/0
-- 2 = -a/a
-- 3 = 0/-1
-- 4 = -a/-a
-- 5 = -1/0
-- 6 = a/-a
-- 7 = 0/1
--
-- where a=sqrt(2)/2.  With 8 bits- -> a=90 (error of 0.22%)
-- 
-- I orginally tried a single look-up table instead of two, but Xilinx used an
-- unnecessary RAM18K.
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- 											SUB-SAMPLING
-- Fmin = M*1.023 MHz --> Minimum frequency to generate the complete "t" sequence.
--								  with M = 120.
-- F = N*1.023 MHz --> Frequency used to generate the "t" sequence, with N integer >=1.
-- T/P is the irreducible fraction of M/N:
--			T = M/gcd(M,N)
--			P = N/gcd(M,N)
--
-- L_M = lcm(T,8) --> Lenght of the sub-sampled sequences in periods of M
-- L_N = L_M*P/T --> Lenght of the sub-sampled sequences in periods of N
--
-- The "t" sequence is finally generated with
-- t = floor( (8*Y) * mod(p/N,1/Y))   p=0...L_N-1
--
-- * gcd is the greatest common divisor, and lcm is the least common multiple
-- ** do not confuse M and N with the classical terminology in BOC(N,M) signals
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- The initial t depends on the reference address:
-- s = floor( @ref/10*N mod L_N )   @ref=0..10229
--
-- VHDL does not allow to synthesize real numbers (needed to convert @ref). So I
-- generate a vector for all the possible address.
--------------------------------------------------------------------------------------
-- **** INPUTS ****
-- PRN: PRN(3) = E5aI, PRN(2)= E5AaQ, PRN(1) = E5bI, PRN(0) =E5bQ
-- enable --> Freeze everything when '0'
-- addr --> Address of the PRNs
-- strobe_in --> "t" sequence generation strobe
-- addr_new --> New address set
-- N --> The sampling frequency (x 1.023 MHz) (i.e. the "t" frequency), not to be 
--	      confused with the PRN frequency.
--
-- **** OUTPUTS  ****
-- E5I,E5Q --> Signal
-- valid --> Signal valid
-- strobe_out --> New output sample
--------------------------------------------------------------------------------------
-- Diary:	11/06/2016	Start 
--				20/07/2016 	Version 1.0	Dani --> The PRNs MUST be generated at 10*1.023MHz
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

library MIR_pkg;
use MIR_pkg.MIR_lib.all; 

entity E5_signal_generator is
		Generic(Width : integer := 8; -- Output width
				N : integer := 50);
		Port (clk : in STD_LOGIC;
			rst	: in STD_LOGIC;
			PRN : in STD_LOGIC_VECTOR(4-1 downto 0);	-- PRN(3) = E5aI, PRN(2)= E5bI, PRN(1) = E5aQ, PRN(0) =E5bQ
			E5I : out STD_LOGIC_VECTOR(Width-1 downto 0);
			E5Q : out STD_LOGIC_VECTOR(Width-1 downto 0);
			valid : out STD_LOGIC;
			enable : in std_logic;
			addr : in std_logic_vector(14-1 downto 0);
			strobe_in : in std_logic;
			strobe_out : out std_logic;
			addr_new : in std_logic);
end E5_signal_generator;

architecture Behavioral of E5_signal_generator is

	-- Signals
	signal DECOD : STD_LOGIC_VECTOR(3-1 downto 0);
	signal t: std_logic_vector(3-1 downto 0);
	
	signal PRN_d, PRN_d2, PRN_d3  : std_logic_vector(4-1 downto 0);	
	
	signal strobe_in_d, strobe_in_d2, strobe_in_d3,strobe_in_d4, strobe_in_d5 : std_logic;
	signal valid_aux, valid_aux_d, valid_aux_d2, valid_aux_d3, valid_aux_d4 : std_logic;	
	
	-- Constants
	constant alfa_real : real :=  sqrt(real(2))/real(2);		--sqrt(2)/2
	constant alfa_integer : integer := integer(alfa_real *real(2**(Width-1)-1));
	signal alfa: std_logic_vector (Width-1 downto 0)  := STD_LOGIC_VECTOR(to_unsigned(alfa_integer,Width));
	signal logic_one : std_logic_vector (Width-1 downto 0)  := STD_LOGIC_VECTOR(to_unsigned(2**(Width-1)-1,Width));	
	
	constant M : integer := 120;														-- sd/sp sequences minimum rate (M*1.023 MHz)
	constant T_E5 : real :=  0.0666666666666666666666666;						-- Period of a full sd/sp sequence T_E5/1.023e-6 s
	constant T_E5_inv : real := 15.0;
	constant TT : integer := integer(real(M)/real(gcd(M,N)));				-- TT = M/gcd(M,N)
	constant PP : integer := integer(real(N)/real(gcd(M,N)));				-- PP = N/gcd(M,N)
	constant L_M : integer := lcm(TT,8);											-- Lenght of sub-sampled sequence in periods of M
	constant L_N : integer := integer(real(L_M)*(real(PP)/(real(TT))));	-- Lenght of sub-sampled sequence in periods of N
	
	constant aux : integer := integer(ceil(log2(real(L_N))));
	constant aux2 : integer := integer(REALMAX(1.0,real(aux)));
	signal cont : std_logic_vector(aux2-1 downto 0);							-- Counter to update "t"
	
	-- Types 
	type E5_array is array (0 to L_N-1) of std_logic_vector(3-1 downto 0); 
	type E5_array_2 is array (0 to 10230-1) of std_logic_vector(aux2-1 downto 0);  

	-- Functions
	function compute_v return E5_array is -- The VALUES of the sub-sampled "t" sequence
		variable v : E5_array;
		
		begin
			for j in 0 to L_N-1 loop
				v(j) := std_logic_vector(to_unsigned(integer(floor(((real(j)/real(N)) mod T_E5)*real(8)*T_E5_inv)),3));
			end loop;			
			
			return v;
	end compute_v;	
	
	function compute_s return E5_array_2 is -- The INDEX of the sub-sampled "t" sequence when a new address is set
		variable s : E5_array_2;
		
		begin
			for j in 0 to 10230-1 loop
				s(j) := std_logic_vector(to_unsigned(integer(floor((real(j)*real(N)/10.0) mod real(L_N) )),aux2));				
			end loop;
		
			return s;
	end compute_s; 	
	
	signal v : E5_array := compute_v;	-- The values of "t" to generate the sub-sampled sequence
	signal s : E5_array_2 := compute_s; -- The index for the "t" sequence when a new_address is set
	-----------------------------------------------------------------------------------	
	begin
		------- PROCESSES --------------------------------------------------			
		process(clk)
			begin
				if (rising_edge(clk)) then		
					if (rst = '1') then
						E5I<= (others => '0');
						E5Q<= (others => '0');
						DECOD<= (others => '0');
						
						valid <= '0';
						valid_aux <= '0';
						valid_aux_d <= '0';
						valid_aux_d2 <= '0';
						valid_aux_d3 <= '0';
						valid_aux_d4 <= '0';
						
						strobe_out <= '0';
						strobe_in_d  <= '0';
						strobe_in_d2  <= '0';
						strobe_in_d3  <= '0';
						strobe_in_d4  <= '0';
						strobe_in_d5  <= '0';
						
						t <= v(L_N-1);
						cont <=  std_logic_vector(to_unsigned(integer(L_N-1),aux2));						
						
						PRN_d <=(others => '0');
						PRN_d2 <=(others => '0');
						PRN_d3 <=(others => '0');
						
					else
					
						t <= v(to_integer(unsigned(cont)));
						
						PRN_d <= PRN;  -- sync with t
						PRN_d2 <= PRN_d;
						PRN_d3 <= PRN_d2;
						
						valid_aux_d <= valid_aux;
						valid_aux_d2 <= valid_aux_d;
						valid_aux_d3 <= valid_aux_d2;
						valid <= valid_aux_d2;					
					
						strobe_in_d <= strobe_in; 		-- Depending on the frequency of strobe_in
						strobe_in_d2 <= strobe_in_d;	-- it could be done with less delays, but
						strobe_in_d3 <= strobe_in_d2; -- as it is now, it works always.
						strobe_in_d4 <= strobe_in_d3;
						strobe_out <= strobe_in_d3;
						
						if enable = '0' then
							valid_aux <= '0';
						else
						
							valid_aux <= '1';

							-- Conunter for "t" management
							if (addr_new = '1') then
								cont <= s(to_integer(unsigned(addr)));
							else
								if strobe_in = '1' then
									if cont = (L_N-1) then
										cont <= (others => '0');
									else
										cont<= cont+1;
									end if;
								end if;							
							end if;			

							-- Decode "t-PRN"
							CASE to_integer(unsigned((t& PRN_d(3) & PRN_d(2) & PRN_d(1) & PRN_d(0))))  IS 
								WHEN 6 | 15 | 22 | 31 | 32 | 38 | 48 | 54 | 64 | 73 | 80 | 89 | 105 | 111 | 121 | 127 => 
									DECOD<="000"; 
								WHEN 7 | 11 | 20 | 23 | 36 | 39 | 52 | 56 | 68 | 72 | 88 | 91 | 104 | 107 | 119 | 123  => 
									DECOD<="001"; 
								WHEN 3 | 5 |  19 | 21 | 37 | 44 | 53 | 60 | 74 | 76 | 90 | 92 | 99 | 106 | 115 | 122 => 
									DECOD<="010"; 
								WHEN 1 | 2 | 17 | 29 | 33 | 45 | 61 | 62 | 77 | 78 | 82 | 94 | 98 | 110 | 113 | 114 => 
									DECOD<="011"; 
								WHEN 0 | 9 | 16 | 25 | 41 | 47 | 57 | 63 | 70 | 79 | 86 | 95 | 96 | 102 | 112 | 118 => 
									DECOD<="100"; 
								WHEN 4 | 8 | 24 | 27 | 40 | 43 | 55 | 59 | 71 | 75 | 84 | 87 | 100 | 103 | 116 | 120 => 
									DECOD<="101"; 
								WHEN 10 | 12 | 26 | 28 | 35 | 42 | 51 | 58 | 67 | 69 | 83 | 85 | 101 | 108 | 117 | 124 => 
									DECOD<="110"; 
								WHEN 13 | 14 | 18 | 30 | 34 | 46 | 49 | 50 | 65 | 66 | 81 | 93 | 97 | 109 | 125 | 126 => 
									DECOD<="111"; 
								WHEN OTHERS => 							
									DECOD <= (others => '0');	
							end case;
							
							CASE DECOD  IS
								WHEN "000" => --1
									E5Q <= alfa;
									E5I <= alfa;
								WHEN "001" => --2
									E5Q <= logic_one;
									E5I <= (others => '0');	
								WHEN "010" => --3
									E5Q <= alfa;
									E5I <= -alfa;
								WHEN "011" => --4
									E5Q <= (others => '0');	
									E5I <= -logic_one;					
								WHEN "100" => --5
									E5Q <= -alfa;
									E5I <= -alfa;
								WHEN "101" => --6
									E5Q <= -logic_one;	
									E5I <= (others => '0');	
								WHEN "110" => --7
									E5Q <= -alfa;								
									E5I <= alfa;
								WHEN "111" => --8
									E5Q <= (others => '0');	
									E5I <= logic_one;	
								WHEN OTHERS => 		
									E5I <= (others => '0');	
									E5Q <= (others => '0');										
							end case;
						end if; --enable
					end if; --rst
				end if; --clk
		end process;					
end Behavioral;