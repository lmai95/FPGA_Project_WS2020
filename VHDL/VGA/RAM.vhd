LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY graph_RAM IS
   PORT (
      clock               : IN STD_LOGIC;
      data_in             : IN STD_LOGIC_VECTOR (8 DOWNTO 0); --9 Bit Breite Speicherstelle speichert die Y-Possiton des Pixels des Graphen in der x-Position
      data_in_valid       : IN STD_LOGIC;
      horizontal_position : IN INTEGER RANGE 0 TO 650; --X-Position
      data_out            : OUT STD_LOGIC_VECTOR (8 DOWNTO 0)
   );
END graph_RAM;

ARCHITECTURE behave OF graph_RAM IS
   SUBTYPE index_type IS INTEGER RANGE 0 TO 650;
   TYPE mem IS ARRAY(0 TO 650) OF STD_LOGIC_VECTOR(8 DOWNTO 0);
   SIGNAL ram_block : mem := (OTHERS => B"0_1100_1000");

   FUNCTION add_n_wrap(index : index_type; i : INTEGER) RETURN index_type IS
      VARIABLE x : INTEGER;
   BEGIN
      x := index + i;
         IF x > index_type'high THEN
            RETURN x - index_type'high;
         ELSE
            RETURN index + i;
      END IF;
   END FUNCTION;

BEGIN
PROCESS (clock)
   VARIABLE read_address  : index_type := 0;
   VARIABLE write_address : index_type := 0;
   BEGIN
   IF rising_edge(clock) THEN
      read_address := add_n_wrap(write_address, horizontal_position);
   IF (data_in_valid = '1') THEN
         ram_block(write_address) <= data_in;
      write_address := add_n_wrap(write_address, 1);
      END IF;
      data_out <= ram_block(read_address);
      END IF;
   END PROCESS;
END behave;
