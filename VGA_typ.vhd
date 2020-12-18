library ieee;
use ieee.std_logic_1164.all;

package LM_VGA is
  subtype R4G4B4 is std_logic_vector(11 downto 0);

  type sync_signals is (visible, front_porch, sync, back_porch);

  type position is record
      X : integer range 0 to 1040;
      Y : integer range 0 to 666;
  end record position;
  
  constant OO : Position :=(X => 0, Y => 0);
  constant black : R4G4B4 := x"0_0_0";
  constant grey : R4G4B4 := x"8_8_8";
  constant white : R4G4B4 := x"0_0_0";
end package LM_VGA;
