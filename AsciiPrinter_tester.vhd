library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AsciiPrinter_tester is
port(
  EN : out std_logic := '1';    --Enable Signal des AsciiPrinters
  Reset : out std_logic := '0'; --Reset Signal des AsciiPrinters
  Clk : out std_logic;

  data_valid : out std_logic;--data valid des Sensor Kontroll-Modul
  acc_x : out integer; 		  --x-achse des Sensor Kontroll-Modul; in m^2; ToDo Range
  acc_y : out integer; 		  --y-achse des Sensor Kontroll-Modul; in m^2; ToDo Range
  acc_z : out integer; 		  --z-achse des Sensor Kontroll-Modul; in m^2; ToDo Range
  TX_BUSY : out std_logic;                           --TX_Busy der UART
  TX_EN : in std_logic := '0';                       --TX_EN der UART
  TX_DATA : in std_logic_vector(7 downto 0) := x"00"  --Eingangsbyte der UART; LSB hat Index 0
);
end entity AsciiPrinter_tester;

architecture test of AsciiPrinter_tester is
  type TestValue is record
    acc_x, acc_y, acc_z : integer RANGE 0 to 65536;
	end record;
  type TestValueArray is array (natural range <>) of TestValue;
	constant TestValues : TestValueArray :=(
    (1, 1, 1),
    (2, 1, 1),
    (3, 2, 1),
    (4, 3, 2)
  );
  type TestState is record
      EN, Reset, data_valid : std_logic;
  end record;
  type TestStateArray is array (natural range <>) of TestState;
  constant TestStates : TestStateArray :=(
    --EN, Reset, data_valid
    ('0', '1', '0'),
    ('1', '0', '0'),
    ('1', '0', '1')
  );

  signal iClk : std_logic :='0';
  signal iTX_BUSY : std_logic :='0';
  signal CurrentTestState : integer := 0;
  signal CurrentTestValue : integer := 0;
  signal Clockcount : integer := 0;

BEGIN
  --Erzeugt Clk mit 1MHz
  ClockGenerator: PROCESS
  BEGIN
    iClk	<= not iClk;
    IF iCLK = '0' THEN
      Clockcount <= Clockcount + 1;
    end if;
    wait for 500ns;
  end process ClockGenerator;

  --Simuliert die UART mit 115200 Baud; Dauer ~70µS um 8 Bit zu uebertragen
  UartDelay: process(iCLK)
    variable LastTX_DATA : std_logic_vector(7 downto 0) := x"00";
    variable counter : integer Range 0 to 70 := 70;
  BEGIN
    IF (rising_edge(iCLK)) THEN
      IF (TX_EN = '1') THEN
        IF (counter /= 70) THEN
          counter := counter + 1;
          iTX_BUSY <= '1';
        ELSE
          iTX_BUSY <= '0';
        END IF;
        IF (LastTX_DATA /= TX_DATA) THEN
          counter := 0;
          LastTX_DATA := TX_DATA;
        END IF;
      END IF;
    END IF;
  END process UartDelay;

  Testing : PROCESS
  BEGIN
    IF (Clockcount <= 5) THEN CurrentTestState<=0; CurrentTestValue<=0;
    ELSIF (Clockcount <= 9) THEN CurrentTestState<=1; CurrentTestValue<=0;
    ELSIF (Clockcount <= 10) THEN CurrentTestState<=2; CurrentTestValue<=0;--neue Daten
    ELSIF (Clockcount <= 20) THEN CurrentTestState<=1; CurrentTestValue<=0;
    ELSIF (Clockcount <= 21) THEN CurrentTestState<=2; CurrentTestValue<=1;--neue Daten
    ELSIF (Clockcount <= 31) THEN CurrentTestState<=1; CurrentTestValue<=1;
    ELSIF (Clockcount <= 32) THEN CurrentTestState<=2; CurrentTestValue<=2;--neue Daten
    ELSIF (Clockcount <= 42) THEN CurrentTestState<=1; CurrentTestValue<=2;
    ELSIF (Clockcount <= 43) THEN CurrentTestState<=2; CurrentTestValue<=3;--neue Daten
    ELSIF (Clockcount <= 54) THEN CurrentTestState<=1; CurrentTestValue<=3;
    ELSIF (Clockcount <= 55) THEN CurrentTestState<=2; CurrentTestValue<=1;--neu Daten
    ELSE CurrentTestState<=2; CurrentTestValue<=1;
    END IF;
    wait for 1000ns;
  END process Testing;


  Clk <= iClk;
  iTX_BUSY <= iTX_BUSY;
  EN <= TestStates(CurrentTestState).EN;
  Reset <= TestStates(CurrentTestState).Reset;
  data_valid <= TestStates(CurrentTestState).data_valid;
  acc_x <= TestValues(CurrentTestValue).acc_x;
  acc_y <= TestValues(CurrentTestValue).acc_y;
  acc_z <= TestValues(CurrentTestValue).acc_z;
end architecture test;
