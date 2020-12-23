library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.BufferData.all;

entity AsciiPrinter is
generic(
  BufferSize : integer := 9;                  --Legt die groesse der beiden Buffer fest
  MaxBitPerByteWhiteOutput : integer := 47   --Legt die maximale Zeilenlaenge in Bit fest; 28 ASCII-Zeichen: 3xacc=18 + Zeilenumbruch=2 + Leerzeichen=2 + Text=6
);
port(
  EN 	  	: in std_logic := '1';    --Enable Signal des AsciiPrinters
  Reset 	: in std_logic := '0'; --Reset Signal des AsciiPrinters
  Clk   	: in std_logic;

  data_valid : in std_logic;--data valid des Sensor Kontroll-Modul
  acc_x 		 : in integer; 		  --x-achse des Sensor Kontroll-Modul; in m^2; ToDo Range
  acc_y 		 : in integer; 		  --y-achse des Sensor Kontroll-Modul; in m^2; ToDo Range
  acc_z 		 : in integer; 		  --z-achse des Sensor Kontroll-Modul; in m^2; ToDo Range
  TX_BUSY 	 : in std_logic;                             --TX_Busy der UART
  TX_EN 		 : out std_logic := '0';                       --TX_EN der UART
  TX_DATA 	 : out std_logic_vector(7 downto 0):= x"00"  --Eingangsbyte der UART; LSB hat Index 0
);
end entity AsciiPrinter;


architecture behave of AsciiPrinter is
  signal FiFo : DataSampleBuffer(BufferSize downto 0);            		--Buffer1 zum zwischenspeichern der eingehenden Daten
  signal TextGeneratorReady : std_logic := '1';     --Bei '1' PrepareNextLine kann den Inhalt des naechstens Buffers uebertragen
  signal TextGeneratorTrigger : std_logic := '0';     --Wenn '0' kein Buffer wird ausgegeben, wenn '1' ein Buffer wird ausgegebn
  signal ByteWhiteOutputReady : std_logic := '1';
  signal ByteWhiteOutputTrigger : std_logic := '0';
  signal ByteWhiteOutputBuffer : std_logic_vector(MaxBitPerByteWhiteOutput downto 0) := (others =>'0'); --Speicher fuer die Ausgabe der naechsten Zeile; 28 ASCII-Zeichen: 3xacc=18 + Zeilenumbruch=2 + Leerzeichen=2 + Text=6
BEGIN
  Aggregator: entity work.DataCollector(behave)
  generic map(
    BufferSize => BufferSize
  )
  port map(
    EN => EN,
    Reset => Reset,
    Clk => Clk,
    data_valid => data_valid,
    acc_x => acc_x,
    acc_y => acc_y,
    acc_z => acc_z,
    TextGeneratorReady => TextGeneratorReady,
    TextGeneratorTrigger => TextGeneratorTrigger,
    FiFo => FiFo
  );

  AsciiGenerator: entity work.TextGenerator(behave)
  generic map(
    BufferSize => BufferSize,
    MaxBitPerByteWhiteOutput => MaxBitPerByteWhiteOutput
  )
  port map(
    EN => EN,
    Reset => Reset,
    Clk => Clk,
    TextGeneratorReady => TextGeneratorReady,
    TextGeneratorTrigger => TextGeneratorTrigger,
    FiFo => FiFo,
    ByteWhiteOutputReady => ByteWhiteOutputReady,
    ByteWhiteOutputTrigger => ByteWhiteOutputTrigger,
    ByteWhiteOutputBuffer => ByteWhiteOutputBuffer
  );

  ByteOutput: entity work.ByteWhiteOutput(behave)
  generic map(
    MaxBitPerByteWhiteOutput => MaxBitPerByteWhiteOutput
  )
  port map(
    EN => EN,
    Reset => Reset,
    Clk => Clk,
    ByteWhiteOutputReady => ByteWhiteOutputReady,
    ByteWhiteOutputTrigger => ByteWhiteOutputTrigger,
    ByteWhiteOutputBuffer => ByteWhiteOutputBuffer,
    TX_BUSY => TX_BUSY,
    TX_EN => TX_EN,
    TX_DATA => TX_DATA
  );
end behave;
