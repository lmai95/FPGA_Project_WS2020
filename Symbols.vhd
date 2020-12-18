library ieee;
use ieee.std_logic_1164.all;

package Symbols is
type Symbol is array(0 to 9) of std_logic_vector(0 to 4);

--exclamation mark
constant x21: Symbol  :=(
  B"00000",
  B"00100",
  B"00100",
  B"00100",
  B"00100",
  B"00100",
  B"00000",
  B"00100",
  B"00100",
  B"00000"
);
end package Symbols;
