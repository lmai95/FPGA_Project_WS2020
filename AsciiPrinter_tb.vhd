library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AsciiPrinter_tb is
end entity AsciiPrinter_tb;

architecture behave of AsciiPrinter_tb is
  signal EN : std_logic;
  signal Reset : std_logic;
  signal Clk : std_logic;
  signal data_valid : std_logic;
  signal acc_x : integer RANGE -32768 to 32767;
  signal acc_y : integer RANGE -32768 to 32767;
  signal acc_z : integer RANGE -32768 to 32767;
  signal TX_BUSY : std_logic;
  signal TX_EN : std_logic;
  signal TX_DATA : std_logic_vector(7 downto 0);
  signal data_valid_in : std_logic := '0';	              --Ausgabe von data valid an das VGA-Modl
  signal x_in : integer range -9999 to 9999 := 0;        --Ausgabe der Beschleunigung der x-achse in cm/s^2 an das VGA-Modul
  signal	y_in : integer range -9999 to 9999 := 0;        --Ausgabe der Beschleunigung der y-achse in cm/s^2 an das VGA-Modul
  signal	z_in : integer range -9999 to 9999 := 0;         --Ausgabe de
BEGIN
  Tester: entity work.AsciiPrinter_tester(test)
    port map(
      EN => EN,
      Reset => Reset,
      Clk => Clk,
      data_valid => data_valid,
      acc_x => acc_x,
      acc_y => acc_y,
      acc_z => acc_z,
      TX_BUSY => TX_BUSY,
      TX_EN => TX_EN,
      TX_DATA => TX_DATA
    );

  DUT: entity work.signal_processing(behave)
    generic map(
      FreeRunning => '0'
    )
    port map(
    EN => EN,
    Reset => Reset,
    Clk => Clk,
    data_valid => data_valid,
    acc_x => acc_x,
    acc_y => acc_y,
    acc_z => acc_z,
    TX_BUSY => TX_BUSY,
    TX_EN => TX_EN,
    TX_DATA => TX_DATA,
	 data_valid_in => data_valid_in,
	 x_in => x_in,										
	 y_in => y_in,									
	 z_in => z_in	
    );
end architecture behave;
