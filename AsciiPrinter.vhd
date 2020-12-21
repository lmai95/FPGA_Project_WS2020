library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AsciiPrinter is
generic(
  BufferSize : integer := 9;                  --Legt die groesse der beiden Buffer fest
  MaxBitPerByteWhiteOutput : integer := 223   --Legt die maximale Zeilenlaenge in Bit fest; 28 ASCII-Zeichen: 3xacc=18 + Zeilenumbruch=2 + Leerzeichen=2 + Text=6
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
  type DataSample is record
    acc_x, acc_y, acc_z : integer RANGE 0 to 65536;--ToDo: Eigentlich ist ein kleinere Wertbereich aussreichend
  end record;
  type DataSampleBuffer is array (BufferSize downto 0) of DataSample;

  signal IntToLogicVectorReady 		: std_logic := '0';
  signal IntToLogicVectorIntInput 	: integer RANGE 0 to 65536;--ToDo: Eigentlich ist ein kleinere Wertbereich aussreichend
  signal IntToLogicVectorBinOutput 	: std_logic_vector(47 downto 0) := (others =>'0');

  signal SumRejectedDataFiFo1 : integer := 0;		--Zaehler fuer die Anzahl der nicht verarbeitbaren Messungen waehrend Daten in FiFo1 geasammelt wurden
  signal SumRejectedDataFiFo2 : integer := 0;		--Zaehler fuer die Anzahl der nicht verarbeitbaren Messungen waehrend Daten in FiFo2 geasammelt wurden
  signal FiFo1 : DataSampleBuffer;            		--Buffer1 zum zwischenspeichern der eingehenden Daten
  signal FiFo2 : DataSampleBuffer;              	--Buffer2 zum zwischenspeichern der eingehenden Daten
  signal PrepareNextLineActivSet : std_logic := '0';
  signal PrepareNextLineActivReset1 : std_logic := '0';

  signal PrepareNextLineActivReset2 : std_logic := '0';
  signal PrepareNextLineActiv : std_logic := '0';     --Wenn '0' kein Buffer wird ausgegeben, wenn '1' ein Buffer wird ausgegebn
  signal PrepareNextLineReady : std_logic := '1';     --Bei '1' PrepareNextLine kann den Inhalt des naechstens Buffers uebertragen
  signal PrepareNextLineSelectFiFo1 : boolean := true;--true: Prozess PrepareNextLine nutzt FiFo1, false: PrepareNextLine nutzt FiFo2
  signal OutputActivSet : std_logic := '0';
  signal OutputActivReset1 : std_logic := '0';

  signal OutputActivReset2 : std_logic := '0';
  signal OutputActiv : std_logic := '0';                                                                --Wenn '0' keine ausgabe an UART, wenn '1' ausgabe an UART
  signal ByteWhiteOutputBuffer : std_logic_vector(MaxBitPerByteWhiteOutput downto 0) := (others =>'0'); --Speicher fuer die Ausgabe der naechsten Zeile; 28 ASCII-Zeichen: 3xacc=18 + Zeilenumbruch=2 + Leerzeichen=2 + Text=6
  signal ByteWhiteOutputReady : std_logic := '1';                                                       --Bei '1' Prozess ByteWhiteOutput kann neue Daten Uebertragen
  signal iTX_EN : std_logic := '0';                                                                     --internes Signal fuer den Ausgang TX_EN
  signal iTX_DATA : std_logic_vector(7 downto 0) := x"00";                                              --internes Signal fuer den Ausgang TX_DATA

  signal StepPrepareNextLine : integer Range 0 to 3 := 0;
  
BEGIN
  --Wandelt eine signed Integer Zahl in ASCI Zeichen um. Annahme 16Bit integer daher mit Vorzeichen 6-ASCI Zeichen
  IntToLogicVector: process(Clk,Reset)
    variable Step : integer RANGE 0 to 9 := 0;
    variable uint_input : integer RANGE 0 to 65536;--ToDo: Eigentlich ist ein kleinere Wertbereich aussreichend
    variable Digit : integer RANGE 0 to 9 := 0;
	 variable Cutout : std_logic_vector(7 DOWNTO 0);
  BEGIN
    IF (Reset = '1') THEN
      Step := 0;
    ELSIF (rising_edge(Clk)) THEN
      IntToLogicVectorReady <= '0';
      IF (Step = 0) THEN
        IF (uint_input /= IntToLogicVectorIntInput) THEN
          Step := 1;
        END IF;
      ELSIF (Step = 1) THEN
        --Ergaenzt das Vorzeichen und erzeugt den absolut Wert
        IF (IntToLogicVectorIntInput < 0) THEN
          IntToLogicVectorBinOutput(47 downto 40) <= B"00101101"; --Text: "-"
          uint_input := IntToLogicVectorIntInput*(-1);
        ELSE
          IntToLogicVectorBinOutput(47 downto 40) <= B"00101011"; --Text: "+"
          uint_input := IntToLogicVectorIntInput;
        END IF;
        Step := 2;
      ELSIF ((Step >= 2) AND (Step <= 6)) THEN
        Digit := IntToLogicVectorIntInput mod 10;
        uint_input := uint_input/10;
        Case Digit is
          WHEN 0 => Cutout := B"00110000";
          WHEN 1 => Cutout := B"00110001";
          WHEN 2 => Cutout := B"00110010";
          WHEN 3 => Cutout := B"00110011";
          WHEN 4 => Cutout := B"00110100";
          WHEN 5 => Cutout := B"00110101";
          WHEN 6 => Cutout := B"00110110";
          WHEN 7 => Cutout := B"00110111";
          WHEN 8 => Cutout := B"00111000";
          WHEN 9 => Cutout := B"00111001";
          WHEN OTHERS => Cutout := B"00111111";--Text "?"
        END CASE;
			 IntToLogicVectorBinOutput((47-((7-Step)*8)) DOWNTO (48-(8-Step)*8)) <= Cutout;
          Step := Step + 1;
        ELSIF (Step = 7) THEN
          IntToLogicVectorReady <= '1';
          Step := 0;
          uint_input := IntToLogicVectorIntInput;
        END IF;
      END IF;
  end process IntToLogicVector;

  --Sammelt die Eingangswerte
  CollectData: process(Reset, EN, data_valid)
    variable CurrentFiFo1 : boolean := true; --true: Sammelt gerade Daten in FiFo1, false: Sammelt gerade Daten in FiFo2
    variable CurrentEntry : integer RANGE 0 to (BufferSize+1) := 0;
  BEGIN
    IF (Reset = '1') THEN
      PrepareNextLineActivSet <= '0';
      PrepareNextLineActivReset1 <= '1';
      FiFo1 <= (others => (others => 0));
      FiFo2 <= (others => (others => 0));
    ELSE
      PrepareNextLineActivReset1 <= '0';
      IF ((EN = '1') AND (rising_edge(data_valid))) THEN
        PrepareNextLineActivSet <= '0';
         IF (CurrentFiFo1) THEN
            --Sammelt gerade Daten in FiFo1
            IF (CurrentEntry <= BufferSize) THEN
              --In der FiFo ist genuegend Platz fuer einen weiteren Eintrag
              FiFo1(CurrentEntry).acc_x <= acc_x;
              FiFo1(CurrentEntry).acc_y <= acc_y;
              FiFo1(CurrentEntry).acc_z <= acc_z;
              CurrentEntry := CurrentEntry + 1;
            ELSE
              --Die FiFo ist gefuellt kein weitere Eintraege Moeglich
              IF (PrepareNextLineReady = '1') THEN
                --Prozess PrepareNextLine ist bereit die FiFo auszugeben
                CurrentFiFo1 := false;
                CurrentEntry := 0;
                SumRejectedDataFiFo2 <= 0;
                PrepareNextLineSelectFiFo1 <= true;
                PrepareNextLineActivSet <= '1';
              ELSE
                --Der Prozess PrepareNextLine ist beschaefigt; Messdaten muessen verworfen werden
                SumRejectedDataFiFo1 <= SumRejectedDataFiFo1 + 1;
              END IF;
            END IF;
          ELSE
            --Sammelt gerade Daten in FiFo2
            IF (CurrentEntry <= BufferSize) THEN
              --In der FiFo ist genuegend Platz fuer einen weiteren Eintrag
              FiFo2(CurrentEntry).acc_x <= acc_x;
              FiFo2(CurrentEntry).acc_y <= acc_y;
              FiFo2(CurrentEntry).acc_z <= acc_z;
              CurrentEntry := CurrentEntry + 1;
            ELSE
              --Die FiFo ist gefuellt kein weitere Eintraege Moeglich
              IF (PrepareNextLineReady = '1') THEN
                --Prozess PrepareNextLine ist bereit die FiFo auszugeben
                CurrentFiFo1 := true;
                CurrentEntry := 0;
                SumRejectedDataFiFo2 <= 1;
                PrepareNextLineSelectFiFo1 <= false;
                PrepareNextLineActivSet <= '1';
              ELSE
                --Der Prozess PrepareNextLine ist beschaefigt; Messdaten muessen verworfen werden
                SumRejectedDataFiFo2 <= SumRejectedDataFiFo2 + 1;
              END IF;
            END IF;
          END IF;
      END IF;
    END IF;
  END process CollectData;

  SwitchPrepareNextLine: process(PrepareNextLineActivSet, PrepareNextLineActivReset1, PrepareNextLineActivReset2)
  BEGIN
    IF (PrepareNextLineActivSet = '1') THEN
      PrepareNextLineActiv <= '1';
	 ELSE
		PrepareNextLineActiv <= '0';
	 END IF;
	  
	 --xDDFPNLAS: entity work.xDDF(behave) 
		--port map(
		--D => PrepareNextLineActivSet,
		--EN => '1',
		--Reste => Reset,
		--Clk => Clk,
		--Q => PrepareNextLineActiv
		--);
	 
    IF ((PrepareNextLineActivReset1 = '1') OR (PrepareNextLineActivReset2 = '1')) THEN
      PrepareNextLineActiv <= '0';
    END IF;
  END process SwitchPrepareNextLine;

  --ToDo Ausgabe der beiden Zaehler mit der Anzahl der verworfenen Messungen
  --Bereitet die naechste Zeile zur Ausgabe, ueber den Prozess ByteWhiteOutput, mit den Daten von FiFo1 oder FiFo2 vor
  --Anschliessend wird der Prozess ByteWhiteOutput angestossen. Ist aktiv falls EN = '1' und PrepareNextLineActiv = '1' ist
  --Fomrat der Ausgabe: "x:+/-_____ y:+/-_____ z:+/-_____\n\r"
  --Setzt PrepareNextLineReady auf '1' falls der gesamte inhalt der FiFo ausgegebn wurde
  PrepareNextLine: process(Reset, EN, PrepareNextLineActiv, ByteWhiteOutputReady, IntToLogicVectorReady, 
									PrepareNextLineSelectFiFo1, FiFo1, FiFo2, IntToLogicVectorBinOutput, StepPrepareNextLine)
    variable iByteWhiteOutputBuffer : std_logic_vector(MaxBitPerByteWhiteOutput downto 0) := (others =>'0');
    variable CurrentEntry : integer RANGE 0 to (BufferSize+1) := 0;
    variable Step : integer Range 0 to 3 := 0;
  BEGIN
		Step := StepPrepareNextLine;
    IF (Reset = '1') THEN
      PrepareNextLineReady <= '1';
      PrepareNextLineActivReset2 <= '1';
      OutputActivSet <= '0';
      OutputActivReset1 <= '1';
      CurrentEntry := 0;
      Step := 0;
      iByteWhiteOutputBuffer := (others =>'0');
		
    ELSE
      PrepareNextLineActivReset2 <= '0';
      OutputActivReset1 <= '0';
		PrepareNextLineReady <= '0';												--Test bzgl. Latches
		OutputActivSet <= '1';
		--Step := StepPrepareNextLine;
		
      IF ((EN = '1') AND (PrepareNextLineActiv = '1')) THEN
        OutputActivSet <= '0';
        IF(ByteWhiteOutputReady = '1') THEN
          IF (CurrentEntry >= (BufferSize+1)) THEN
            --Alle Eintraege im Puffer sind ausgegeben
            CurrentEntry := 0;
            PrepareNextLineReady <= '1';
            PrepareNextLineActivReset2 <= '1';
          ELSE
            --Bereitet die naechste Zeile zur Ausgabe vor und triggert den Prozess ByteWhiteOutput
            PrepareNextLineReady <= '0';
            IF (Step = 0) THEN
              iByteWhiteOutputBuffer(223 downto 208) := x"783A"; --Text "x:"
              IF (PrepareNextLineSelectFiFo1) THEN
                IntToLogicVectorIntInput <= FiFo1(CurrentEntry).acc_x;
              ELSE
                IntToLogicVectorIntInput <= FiFo2(CurrentEntry).acc_x;
              END IF;
              IF IntToLogicVectorReady = '1' THEN Step := 1; END IF;
            ELSIF (Step = 1) THEN
              iByteWhiteOutputBuffer(207 downto 160) := IntToLogicVectorBinOutput;
              iByteWhiteOutputBuffer(159 downto 136) := x"20793A"; --Text " y:"
              IF (PrepareNextLineSelectFiFo1) THEN
                IntToLogicVectorIntInput <= FiFo1(CurrentEntry).acc_y;
              ELSE
                IntToLogicVectorIntInput <= FiFo2(CurrentEntry).acc_y;
              END IF;
              IF IntToLogicVectorReady = '1' THEN Step := 2; END IF;
            ELSIF (Step = 2) THEN
              iByteWhiteOutputBuffer(135 downto 88) := IntToLogicVectorBinOutput;
              iByteWhiteOutputBuffer(87 downto 64) := x"207A3A"; --Text " z:"
              IF (PrepareNextLineSelectFiFo1) THEN
                IntToLogicVectorIntInput <= FiFo1(CurrentEntry).acc_z;
              ELSE
                IntToLogicVectorIntInput <= FiFo2(CurrentEntry).acc_z;
              END IF;
              IF IntToLogicVectorReady = '1' THEN Step := 3; END IF;
            ELSIF (Step = 3) THEN
              iByteWhiteOutputBuffer(63 downto 16) := IntToLogicVectorBinOutput;
              iByteWhiteOutputBuffer(15 downto 0) := x"0A0D"; --Text "\n\r"
              CurrentEntry := CurrentEntry + 1;
              OutputActivSet <= '1';
              Step := 0;
            ELSE
              Step := 0;
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;
    ByteWhiteOutputBuffer <= iByteWhiteOutputBuffer;
	 StepPrepareNextLine <= Step;
  END process PrepareNextLine;

  SwitchByteWhiteOutput: process(OutputActivSet, OutputActivReset1, OutputActivReset2)
  BEGIN
    IF (OutputActivSet = '1') THEN
      OutputActiv <= '1';		
    ELSIF ((OutputActivReset1 = '1') OR (OutputActivReset2 = '1')) THEN
      OutputActiv <= '0';
	 --ELSE
		--OutputActiv <= '0';
    END IF;
  END process SwitchByteWhiteOutput;

  --ToDo mit clock synchronisieren
  --Gibt die Bytes aus ByteWhiteOutputBuffer einzel an die UART aus, wenn OutputActiv '1' und EN '1' ist
  --Sobald das Zeichen '\r' in ByteWhiteOutputBuffer erkannt wird stoppt die ausgabe
  --Setzt ByteWhiteOutputReady auf '1' wenn alle Bytes ausgegebn wurden
  ByteWhiteOutput: process(Reset, EN, OutputActiv, TX_BUSY, iTX_DATA, ByteWhiteOutputBuffer)
    variable CurrentByte : integer RANGE 0 to 8 := 0; --Maximal 224 Bit pro Zeile
  BEGIN
    IF (Reset = '1') THEN
      CurrentByte := 0;
      OutputActivReset2 <= '1';
      ByteWhiteOutputReady <= '1';
      iTX_EN <= '0';
      iTX_DATA <= x"00";
    ELSE
      OutputActivReset2 <= '0';
      IF (EN = '1' AND OutputActiv = '1') THEN
        IF  (TX_BUSY = '0') THEN
          IF ((CurrentByte >= 28) OR (iTX_DATA = x"0D")) THEN
            --Alle Bytes uebertragen
            ByteWhiteOutputReady <= '1';
            OutputActivReset2 <= '1';
            CurrentByte := 0;
          ELSE
            --Uebertraegt ein Byte
            ByteWhiteOutputReady <= '0';
            iTX_DATA <= ByteWhiteOutputBuffer( (MaxBitPerByteWhiteOutput-(8*CurrentByte)) DOWNTO (MaxBitPerByteWhiteOutput-(8*((CurrentByte+1))-1)) );
            CurrentByte := CurrentByte + 1;
          END IF;
        END IF;
        iTX_EN <= '1';
      ELSE
        iTX_EN <= '0';
      END IF;
    END IF;
  END process ByteWhiteOutput;
  TX_EN <= iTX_EN;
  TX_DATA <= iTX_DATA;
end behave;
