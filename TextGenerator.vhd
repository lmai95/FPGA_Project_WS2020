library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.BufferData.all;

entity TextGenerator is
  generic(
    BufferSize : integer := 9;                  --Legt die groesse des Buffer fest
    MaxBitPerByteWhiteOutput : integer := 223   --Legt die maximale Zeilenlaenge in Bit fest; 28 ASCII-Zeichen: 3xacc=18 + Zeilenumbruch=2 + Leerzeichen=2 + Text=6
  );
  port(
    EN 	  	: in std_logic := '1'; --Enable Signal des TextGenerators
    Reset 	: in std_logic := '0'; --Reset Signal des TextGenerators
    Clk   	: in std_logic;
    TextGeneratorReady : out std_logic;
    TextGeneratorTrigger : in std_logic;
    FiFo : in DataSampleBuffer(BufferSize downto 0); --Buffer mit eingegangen Daten
    ByteWhiteOutputReady : in std_logic;
    ByteWhiteOutputTrigger : out std_logic;
    ByteWhiteOutputBuffer :out std_logic_vector(MaxBitPerByteWhiteOutput downto 0)
  );
end entity TextGenerator;

architecture behave of TextGenerator is
  signal IntToLogicVectorReady : std_logic := '1';
  signal IntToLogicVectorIntInput : integer RANGE 0 to 65536;
  signal IntToLogicVectorBinOutput 	: std_logic_vector(47 downto 0) := (others =>'0');
  signal IntToLogicVectorTrigger : std_logic := '0';
  signal IntToLogicVectorReset : std_logic := '0';
  signal IntToLogicVectorTaskCompleted : std_logic := '0';
  signal IntToLogicVectorActiv : std_logic := '0';
  
  signal PrepareNextLineReset : std_logic := '0';
  signal PrepareNextLineTaskCompleted : std_logic := '0';
  signal PrepareNextLineActiv : std_logic := '0';
  signal CurrentEntry : integer RANGE 0 to (BufferSize+1) := 0;
  signal iCurrentEntry : integer RANGE 0 to (BufferSize+1) := 0;
  signal StepPrepareNextLine : integer Range 0 to 4 := 0;
  signal NextStepPrepareNextLine : integer Range 0 to 4 := 0;
  signal iByteWhiteOutputBuffer : std_logic_vector(MaxBitPerByteWhiteOutput downto 0) := (others =>'0'); --Speicher fuer die Ausgabe der naechsten Zeile; 28 ASCII-Zeichen: 3xacc=18 + Zeilenumbruch=2 + Leerzeichen=2 + Text=6
  signal ByteWhiteOutputReadyLast : std_logic := '1';
  signal IntToLogicVectorReadyLast : std_logic := '1';
  
  BEGIN
  IntToLogicVectorReset <= IntToLogicVectorTaskCompleted or Reset;
  IntToLogicVectorSwitch: entity work.xDDF(behave) 
  port map(
    D => IntToLogicVectorTrigger,
    EN => '1',
    Reset => IntToLogicVectorReset,
    Clk => Clk,
    Q => IntToLogicVectorActiv
  );
  --Wandelt die signed Integer Zahl IntToLogicVectorIntInput in ASCI Zeichen um. Annahme 16Bit integer daher mit Vorzeichen 6-ASCI Zeichen
  --Umwandlung beginnt sobald IntToLogicVectorReady ein neuer Wert zugewisen wird. Ausgabe erfolgt in IntToLogicVectorBinOutput
  --Sobald die Umwandlung abgeschlossen ist und eine neue begonnen werden kann wird IntToLogicVectorReady auf '1' gesetzt
  IntToLogicVector: process(Clk, Reset, IntToLogicVectorIntInput)
    variable Step : integer RANGE 0 to 9 := 0;
    variable IntUnderConversion : integer RANGE 0 to 65536;
    variable Digit : integer RANGE 0 to 9 := 0;
    variable Cutout : std_logic_vector(7 DOWNTO 0);
  BEGIN
    IF (Reset = '1') THEN
      Step := 0;
      IntUnderConversion := 0;
      IntToLogicVectorReady <= '1';
		IntToLogicVectorTaskCompleted <= '0';
    ELSIF (rising_edge(Clk)) THEN
		IntToLogicVectorTaskCompleted <= '0';
      IF (Step = 0) THEN
        --Wartet auf einen neuen Wert
        IF (IntToLogicVectorActiv = '1') THEN
          Step := 1;
        END IF;
      ELSIF (Step = 1) THEN
        --Ergaenzt das Vorzeichen & erzeugt den absolut Wert
        IF (IntToLogicVectorIntInput < 0) THEN
          IntToLogicVectorBinOutput(47 downto 40) <= B"00101101"; --Text: "-"
          IntUnderConversion := IntToLogicVectorIntInput*(-1);
        ELSE
          IntToLogicVectorBinOutput(47 downto 40) <= B"00101011"; --Text: "+"
          IntUnderConversion := IntToLogicVectorIntInput;
        END IF;
        IntToLogicVectorReady <= '0';
        Step := 2;
      ELSIF ((Step >= 2) AND (Step <= 6)) THEN
        --Wandelt nacheinander die Eingabe IntToLogicVectorIntInput in fuenf ASCII Zeichen
        Digit := IntUnderConversion mod 10;
        IntUnderConversion := IntUnderConversion/10;
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
        IntToLogicVectorReady <= '0';
        Step := Step + 1;
        ELSIF (Step = 7) THEN
          --Umwandlung abgeschlossen
          IntToLogicVectorReady <= '1';
          Step := 0;
          IntToLogicVectorTaskCompleted <= '1';
        END IF;
      END IF;
  end process IntToLogicVector;

  PrepareNextLineReset <= PrepareNextLineTaskCompleted or Reset;
  SwitchPrepareNextLine: entity work.xDDF(behave)
  port map(
    D => TextGeneratorTrigger,
    EN => '1',
    Reset => PrepareNextLineReset,
    Clk => Clk,
    Q => PrepareNextLineActiv,
    Qn => TextGeneratorReady
  );
  --ToDo Ausgabe der beiden Zaehler mit der Anzahl der verworfenen Messungen
  --Bereitet die naechste Zeile zur Ausgabe, ueber den Prozess ByteWhiteOutput, mit den Daten von FiFo vor
  --Anschliessend wird der Prozess ByteWhiteOutput angestossen. Ist aktiv falls EN = '1' und PrepareNextLineActiv = '1' ist
  --Fomrat der Ausgabe: "x:+/-_____ y:+/-_____ z:+/-_____\n\r"
  --Setzt TextGeneratorReady auf '1' falls der gesamte inhalt der FiFo ausgegebn wurde
  PrepareNextLine: process(Clk, Reset, EN, PrepareNextLineActiv)
  BEGIN
    IF (Reset = '1') THEN
      iByteWhiteOutputBuffer <= (others =>'0');
      iCurrentEntry <= 0;
      ByteWhiteOutputTrigger <= '0';
      PrepareNextLineTaskCompleted <= '0';
		IntToLogicVectorTrigger <= '0';
    ELSIF (rising_edge(Clk)) THEN
		IntToLogicVectorTrigger <= '0';
      iCurrentEntry <= CurrentEntry;
      ByteWhiteOutputTrigger <= '0';
      PrepareNextLineTaskCompleted <= '0';
      IF ((EN = '1') AND (PrepareNextLineActiv = '1') AND (ByteWhiteOutputReady = '1')) THEN
        IF (iCurrentEntry >= (BufferSize+1)) THEN
          --Alle Eintraege im Puffer sind ausgegeben
          iCurrentEntry <= 0;
          PrepareNextLineTaskCompleted <= '1';
        ELSE
          --FSM zur Erzeugung der naechste Zeile fuer die Ausgabe triggert den Prozess ByteWhiteOutput
          IF (StepPrepareNextLine = 0) THEN
            iByteWhiteOutputBuffer(223 downto 208) <= x"783A"; --Text "x:"
            IntToLogicVectorIntInput <= FiFo(iCurrentEntry).acc_x;
				IntToLogicVectorTrigger <= '1';
          ELSIF (StepPrepareNextLine = 1) THEN
            iByteWhiteOutputBuffer(207 downto 136) <= IntToLogicVectorBinOutput & x"20793A"; --Text " y:"
            IntToLogicVectorIntInput <= FiFo(iCurrentEntry).acc_y;
				IntToLogicVectorTrigger <= '1';
          ELSIF (StepPrepareNextLine = 2) THEN
            iByteWhiteOutputBuffer(135 downto 64) <= IntToLogicVectorBinOutput & x"207A3A"; --Text " z:"
            IntToLogicVectorIntInput <= FiFo(iCurrentEntry).acc_z;
				IntToLogicVectorTrigger <= '1';
          ELSIF (StepPrepareNextLine = 3) THEN
            iByteWhiteOutputBuffer(63 downto 0) <= IntToLogicVectorBinOutput & x"0A0D"; --Text "\n\r"
            ByteWhiteOutputTrigger <= '1';
			 ELSIF (StepPrepareNextLine = 4) THEN
				iCurrentEntry<=iCurrentEntry+1;
          END IF;
        END IF;
      END IF;
    END IF;
  END process PrepareNextLine;

  --Prozess zum Weiterschalten der FSM in PrepareNextLine
  NextStatePrepareNextLine: process(StepPrepareNextLine, EN, Clk, Reset, PrepareNextLineActiv, ByteWhiteOutputReady, IntToLogicVectorReady, ByteWhiteOutputReadyLast)
  BEGIN
	IF Reset = '1' THEN 
		NextStepPrepareNextLine <= 0;
	ELSIF (rising_edge(Clk)) THEN
		 NextStepPrepareNextLine <= StepPrepareNextLine;
		 IF (EN = '1') AND (Reset = '0') AND (PrepareNextLineActiv = '1')  THEN
			CASE StepPrepareNextLine IS
			  WHEN 0 =>
				 IF (IntToLogicVectorReady = '1') AND (IntToLogicVectorReadyLast = '0') THEN NextStepPrepareNextLine <= 1; END IF;
			  WHEN 1 =>
				 IF (IntToLogicVectorReady = '1') AND (IntToLogicVectorReadyLast = '0') THEN NextStepPrepareNextLine <= 2; END IF;
			  WHEN 2 =>
				 IF (IntToLogicVectorReady = '1') AND (IntToLogicVectorReadyLast = '0') THEN NextStepPrepareNextLine <= 3; END IF;
			  WHEN 3 =>
				IF (ByteWhiteOutputReady = '1') AND (ByteWhiteOutputReadyLast = '0') THEN NextStepPrepareNextLine <= 4; END IF;
			  WHEN 4 =>
				NextStepPrepareNextLine <= 0;
			END CASE;
		 END IF;
		 ByteWhiteOutputReadyLast <= ByteWhiteOutputReady;
		 IntToLogicVectorReadyLast <= IntToLogicVectorReady;
		END IF;
  END process NextStatePrepareNextLine;
  StepPrepareNextLine <= NextStepPrepareNextLine;
  CurrentEntry <= iCurrentEntry;
  ByteWhiteOutputBuffer <= iByteWhiteOutputBuffer;
end architecture behave;
