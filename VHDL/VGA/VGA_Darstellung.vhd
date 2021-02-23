LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.bitmaps.ALL;
ENTITY VGA_Darstellung IS
  GENERIC
  (
    CONSTANT hpos_total : INTEGER;
    CONSTANT vpos_total : INTEGER
  );
  PORT (
    clk       : IN STD_LOGIC;
    rst       : IN STD_LOGIC;
    screen_on : IN STD_LOGIC;
    hpos      : IN INTEGER RANGE 0 TO hpos_total;
    vpos      : IN INTEGER RANGE 0 TO vpos_total;
	 data_valid : IN STD_LOGIC;
    x_int     : IN INTEGER RANGE -32768 TO 32767;
    y_int     : IN INTEGER RANGE -32768 TO 32767;
    z_int     : IN INTEGER RANGE -32768 TO 32767;
    rgb       : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
  );
END ENTITY VGA_Darstellung;

ARCHITECTURE behave OF VGA_Darstellung IS
  SIGNAL rgb_graph   : STD_LOGIC_VECTOR(11 DOWNTO 0);
  SIGNAL rgb_numbers : STD_LOGIC_VECTOR(11 DOWNTO 0);

BEGIN

  Diagramm : ENTITY work.graph
  PORT MAP(
    CLK                 => clk,
    horizontal_position => hpos,
    vertical_position   => vpos,
    value_X             => x_int,
    value_Y             => y_int,
    value_Z             => z_int,
    data_Valid          => data_valid,
    RGB_Wert            => rgb_graph
  );

  numbers : ENTITY work.alphanumeric_display
  PORT MAP(
    CLK      => clk,
    rst      => rst,
    hpos     => hpos,
    vpos     => vpos,
    x_int    => x_int,
    y_int    => y_int,
    z_int    => z_int,
    RGB_Wert => rgb_numbers
  );
  rgb <= rgb_graph OR rgb_numbers;
END ARCHITECTURE behave;
