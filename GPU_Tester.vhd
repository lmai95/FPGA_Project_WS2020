library ieee;
use ieee.std_logic_1164.all;
use work.LM_VGA.all;


entity GPU_Tester IS
	generic (
		T		: time := 20ns;
		TCO 	: time := 5ns;
		TD		: time := 1ns
	);
	port(
    Reset : out std_logic := '0';
		CLK_50MHz : out  std_logic := '0'
	);
end entity GPU_Tester;

architecture test of GPU_Tester is
	signal iCLk : std_logic:='0';

BEGIN
Clockgen: PROCESS

BEGIN
	iClk	<= not iClk;
	wait for T/2;
END PROCESS Clockgen;

Reset <=  '1' , '0' after 1ns ;
CLK_50MHz <= iClK;


END architecture test;
