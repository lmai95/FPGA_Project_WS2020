library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ByteWhiteOutput is
  generic(
    MaxBitPerByteWhiteOutput : integer := 247 --Legt die Anazahl der Bit's fest (inclusive Wert 0..) die ByteWhiteOutput aufeinmal verarbeitet; ->31 ASCII-Zeichen: 3xacc=18 + 3xPunkt + Zeilenumbruch=2 + Leerzeichen=2 + Text=6
  );
  port(
    EN 	  	: in std_logic := '1'; --Enable Signal des ByteWhiteOutput
    Reset 	: in std_logic := '0'; --Reset Signal des ByteWhiteOutput
    Clk   	: in std_logic;        --Clock Signal des ByteWhiteOutput

    ByteWhiteOutputReady : out std_logic := '1';  --Bei '1' bereit die naechste Zeile auszugeben
    ByteWhiteOutputTrigger : in std_logic;        --Startet die Ausgabe duch den Wert '1'
    ByteWhiteOutputBuffer : in std_logic_vector(MaxBitPerByteWhiteOutput downto 0); --Die Daten/Die Zeile die Ausgegebn werden soll

    TX_BUSY : in std_logic := '0';                      --TX_BUSY der UART
    TX_EN 	: out std_logic := '0';                     --TX_EN der UART
    TX_DATA : out std_logic_vector(7 downto 0):= x"00"  --Eingangsbyte der UART; LSB Index 0
  );
 end entity ByteWhiteOutput;


architecture behave of ByteWhiteOutput is
  signal Step : integer RANGE 0 to 4 := 0;      --aktueller Zustand der FSM
  signal NextStep : integer RANGE 0 to 4 := 0;  --naechster Zustand der FSM
  signal CurrentByte : integer RANGE 0 to ((MaxBitPerByteWhiteOutput+1)/8) := 0;  --Zaehlvariable fuer das aktuelle Byte (der Zeile) das ausgegeben wird
  signal iCurrentByte : integer RANGE 0 to ((MaxBitPerByteWhiteOutput+1)/8) := 0;
  signal iTX_EN : std_logic := '0';
  signal iTX_DATA : std_logic_vector(7 downto 0) := x"00";
  signal iByteWhiteOutputReady : std_logic := '1';

BEGIN

  --Byteweise ausgabe einer Textzeile die durch ByteWhiteOutputBuffer uebergeben wird
  --Sobald MaxBitPerByteWhiteOutput oder das Zeichen "\r" in ByteWhiteOutputBuffer erkannt wird stoppt die ausgabe
  --Setzt ByteWhiteOutputReady auf '1' wenn alle Bytes ausgegebn wurden
  ByteWhiteOutput: process(Reset, Clk)
  BEGIN
    IF (Reset = '1') THEN
		iCurrentByte <= 0;
      iTX_EN <= '0';
      iTX_DATA <= x"00";
    ELSIF (rising_edge(Clk)) THEN
		CASE Step IS
			WHEN 0 =>
        --Grundzustand wartet auf ByteWhiteOutputTrigger
				iCurrentByte <= 0;
				iTX_EN <= '0';
				iTX_DATA <= x"00";
				iByteWhiteOutputReady <= '1';
			WHEN 1 =>
        --Uebergibt der UART ein Byte, startet sie durch TX_EN
				iCurrentByte <= CurrentByte;
				iTX_EN <= '1';
				iTX_DATA <= ByteWhiteOutputBuffer( (MaxBitPerByteWhiteOutput-(8*iCurrentByte)) DOWNTO (MaxBitPerByteWhiteOutput-(8*((iCurrentByte+1))-1)) );
				iByteWhiteOutputReady <= '0';
			WHEN 2 =>
        --Wartet bis die UART wieder bereit ist
				iCurrentByte <= CurrentByte;
				iTX_EN <= '0';
				iTX_DATA <= ByteWhiteOutputBuffer( (MaxBitPerByteWhiteOutput-(8*iCurrentByte)) DOWNTO (MaxBitPerByteWhiteOutput-(8*((iCurrentByte+1))-1)) );
				iByteWhiteOutputReady <= '0';
			WHEN 3 =>
        --Bereitet das naechste Byte zur ausgabe vor
				iCurrentByte <= iCurrentByte + 1;
				iTX_EN <= '0';
				iTX_DATA <= x"00";
				iByteWhiteOutputReady <= '0';
			WHEN 4 =>
        --Wartet darauf das ByteWhiteOutputTrigger '0' ist
				iCurrentByte <= 0;
				iTX_EN <= '0';
				iTX_DATA <= x"00";
				iByteWhiteOutputReady <= '0';
		END CASE;
	 END IF;
	END process ByteWhiteOutput;

	ByteWhiteOutputNextState: process(Reset, Clk, EN, Step, ByteWhiteOutputTrigger, TX_BUSY, iCurrentByte, iTX_DATA, ByteWhiteOutputBuffer)
	BEGIN
		IF Reset = '1' THEN
		  NextStep <= 0;
		ELSIF (rising_edge(Clk)) THEN
		  NextStep <= Step;
		  IF (EN = '1') THEN
				CASE Step IS
					WHEN 0 =>
						IF ((ByteWhiteOutputTrigger = '1') AND (TX_BUSY = '0')) THEN NextStep <= 1; END IF;
					WHEN 1 =>
						IF (TX_BUSY = '1') THEN NextStep <= 2; END IF;
					WHEN 2 =>
						IF (TX_BUSY = '0') AND (iCurrentByte < ((MaxBitPerByteWhiteOutput+1)/8)) THEN
							IF (iTX_DATA = x"0D") THEN	  --"\r" erkannt
								NextStep <= 4;
							ELSE
								NextStep <= 3; --Es stehen weitere Daten zur Ausgabe Bereit
							END IF;
						END IF;
						IF (TX_BUSY = '0') AND (iCurrentByte >= ((MaxBitPerByteWhiteOutput+1)/8)) THEN	  	--Alle Daten ausgeben
							NextStep <= 4;
						END IF;
					WHEN 3 =>
						NextStep <= 1;
					WHEN 4 =>
						IF (ByteWhiteOutputTrigger = '0') THEN NextStep <= 0; END IF;
					WHEN OTHERS =>
						NextStep <= 0;
				END CASE;
			END IF;
		END IF;
  END process ByteWhiteOutputNextState;
  Step <= NextStep;
  CurrentByte <= iCurrentByte;
  TX_EN <= iTX_EN;
  TX_DATA <= iTX_DATA;
  ByteWhiteOutputReady <= iByteWhiteOutputReady;
end architecture behave;
