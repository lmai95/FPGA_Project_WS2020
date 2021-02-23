LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY Integer2BCD IS
	PORT (
		x_in  : IN INTEGER RANGE -9999 TO 9999;
		x_out : OUT STD_LOGIC_VECTOR(0 TO 16);
		y_in  : IN INTEGER RANGE -9999 TO 9999;
		y_out : OUT STD_LOGIC_VECTOR(0 TO 16);
		z_in  : IN INTEGER RANGE -9999 TO 9999;
		z_out : OUT STD_LOGIC_VECTOR(0 TO 16)
	);

END ENTITY Integer2BCD;

ARCHITECTURE behave OF Integer2BCD IS

	SIGNAL x_sig : INTEGER RANGE -9999 TO 9999;
	SIGNAL y_sig : INTEGER RANGE -9999 TO 9999;
	SIGNAL z_sig : INTEGER RANGE -9999 TO 9999;

	TYPE div IS ARRAY(0 TO 3) OF INTEGER;
	CONSTANT divs : div := (1000, 100, 10, 1);

	SIGNAL xout0, xout1, xout2, xout3      : STD_LOGIC_VECTOR(0 TO 3);
	SIGNAL xout0_int, xout1_int, xout2_int : INTEGER;
	SIGNAL x_vrz                           : STD_LOGIC;

	SIGNAL yout0, yout1, yout2, yout3      : STD_LOGIC_VECTOR(0 TO 3);
	SIGNAL yout0_int, yout1_int, yout2_int : INTEGER;
	SIGNAL y_vrz                           : STD_LOGIC;

	SIGNAL zout0, zout1, zout2, zout3      : STD_LOGIC_VECTOR(0 TO 3);
	SIGNAL zout0_int, zout1_int, zout2_int : INTEGER;
	SIGNAL z_vrz                           : STD_LOGIC;

BEGIN

	x_vrz <= '1' WHEN x_in < 0 ELSE
		'0';
	x_sig <= x_in WHEN x_in >= 0 ELSE
		- x_in;

	xout0_int <= x_sig - to_integer(unsigned(xout0)) * 1000;
	xout1_int <= xout0_int - to_integer(unsigned(xout1)) * 100;
	xout2_int <= xout1_int - to_integer(unsigned(xout2)) * 10;
	xout3     <= STD_LOGIC_VECTOR(to_unsigned(xout2_int, 4));
	x_out     <= x_vrz & xout0 & xout1 & xout2 & xout3;

	xout0 <= x"9" WHEN x_sig >= 9000 ELSE
		x"8" WHEN x_sig >= 8000 ELSE
		x"7" WHEN x_sig >= 7000 ELSE
		x"6" WHEN x_sig >= 6000 ELSE
		x"5" WHEN x_sig >= 5000 ELSE
		x"4" WHEN x_sig >= 4000 ELSE
		x"3" WHEN x_sig >= 3000 ELSE
		x"2" WHEN x_sig >= 2000 ELSE
		x"1" WHEN x_sig >= 1000 ELSE
		x"0";
	xout1 <= x"9" WHEN xout0_int >= 900 ELSE
		x"8" WHEN xout0_int >= 800 ELSE
		x"7" WHEN xout0_int >= 700 ELSE
		x"6" WHEN xout0_int >= 600 ELSE
		x"5" WHEN xout0_int >= 500 ELSE
		x"4" WHEN xout0_int >= 400 ELSE
		x"3" WHEN xout0_int >= 300 ELSE
		x"2" WHEN xout0_int >= 200 ELSE
		x"1" WHEN xout0_int >= 100 ELSE
		x"0";
	xout2 <= x"9" WHEN xout1_int >= 90 ELSE
		x"8" WHEN xout1_int >= 80 ELSE
		x"7" WHEN xout1_int >= 70 ELSE
		x"6" WHEN xout1_int >= 60 ELSE
		x"5" WHEN xout1_int >= 50 ELSE
		x"4" WHEN xout1_int >= 40 ELSE
		x"3" WHEN xout1_int >= 30 ELSE
		x"2" WHEN xout1_int >= 20 ELSE
		x"1" WHEN xout1_int >= 10 ELSE
		x"0";

	--------- Y ---------

	y_vrz <= '1' WHEN y_in < 0 ELSE
		'0';
	y_sig <= y_in WHEN y_in >= 0 ELSE
		- y_in;

	yout0_int <= y_sig - to_integer(unsigned(yout0)) * 1000;
	yout1_int <= yout0_int - to_integer(unsigned(yout1)) * 100;
	yout2_int <= yout1_int - to_integer(unsigned(yout2)) * 10;
	yout3     <= STD_LOGIC_VECTOR(to_unsigned(yout2_int, 4));
	y_out     <= y_vrz & yout0 & yout1 & yout2 & yout3;

	yout0 <= x"9" WHEN y_sig >= 9000 ELSE
		x"8" WHEN y_sig >= 8000 ELSE
		x"7" WHEN y_sig >= 7000 ELSE
		x"6" WHEN y_sig >= 6000 ELSE
		x"5" WHEN y_sig >= 5000 ELSE
		x"4" WHEN y_sig >= 4000 ELSE
		x"3" WHEN y_sig >= 3000 ELSE
		x"2" WHEN y_sig >= 2000 ELSE
		x"1" WHEN y_sig >= 1000 ELSE
		x"0";
	yout1 <= x"9" WHEN yout0_int >= 900 ELSE
		x"8" WHEN yout0_int >= 800 ELSE
		x"7" WHEN yout0_int >= 700 ELSE
		x"6" WHEN yout0_int >= 600 ELSE
		x"5" WHEN yout0_int >= 500 ELSE
		x"4" WHEN yout0_int >= 400 ELSE
		x"3" WHEN yout0_int >= 300 ELSE
		x"2" WHEN yout0_int >= 200 ELSE
		x"1" WHEN yout0_int >= 100 ELSE
		x"0";
	yout2 <= x"9" WHEN yout1_int >= 90 ELSE
		x"8" WHEN yout1_int >= 80 ELSE
		x"7" WHEN yout1_int >= 70 ELSE
		x"6" WHEN yout1_int >= 60 ELSE
		x"5" WHEN yout1_int >= 50 ELSE
		x"4" WHEN yout1_int >= 40 ELSE
		x"3" WHEN yout1_int >= 30 ELSE
		x"2" WHEN yout1_int >= 20 ELSE
		x"1" WHEN yout1_int >= 10 ELSE
		x"0";

	--------- Z ---------

	z_vrz <= '1' WHEN z_in < 0 ELSE
		'0';
	z_sig <= z_in WHEN z_in >= 0 ELSE
		- z_in;

	zout0_int <= z_sig - to_integer(unsigned(zout0)) * 1000;
	zout1_int <= zout0_int - to_integer(unsigned(zout1)) * 100;
	zout2_int <= zout1_int - to_integer(unsigned(zout2)) * 10;
	zout3     <= STD_LOGIC_VECTOR(to_unsigned(zout2_int, 4));
	z_out     <= z_vrz & zout0 & zout1 & zout2 & zout3;

	zout0 <= x"9" WHEN z_sig >= 9000 ELSE
		x"8" WHEN z_sig >= 8000 ELSE
		x"7" WHEN z_sig >= 7000 ELSE
		x"6" WHEN z_sig >= 6000 ELSE
		x"5" WHEN z_sig >= 5000 ELSE
		x"4" WHEN z_sig >= 4000 ELSE
		x"3" WHEN z_sig >= 3000 ELSE
		x"2" WHEN z_sig >= 2000 ELSE
		x"1" WHEN z_sig >= 1000 ELSE
		x"0";
	zout1 <= x"9" WHEN zout0_int >= 900 ELSE
		x"8" WHEN zout0_int >= 800 ELSE
		x"7" WHEN zout0_int >= 700 ELSE
		x"6" WHEN zout0_int >= 600 ELSE
		x"5" WHEN zout0_int >= 500 ELSE
		x"4" WHEN zout0_int >= 400 ELSE
		x"3" WHEN zout0_int >= 300 ELSE
		x"2" WHEN zout0_int >= 200 ELSE
		x"1" WHEN zout0_int >= 100 ELSE
		x"0";
	zout2 <= x"9" WHEN zout1_int >= 90 ELSE
		x"8" WHEN zout1_int >= 80 ELSE
		x"7" WHEN zout1_int >= 70 ELSE
		x"6" WHEN zout1_int >= 60 ELSE
		x"5" WHEN zout1_int >= 50 ELSE
		x"4" WHEN zout1_int >= 40 ELSE
		x"3" WHEN zout1_int >= 30 ELSE
		x"2" WHEN zout1_int >= 20 ELSE
		x"1" WHEN zout1_int >= 10 ELSE
		x"0";
END ARCHITECTURE behave;
