library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.BufferData.all;

entity AsciiPrinter is
	generic(
		FreeRunning : std_logic := '0';	--Bei '1' FreeRunning-Mode: Daten die nicht verarbeitet werden koennen werden verworfen die Datenerfassung wird natlos fortgesetzt
													--Bei '0' Sampling-Mode: Sobald ein Datensatz nicht erfasst werden kann stoppt die Datenerfassung bis die FiFo ausgegbe wurde, PrintRejectedData wird auf '1' gesetzt, die Datenerfassung wird fortgesetzt
		MaxBitPerByteWhiteOutput : integer := 223 --Legt die Anazahl der Bit's fest (inclusive Wert 0..) die ByteWhiteOutput aufeinmal verarbeitet; ->28 ASCII-Zeichen: 3xacc=18 + Zeilenumbruch=2 + Leerzeichen=2 + Text=6
	);
	port(
		EN 	  	: in std_logic := '1';    --Enable Signal des AsciiPrinters
		Reset 	: in std_logic := '0'; --Reset Signal des AsciiPrinters
		Clk   	: in std_logic;

		data_valid : in std_logic;						--data valid des Sensor Kontroll-Modul
		acc_x 		 : in integer RANGE 0 to 65536; 	--x-achse des Sensor Kontroll-Modul; in m^2
		acc_y 		 : in integer RANGE 0 to 65536; 	--y-achse des Sensor Kontroll-Modul; in m^2
		acc_z 		 : in integer RANGE 0 to 65536; 	--z-achse des Sensor Kontroll-Modul; in m^2
		
		TX_BUSY 	 : in std_logic;                            --TX_Busy der UART
		TX_EN 		 : out std_logic := '0';                 --TX_EN der UART
		TX_DATA 	 : out std_logic_vector(7 downto 0):= x"00" --Eingangsbyte der UART; LSB hat Index 0
	);
end entity AsciiPrinter;


architecture behave of AsciiPrinter is
  signal FiFoData : STD_LOGIC_VECTOR (47 DOWNTO 0) := (others => '0');
  signal FiFoEmpty : std_logic := '1';
  signal FiFoFull : std_logic := '0';
  signal FiFoWrreq : std_logic := '0';
  signal FiFoRdreq : std_logic := '0';
  signal FiFoQ : STD_LOGIC_VECTOR (47 DOWNTO 0) := (others => '0');
  signal PrintRejectedData : std_logic := '0';
  signal RejectedData : integer RANGE 0 to 65536 := 0;
  signal ByteWhiteOutputReady : std_logic := '1';
  signal ByteWhiteOutputTrigger : std_logic := '0';
  signal ByteWhiteOutputBuffer : std_logic_vector(MaxBitPerByteWhiteOutput downto 0) := (others =>'0'); --Speicher fuer die Ausgabe der naechsten Zeile; 28 ASCII-Zeichen: 3xacc=18 + Zeilenumbruch=2 + Leerzeichen=2 + Text=6
BEGIN
  Aggregator: entity work.DataCollector(behave)
  generic map(
    FreeRunning => FreeRunning
  )
  port map(
    EN => EN,
    Reset => Reset,
    Clk => Clk,
    data_valid => data_valid,
    acc_x => acc_x,
    acc_y => acc_y,
    acc_z => acc_z,
    FiFoEmpty => FiFoEmpty,
	 FiFoFull => FiFoFull,
	 FiFoWrreq => FiFoWrreq,
    FiFoData => FiFoData,
    PrintRejectedData => PrintRejectedData,
	 RejectedData => RejectedData
  );

  FiFo: entity work.FiFo48(SYN)
  port map(
	aclr => Reset,
	clock => Clk,
	data => FiFoData,
	rdreq => FiFoRdreq,
	wrreq => FiFoWrreq,
	empty	=> FiFoEmpty,
	full => FiFoFull,
	q => FiFoQ
  );
  
  AsciiGenerator: entity work.TextGenerator(behave)
  generic map(
    MaxBitPerByteWhiteOutput => MaxBitPerByteWhiteOutput
  )
  port map(
    EN => EN,
    Reset => Reset,
    Clk => Clk,
    FiFoEmpty => FiFoEmpty,
	 FiFoRdreq => FiFoRdreq,
    DataFromFiFo => FiFoQ,
	 PrintRejectedData => PrintRejectedData,
    RejectedData => RejectedData,
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
