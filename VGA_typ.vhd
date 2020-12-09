library ieee;
use ieee.std_logic_1164.all;

package LM_VGA is
  type color is record
    R, G, B : std_logic_vector(3 downto 0);
  end record;
  
  type Position is record
    X , Y : integer;
  end record;
  
  type gfx_buffer is array (0 to 799, 0 to 599) of Color;
	 
  constant OO : Position :=(X => 0, Y => 0);
  constant black : color :=(R => x"0",G => x"0",B => x"0");
  constant white : color :=(R => x"F",G => x"F",B => x"F");
end package LM_VGA;
