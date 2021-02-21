library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------
--	Tester des ASCII Printers
-- 50MHz Takterzeugung, Erzeugung beliebiger Sensorwerte, beliebige
-- Kombination aus En, Reset und data_valid
--------------------------------------------------------------------
entity AsciiPrinter_tester is
port(
  EN : out std_logic := '1';    --Enable Signal des AsciiPrinters
  Reset : out std_logic := '0'; --Reset Signal des AsciiPrinters
  Clk : out std_logic;

  data_valid : out std_logic;--data valid des Sensor Kontroll-Modul
  acc_x : out integer RANGE -32768 to 32767; 		  	--x-achse des Sensor Kontroll-Modul; in m^2; ToDo Range
  acc_y : out integer RANGE -32768 to 32767; 		  	--y-achse des Sensor Kontroll-Modul; in m^2; ToDo Range
  acc_z : out integer RANGE -32768 to 32767; 		  	--z-achse des Sensor Kontroll-Modul; in m^2; ToDo Range
  TX_BUSY : out std_logic;                           	--TX_Busy der UART
  TX_EN : in std_logic := '0';                       	--TX_EN der UART
  TX_DATA : in std_logic_vector(7 downto 0) := x"00" 	--Eingangsbyte der UART; LSB hat Index 0
);
end entity AsciiPrinter_tester;

architecture test of AsciiPrinter_tester is
  type TestValue is record
    acc_x, acc_y, acc_z : integer RANGE -32768 to 32767;
	end record;
  type TestValueArray is array (natural range <>) of TestValue;	--beliebiger Sensorwerte
	constant TestValues : TestValueArray :=(
	 (-32768, -314, 32767),
	 (19331, 0, -24400)	
  );
  type TestState is record
      EN, Reset, data_valid : std_logic;
  end record;
  type TestStateArray is array (natural range <>) of TestState;	--beliebige Kombination aus En, Reset, data_valid
  constant TestStates : TestStateArray :=(
    --EN, Reset, data_valid
    ('0', '1', '0'),
    ('1', '0', '0'),
    ('1', '0', '1')
  );

  signal iClk : std_logic :='0';												--benötigte Signale setzten
  signal iTX_BUSY : std_logic :='0';
  signal CurrentTestState : integer := 0;
  signal CurrentTestValue : integer := 0;
  signal Clockcount : integer := 0;

BEGIN
  ClockGenerator: PROCESS					--Erzeugt Clk mit 50MHz
  BEGIN
    iClk	<= not iClk;
    IF iCLK = '0' THEN
      Clockcount <= Clockcount + 1;
    end if;
    wait for 10ns;
  end process ClockGenerator;

  --Simuliert die UART mit 115200 Baud; Dauer ~70µS um 8 Bit zu uebertragen
  UartDelay: process(iCLK, TX_EN)
	 variable LastTX_EN	 : std_logic := '0';
    variable counter : integer Range 0 to 70 := 0;
  BEGIN
    IF (rising_edge(iCLK)) THEN
			IF (LastTX_EN = '0') AND (TX_EN = '1') THEN
          counter := 0;
        END IF;
        IF (counter < 30) THEN
          counter := counter + 1;
          iTX_BUSY <= '1';
        ELSE
          iTX_BUSY <= '0';
        END IF;
		 LastTX_EN := TX_EN;
    END IF;
  END process UartDelay;

  --zeitliche Abfolge der oben definierten Parameter
  Testing : PROCESS					
  BEGIN
	for i in 0 to 32 loop
		CurrentTestValue <= 0; 
		CurrentTestState <= 2;
		wait for 100ns;
		CurrentTestState <= 1;
		wait for 100ns;
		CurrentTestState <= 2;
		CurrentTestValue <= 1;
		wait for 100ns;
		CurrentTestState <= 1;
		wait for 100ns;
		end loop;  

  END process Testing;


  Clk <= iClk;
  TX_BUSY <= iTX_BUSY;
  EN <= TestStates(CurrentTestState).EN;
  Reset <= TestStates(CurrentTestState).Reset;
  data_valid <= TestStates(CurrentTestState).data_valid;
  acc_x <= TestValues(CurrentTestValue).acc_x;
  acc_y <= TestValues(CurrentTestValue).acc_y;
  acc_z <= TestValues(CurrentTestValue).acc_z;
end architecture test;
