library ieee;
use ieee.std_logic_1164.all;

package BufferData is
  type DataSample is record
    acc_x, acc_y, acc_z : integer RANGE 0 to 65536;--ToDo: Eigentlich ist ein kleinere Wertbereich aussreichend
  end record;
  type DataSampleBuffer is array (natural  RANGE <>) of DataSample;

end package BufferData;
