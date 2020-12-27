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
  signal acc_x : integer RANGE 0 to 65536;
  signal acc_y : integer RANGE 0 to 65536;
  signal acc_z : integer RANGE 0 to 65536;
  signal TX_BUSY : std_logic;
  signal TX_EN : std_logic;
  signal TX_DATA : std_logic_vector(7 downto 0);
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

  DUT: entity work.AsciiPrinter(behave)
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
    TX_DATA => TX_DATA
    );
end architecture behave;
