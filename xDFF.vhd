library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xDFF is 

	port (
		D 		: in std_logic;
		Clk		: in std_logic;
		Reset 	: in std_logic;
		En 		: in std_logic;
		Q		: out std_logic := '0'
		);
end entity;

architecture behave of xDFF is

begin

	clocked: process(Reset, Clk, En)

		begin

			if (Reset = '1') then
				Q <= '0';
				
			elsif rising_edge(Clk) then
				if En = '1' then
					Q <= D;
				end if;
			end if;
			
		end process clocked;
	
end architecture behave;
	
