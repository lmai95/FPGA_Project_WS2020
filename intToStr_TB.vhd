--Testbench of intToStr
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity intToStr_TB is

end entity intToStr_TB;

architecture sim of intToStr_TB is

  signal integer_input : signed integer;
  signal bin_output : std_logic_vector;

	component processing_tester is
	port
	(
		integer_input : in signed integer;
		bin_output : out std_logic_vector
	);
	end component processing_tester;

	begin

	tester: processing_tester
	port map
	(
		integer_input => integer_input,
		bin_output => bin_output
	);

	DUT: entity work.intToStr(logic)
	port map
	(
		integer_input => integer_input,
		bin_output => bin_output
	);
end architecture sim;
