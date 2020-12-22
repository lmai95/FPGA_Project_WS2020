library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.BufferData.all;

entity ByteWhiteOutput is
  generic(
    MaxBitPerByteWhiteOutput : integer := 223   --Legt die maximale Zeilenlaenge in Bit fest; 28 ASCII-Zeichen: 3xacc=18 + Zeilenumbruch=2 + Leerzeichen=2 + Text=6
  );
  port(
    EN 	  	: in std_logic := '1'; --Enable Signal des ByteWhiteOutput
    Reset 	: in std_logic := '0'; --Reset Signal des ByteWhiteOutput
    Clk   	: in std_logic;
    ByteWhiteOutputReady : out std_logic;
    ByteWhiteOutputTrigger : in std_logic;
    ByteWhiteOutputBuffer : in std_logic_vector(MaxBitPerByteWhiteOutput downto 0);
    TX_BUSY : in std_logic := '0';
    TX_EN 	: out std_logic := '0';                     --TX_EN der UART
    TX_DATA : out std_logic_vector(7 downto 0):= x"00"  --Eingangsbyte der UART; LSB hat Index 0
  );
 end entity ByteWhiteOutput;


architecture behave of ByteWhiteOutput is
  signal ByteWhiteOutputReset : std_logic := '0';
  signal ByteWhiteOutputTaskCompleted : std_logic := '0';
  signal ByteWhiteOutputActiv : std_logic := '0';
  signal UartNotEnable : std_logic := '0';
  signal iTX_EN : std_logic := '0';                                                                     --internes Signal fuer den Ausgang TX_EN
  signal iTX_DATA : std_logic_vector(7 downto 0) := x"00";
  signal iTX_DATA_Last : std_logic_vector(7 downto 0) := x"00";
  signal CurrentByte : integer RANGE 0 to 29 := 0; --Maximal 224 Bit pro Zeile
  signal iCurrentByte : integer RANGE 0 to 29 := 0; --Maximal 224 Bit pro Zeile
  signal iByteWhiteOutputReady : std_logic := '1';
BEGIN
  ByteWhiteOutputReset <= ByteWhiteOutputTaskCompleted or Reset;
  SwitchByteWhiteOutput: entity work.xDDF(behave)
  port map(
    D => ByteWhiteOutputTrigger,
    EN => '1',
    Reset => ByteWhiteOutputReset,
    Clk => Clk,
    Q => ByteWhiteOutputActiv
  );
  UartNotEnable <= NOT(TX_BUSY) or Reset;
  EnableUART: entity work.xDDF(behave)
  port map(
    D => iTX_EN,
    EN => '1',
    Reset => UartNotEnable,
    Clk => Clk,
    Q => TX_EN
  );
  ByteWhiteOutputState: process(Reset, Clk)
  BEGIN
	IF (rising_edge(Clk)) THEN
		IF((ByteWhiteOutputTaskCompleted  = '1') OR (Reset = '1')) THEN
			iByteWhiteOutputReady <= '1';
		END IF;
		IF (ByteWhiteOutputTrigger = '1') THEN
			iByteWhiteOutputReady <= '0';
		END IF;
	END IF;
  end process ByteWhiteOutputState;

  --ToDo mit clock synchronisieren
  --Gibt die Bytes aus ByteWhiteOutputBuffer einzel an die UART aus, wenn OutputActiv '1' und EN '1' ist
  --Sobald das Zeichen '\r' in ByteWhiteOutputBuffer erkannt wird stoppt die ausgabe
  --Setzt ByteWhiteOutputReady auf '1' wenn alle Bytes ausgegebn wurden
  ByteWhiteOutput: process(Reset, EN, Clk, ByteWhiteOutputActiv, TX_BUSY, iCurrentByte, iTX_DATA)
  BEGIN
    IF (Reset = '1') THEN
      iCurrentByte <= 0;
      ByteWhiteOutputTaskCompleted <= '1';
      iTX_EN <= '0';
      iTX_DATA <= x"00";
    ELSIF (rising_edge(Clk)) THEN
      iTX_EN <= '0';
      iTX_DATA <= iTX_DATA_Last;
      iCurrentByte <= CurrentByte;
		ByteWhiteOutputTaskCompleted <= '0';
      IF ((EN = '1') AND (ByteWhiteOutputActiv = '1') AND (TX_BUSY = '0')) THEN
        IF ((iCurrentByte >= 28) OR (iTX_DATA = x"0D")) THEN
          --Alle Bytes uebertragen
          iCurrentByte <= 0;
			 iTX_DATA <= x"00";
          ByteWhiteOutputTaskCompleted <= '1';
        ELSE
          --Uebertraegt ein Byte
          iTX_DATA <= ByteWhiteOutputBuffer( (MaxBitPerByteWhiteOutput-(8*iCurrentByte)) DOWNTO (MaxBitPerByteWhiteOutput-(8*((iCurrentByte+1))-1)) );
          iTX_EN <= '1';
          iCurrentByte <= iCurrentByte + 1;
        END IF;
      END IF;
    END IF;
  END process ByteWhiteOutput;
  CurrentByte <= iCurrentByte;
  iTX_DATA_Last <= iTX_DATA;

  ByteWhiteOutputReady <= iByteWhiteOutputReady;
  TX_DATA <= iTX_DATA;
end architecture behave;
