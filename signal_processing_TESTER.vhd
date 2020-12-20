library ieee;
use ieee.std_logic_1164.all;

entity signal_processing_TESTER is
	port
	(
    --example
		S : in std_logic;
		R : in std_logic;

		Q1: out std_logic;
		Q2: out std_logic

	);
end entity signal_processing_TESTER;



architecture sim of signal_processing_TESTER is
begin
  --example
	--S <= '0', '1' after 100ps, '0' after 200ps, '1' after 300ps;
	--R <= '0', '0' after 100ps, '1' after 200ps, '1' after 300ps;
end architecture sim;
