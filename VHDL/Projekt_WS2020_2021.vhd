LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.bitmaps.ALL;

ENTITY Projekt_WS2020_2021 IS
	PORT (
		clk   : IN STD_LOGIC;
		rst   : IN STD_LOGIC;
		
		hsync : OUT STD_LOGIC;
		vsync : OUT STD_LOGIC;
		red   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		blue  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		green : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		
		o_MOSI : OUT STD_LOGIC;
		i_MISO : IN STD_LOGIC;
		o_CLK  : OUT STD_LOGIC;
		o_CS   : OUT STD_LOGIC;
		i_Interrupt : IN STD_LOGIC	
	);
END ENTITY Projekt_WS2020_2021;

ARCHITECTURE behave OF Projekt_WS2020_2021 IS

SIGNAL Accel_X :INTEGER RANGE -32768 TO 32767;
SIGNAL Accel_Y :INTEGER RANGE -32768 TO 32767;
SIGNAL Accel_Z :INTEGER RANGE -32768 TO 32767;
SIGNAL Data_valid :STD_LOGIC;

BEGIN
Sensor : ENTITY work.icm_20948
	PORT MAP(
		i_board_clk => clk,
		o_MOSI => o_MOSI,
		i_MISO => i_MISO,
		o_CLK => o_clk,
		o_CS => o_CS,
		i_Interrupt =>i_interrupt,
		o_Accel_X => Accel_X,		
		o_Accel_Y => Accel_Y,
		o_Accel_Z => Accel_Z,
		o_DV => Data_valid
	);
Display : ENTITY work.VGA 
	PORT MAP(
		clk   => clk,
		rst   => rst,
		hsync => hsync,
		vsync => vsync,
		red   => red,
		blue  => blue,
		green => green, 
		data_valid => Data_valid,
		x_in => Accel_X,
		y_in => Accel_Y,
		z_in => Accel_Z
	);


END ARCHITECTURE behave;
