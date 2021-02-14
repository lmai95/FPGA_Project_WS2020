LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

ENTITY scaling IS
	GENERIC
	(
		MAX_value : INTEGER := 2000;
		MIN_value : INTEGER := - 2000;
		MAX_DATA  : INTEGER := 110;
		MIN_DATA  : INTEGER := 460
	);
	PORT (
		clk              : IN STD_LOGIC;
		data_valid       : IN STD_LOGIC;
		in_value         : IN INTEGER RANGE -32768 TO 32767;
		out_scaled_value : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
		out_valid        : OUT STD_LOGIC
	);
END ENTITY scaling;

ARCHITECTURE behave OF scaling IS
	FUNCTION INT_to_V(INPUT : INTEGER)RETURN STD_LOGIC_VECTOR IS
	BEGIN
		RETURN STD_LOGIC_VECTOR(to_unsigned(INPUT, 9));
	END FUNCTION;

BEGIN
	PROCESS (clk)
		VARIABLE previous_value : INTEGER RANGE -32768 TO 32767;
		VARIABLE scaled_value   : INTEGER;
		VARIABLE valid : STD_LOGIC;
	BEGIN
		IF rising_edge(clk) THEN
			IF  data_valid = '1'THEN --previous_value /= in_value AND
				previous_value := in_value;
				scaled_value   := MIN_DATA + (in_value - MIN_value) * (MAX_DATA - MIN_DATA)/(MAX_value - MIN_value);
				valid := '1';
				out_scaled_value <= INT_to_V(scaled_value);
			ELSE
				valid := '0';
				out_scaled_value <= INT_to_V(350);
			END IF;
		END IF;
		out_valid <= valid;
		out_scaled_value <= INT_to_V(scaled_value);
	END PROCESS;

END ARCHITECTURE behave;
