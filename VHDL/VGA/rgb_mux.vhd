LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY rgb_mux IS
	GENERIC
	(
		border : INTEGER := 160
	);
	PORT (
		hpos    : IN INTEGER;
		vpos    : IN INTEGER;
		rgb0    : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		rgb1    : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		rgb_out : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
	);
END ENTITY rgb_mux;
ARCHITECTURE behave OF rgb_mux IS

BEGIN

	rgb_switch : PROCESS (vpos, rgb0, rgb1)
	BEGIN
		IF (vpos <= (border)) THEN
			rgb_out  <= rgb0;
		ELSIF (vpos > (border)) THEN
			rgb_out <= rgb1;
		END IF;
	END PROCESS rgb_switch;

END ARCHITECTURE behave;
