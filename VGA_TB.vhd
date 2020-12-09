library ieee;
use ieee.std_logic_1164.all;
use work.LM_VGA.all;


entity VGA_TB IS
	generic (
		T		: time := 20ns;
		TCO 	: time := 5ns;
		TD		: time := 1ns
	);
	port(
	h_sync : out std_logic :='1';
	v_sync : out std_logic :='1';
	current_Position : out Position;
	out_px : out color
	);
end entity VGA_TB;

architecture structure of VGA_TB IS
signal CLK_50MHz : std_logic;
signal Reset : std_logic;
signal in_col : color;

begin
DUT: entity work.VGA(behave)
      port map(
				CLK_50MHz => CLK_50MHz,
				Reset => Reset,
				in_col => in_col,
				current_Position => current_Position,
				h_sync => h_sync,
				v_sync => v_sync,
				out_px => out_px
			);

Tester: entity work.VGA_Tester(test)
				port map(
				  CLK_50MHz => CLK_50MHz
				);


END architecture structure;
