LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY xDFF IS

	PORT (
		D     : IN STD_LOGIC;
		Clk   : IN STD_LOGIC;
		Reset : IN STD_LOGIC;
		En    : IN STD_LOGIC;
		Q     : OUT STD_LOGIC := '0'
	);
END ENTITY;

ARCHITECTURE behave OF xDFF IS

BEGIN

	clocked : PROCESS (Reset, Clk, En)

	BEGIN

		IF (Reset = '1') THEN
			Q <= '0';

		ELSIF rising_edge(Clk) THEN
			IF En = '1' THEN
				Q <= D;
			END IF;
		END IF;

	END PROCESS clocked;

END ARCHITECTURE behave;
