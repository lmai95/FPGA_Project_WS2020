library ieee;
use ieee.std_logic_1164.all;

--------------------------------------------------------------------
--	DDF bildet ein D-FlipFlop ab
-- die beiden Ausgänge sind mit einer Delay-Zeit versehen
--------------------------------------------------------------------
entity xDDF is
	generic(
		TCO 	: time := 10ns;
		TD		: time := 6ns
	);
	port(
		Reset	: in std_logic := '0';		--Eingänge für Simulation mit sinnvollen Werten initialisieren
		Set	: in std_logic := '0';
		sClear: in std_logic := '0';
		D		: in std_logic;
		EN		: in std_logic := '1';
		Clk	: in std_logic;
		Q		: out std_logic;
		Qn		: out std_logic
	);
end entity xDDF;

architecture behave of xDDF is
	signal Qi : std_logic;					--internes Ausgangssignal
begin

clocked: process(Reset,Set ,Clk)
begin
		if (Reset = '1' ) then				--Resetfall: Ausgang reseten
			Qi <= '0';
		elsif (Set = '1') then				--Setfall: Ausgang setzten
			Qi <= '1';
		elsif (rising_edge(Clk))then		--bei steigender Flanke Daten am Ausgang übernehmen oder löschen
			if sClear ='1'then
				Qi <= '0';
			elsif EN  ='1' then
				Qi <= D;
			end if;
		end if;
end process clocked;

Q <= Qi after TCO;							--Delay des Ausgangs, hier 10ns
Qn <= not Qi after TCO + TD;				--Delay des invertierten-Ausgangs nach 16ns

end architecture behave;
