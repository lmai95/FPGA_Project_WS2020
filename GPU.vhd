library ieee;
use ieee.std_logic_1164.all;
use work.LM_VGA.all;

entity GPU IS
	generic (
		T		: time := 20ns;
		TCO 	: time := 5ns;
		TD		: time := 1ns
	);
	port(
  CLK_50MHz : in std_logic;
  Reset : in std_logic;
  in_col : in color := black;
	h_sync : out std_logic :='1';
	v_sync : out std_logic :='1';
	current_Position : out Position;
	out_px : out color
	);
end entity GPU;

architecture structure of GPU IS
begin
VGA0: entity work.VGA(behave)
  port map (
    CLK_50MHz => CLK_50MHz,
    Reset => Reset,
    in_col => in_col,
    current_Position => current_Position,
    h_sync => h_sync,
    v_sync => v_sync,
    out_px => out_px
    );
end architecture structure;
