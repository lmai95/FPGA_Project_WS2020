library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_generator is
	generic(
		freq_MHZ : integer :=25
	);
	port(
		clk_in	: in std_logic;
		clk_out	: out std_logic
		);
end entity clk_generator;

architecture behave of clk_generator is

	signal clk_sig : std_logic := '0';
	
begin

	clk_div : process(clk_in)
		begin
			if freq_MHZ = 25 then
				if rising_edge(clk_in) then
					clk_sig <= not clk_sig;
				end if;
			else
				clk_sig <= clk_in;
			end if;
		end process;

	clk_out <= clk_sig;
	
end architecture behave;