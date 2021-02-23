LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.bitmaps.ALL;
ENTITY graph IS
   GENERIC
   (
      x_color : STD_LOGIC_VECTOR(11 DOWNTO 0) := x"F00";
      y_color : STD_LOGIC_VECTOR(11 DOWNTO 0) := x"0F0";
      z_color : STD_LOGIC_VECTOR(11 DOWNTO 0) := x"0FF"
   );
   PORT (
      CLK                 : IN STD_LOGIC;
      horizontal_position : IN INTEGER;
      vertical_position   : IN INTEGER;
      value_X             : IN INTEGER RANGE -32768 TO 32767;
      value_Y             : IN INTEGER RANGE -32768 TO 32767;
      value_Z             : IN INTEGER RANGE -32768 TO 32767;
      data_Valid          : IN STD_LOGIC;
      RGB_Wert            : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
   );
END graph;

ARCHITECTURE rtl OF graph IS
   FUNCTION V_to_INT(INPUT : STD_LOGIC_VECTOR (8 DOWNTO 0)) RETURN INTEGER IS
   BEGIN
      RETURN to_integer(unsigned(INPUT));
   END FUNCTION;
   SIGNAL drawable   : BOOLEAN;
   SIGNAL graph_area : BOOLEAN;
   SIGNAL scaled_x   : STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL data_Valid_x    : STD_LOGIC;
   SIGNAL x_hight_v  : STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL scaled_y   : STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL data_Valid_y    : STD_LOGIC;
   SIGNAL y_hight_v  : STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL scaled_z   : STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL data_Valid_z    : STD_LOGIC;
   SIGNAL z_hight_v  : STD_LOGIC_VECTOR(8 DOWNTO 0);
BEGIN

   x_scaling : work.scaling
   PORT MAP(
      clk              => CLK,
      data_valid => data_Valid,
      in_value         => value_X,
      out_scaled_value => scaled_x,
      out_valid => data_Valid_x
   );

   y_scaling : work.scaling
   PORT MAP(
      clk              => CLK,
      data_valid => data_Valid,
      in_value         => value_y,
      out_scaled_value => scaled_y,
      out_valid => data_Valid_y
   );

   z_scaling : work.scaling
   PORT MAP(
      clk              => CLK,
      data_valid => data_Valid,
      in_value         => value_z,
      out_scaled_value => scaled_z,
      out_valid => data_Valid_z
   );

   ram_x_graph : work.graph_RAM
   PORT MAP(
      clock               => CLK,
      data_in             => scaled_x,
      data_in_valid       => data_Valid_x,
      horizontal_position => horizontal_position,
      data_out            => x_hight_v
   );
   ram_y_graph : work.graph_RAM
   PORT MAP(
      clock               => CLK,
      data_in             => scaled_y,
      data_in_valid       => data_Valid_y,
      horizontal_position => horizontal_position,
      data_out            => y_hight_v
   );
   ram_z_graph : work.graph_RAM
   PORT MAP(
      clock               => CLK,
      data_in             => scaled_z,
      data_in_valid       => data_Valid_z,
      horizontal_position => horizontal_position,
      data_out            => z_hight_v
   );

   drawable   <= (horizontal_position < 639 AND vertical_position < 479);
   graph_area <= (horizontal_position > 10 AND horizontal_position < 630 AND vertical_position > 110 AND vertical_position < 460);

   Darstellung : PROCESS (clk, horizontal_position, vertical_position)
      VARIABLE RGB_sig : STD_LOGIC_VECTOR(11 DOWNTO 0);
   BEGIN
      IF rising_edge(clk) THEN
         RGB_sig := x"000";
         IF drawable THEN
            --Y - Achse
            RGB_sig := print_any_line(horizontal_position, 10, 10, vertical_position, 110, 460, RGB_sig, x"FFF");
            RGB_sig := print_bitmap(horizontal_position, 6, vertical_position, 110, zero, arrow, RGB_sig, x"FFF", x"000");
            RGB_sig := print_bitmap(horizontal_position, 16, vertical_position, 110, zero, a, RGB_sig, x"FFF", x"000");
            --X - Achse
            RGB_sig := print_any_line(horizontal_position, 10, 625, vertical_position, 285, 285, RGB_sig, x"FFF");
            RGB_sig := print_bitmap(horizontal_position, 624, vertical_position, 281, ninety, arrow, RGB_sig, x"FFF", x"000");
            RGB_sig := print_bitmap(horizontal_position, 625, vertical_position, 290, zero, t, RGB_sig, x"FFF", x"000");
            --Borderline
            RGB_sig := print_any_line(horizontal_position, 1, 1, vertical_position, 0, 480, RGB_sig, x"555");
            RGB_sig := print_any_line(horizontal_position, 638, 638, vertical_position, 0, 480, RGB_sig, x"555");
            RGB_sig := print_any_line(horizontal_position, 0, 638, vertical_position, 478, 478, RGB_sig, x"555");
            RGB_sig := print_any_line(horizontal_position, 0, 638, vertical_position, 2, 2, RGB_sig, x"555");
            IF graph_area THEN
               IF V_to_INT(x_hight_v) = vertical_position THEN
                  RGB_sig := x_color;
               ELSIF (V_to_INT(y_hight_v) = vertical_position) THEN
                  RGB_sig := y_color;
               ELSIF (V_to_INT(z_hight_v) = vertical_position) THEN
                  RGB_sig := z_color;
               END IF;
            END IF;
         END IF;
      END IF;
      RGB_Wert <= RGB_sig;
   END PROCESS;

END rtl;
