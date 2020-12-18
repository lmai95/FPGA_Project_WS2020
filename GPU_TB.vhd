library ieee;
use ieee.std_logic_1164.all;
use work.LM_VGA.all;


entity GPU_TB IS
	generic (
		T		: time := 20ns;
		TCO 	: time := 5ns;
		TD		: time := 1ns
	);
end entity GPU_TB;

architecture structure of GPU_TB IS
signal CLK_50MHz : std_logic;
signal Reset : std_logic;
signal enable_plotter : std_logic;
begin
DUT: entity work.GPU(behave)
      port map(
				CLK_50MHz => CLK_50MHz,
				Reset => Reset,
				enable_plotter => enable_plotter
			);

Tester: entity work.GPU_Tester(test)
				port map(
				  CLK_50MHz => CLK_50MHz,
					Reset => Reset,
					enable_plotter => enable_plotter
				);


END architecture structure;
