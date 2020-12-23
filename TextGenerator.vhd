library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.BufferData.all;

entity TextGenerator is
  generic(
    BufferSize : integer := 9;                  --Legt die groesse des Buffer fest
    MaxBitPerByteWhiteOutput : integer := 47   --Legt die maximale Zeilenlaenge in Bit fest; 28 ASCII-Zeichen: 3xacc=18 + Zeilenumbruch=2 + Leerzeichen=2 + Text=6
  );
  port(
    EN 	  	: in std_logic := '1'; --Enable Signal des TextGenerators
    Reset 	: in std_logic := '0'; --Reset Signal des TextGenerators
    Clk   	: in std_logic;		  --Clock Signal des TextGenerators
    TextGeneratorReady : out std_logic;  --Bei '1' bereit die naechste Buffer auszugeben
    TextGeneratorTrigger : in std_logic; --Startet die Ausgabe duch den Wert '1'
    FiFo : in DataSampleBuffer(BufferSize downto 0); --Buffer mit eingegangen Daten
    CntRejectedData : integer RANGE 0 to 65536 := 0; --Anzahl der Datensaetze die Verworfen werden mussten
	 ByteWhiteOutputReady : in std_logic;
    ByteWhiteOutputTrigger : out std_logic;
    ByteWhiteOutputBuffer : out std_logic_vector(MaxBitPerByteWhiteOutput downto 0)
  );
end entity TextGenerator;

architecture behave of TextGenerator is
  signal IntToLogicVectorReady : std_logic := '1';		--Bei '1' Prozess IntToLogicVector kann die naechste Wandlung durchfuehren
  signal IntToLogicVectorTrigger : std_logic := '0';	--Startet den Prozess IntToLogicVector durch eine '1'
  signal IntToLogicVectorIntInput : integer RANGE 0 to 65536 := 0;	--Zu Wandelnder Wert von IntToLogicVector
  signal IntToLogicVectorBinOutput 	: std_logic_vector(47 downto 0) := (others =>'0'); --Ergebnis der Wandlung des Prozesses IntToLogicVector
  signal iIntToLogicVectorBinOutput 	: std_logic_vector(47 downto 0) := (others =>'0');
  signal IntToLogicVectorStep : integer RANGE 0 to	8 := 0;		--aktueller Zustand der FSM des Prozesses IntToLogicVector
  signal IntToLogicVectorNextStep : integer RANGE 0 to 8 := 0; --naechster Zustand der FSM des Prozesses IntToLogicVector
  
  signal PrepareNextLineStep : integer Range 0 to 30 := 0;
  signal PrepareNextLineNextStep : integer Range 0 to 30 := 0;
  signal CurrentEntry : integer RANGE 0 to (BufferSize+1) := 0;
  signal iCurrentEntry : integer RANGE 0 to (BufferSize+1) := 0;  
  signal iByteWhiteOutputBuffer : std_logic_vector(MaxBitPerByteWhiteOutput downto 0) := (others =>'0'); --Speicher fuer die Ausgabe der naechsten Zeile; 28 ASCII-Zeichen: 3xacc=18 + Zeilenumbruch=2 + Leerzeichen=2 + Text=6  
  BEGIN
  --Wandelt die (signed) Integer Zahl IntToLogicVectorIntInput in eine ASCII Zeichen-Darstellung. Annahme: 16Bit-Integer daher mit Vorzeichen 6-ASCI Zeichen.
  --Die Umwandlung wird gestartet indem IntToLogicVectorTrigger auf '1' gesetzt wird. Das Ergbnis der Wandlung wird in IntToLogicVectorBinOutput ausgegben.
  --Sobald alle Umwandlungen abgeschlossen sind und eine neue begonnen werden kann wird IntToLogicVectorReady auf '1' gesetzt
  IntToLogicVector: process(Reset, Clk, IntToLogicVectorStep, IntToLogicVectorIntInput)
    variable IntUnderConversion : integer RANGE 0 to 65536 := 0;
    variable Digit : integer RANGE 0 to 9 := 0;
    variable Cutout : std_logic_vector(7 DOWNTO 0) := (others =>'0');
  BEGIN
    IF (Reset = '1') THEN
      IntUnderConversion := 0;
		Digit := 0;
		Cutout := (others =>'0');
		iIntToLogicVectorBinOutput <= (others =>'0');
      IntToLogicVectorReady <= '1';
    ELSIF (rising_edge(Clk)) THEN
      IF (IntToLogicVectorStep = 0) THEN
			--Wartet auf Trigger '1'
			iIntToLogicVectorBinOutput <= IntToLogicVectorBinOutput;
			IntToLogicVectorReady <= '1';
		ELSIF (IntToLogicVectorStep = 1) THEN	
			--Setzt die Ausgabe zurueck
			iIntToLogicVectorBinOutput <= IntToLogicVectorBinOutput;
			iIntToLogicVectorBinOutput <= (others =>'0');
			IntToLogicVectorReady <= '0';
      ELSIF (IntToLogicVectorStep = 2) THEN
        --Ergaenzt das Vorzeichen & erzeugt den absolut Wert
		  iIntToLogicVectorBinOutput <= IntToLogicVectorBinOutput;
        IF (IntToLogicVectorIntInput < 0) THEN
          iIntToLogicVectorBinOutput(47 downto 40) <= B"00101101"; --Text: "-"
          IntUnderConversion := IntToLogicVectorIntInput*(-1);
        ELSE
          iIntToLogicVectorBinOutput(47 downto 40) <= B"00101011"; --Text: "+"
          IntUnderConversion := IntToLogicVectorIntInput;
        END IF;
		  IntToLogicVectorReady <= '0';
      ELSIF ((IntToLogicVectorStep >= 3) AND (IntToLogicVectorStep <= 7)) THEN
        --Wandelt nacheinander die Eingabe IntToLogicVectorIntInput in ASCII Zeichen
		  iIntToLogicVectorBinOutput <= IntToLogicVectorBinOutput;
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
        iIntToLogicVectorBinOutput((47-((8-IntToLogicVectorStep)*8)) DOWNTO (48-(9-IntToLogicVectorStep)*8)) <= Cutout;
		  IntToLogicVectorReady <= '0';
		ELSIF (IntToLogicVectorStep = 8) THEN
			--Wartet auf Trigger '0'
			iIntToLogicVectorBinOutput <= IntToLogicVectorBinOutput;
			IntToLogicVectorReady <= '0';
      END IF;
    END IF;
  end process IntToLogicVector;
  
  IntToLogicVectorNextState: process(Reset, Clk, EN, IntToLogicVectorStep, IntToLogicVectorTrigger)
  BEGIN
	IF Reset = '1' THEN
		IntToLogicVectorNextStep <= 0;
	ELSIF (rising_edge(Clk)) THEN
		IntToLogicVectorNextStep <= IntToLogicVectorStep;
		IF (EN = '1') THEN
			CASE IntToLogicVectorStep IS
				WHEN 0 =>
					IF (IntToLogicVectorTrigger = '1') THEN IntToLogicVectorNextStep <= 1; END IF;
				WHEN 1 =>
					IntToLogicVectorNextStep <= 2;
				WHEN 2 =>
					IntToLogicVectorNextStep <= 3;	
				WHEN 3 =>
					IntToLogicVectorNextStep <= 4;
				WHEN 4 =>
					IntToLogicVectorNextStep <= 5;
				WHEN 5 =>
					IntToLogicVectorNextStep <= 6;
				WHEN 6 =>
					IntToLogicVectorNextStep <= 7;
				WHEN 7 =>
					IntToLogicVectorNextStep <= 8;
				WHEN 8 =>
					IF (IntToLogicVectorTrigger = '0') THEN IntToLogicVectorNextStep <= 0; END IF;
				WHEN OTHERS =>
					IntToLogicVectorNextStep <= 0;
			END CASE;
		END IF;
	END IF;
  end process IntToLogicVectorNextState;
  IntToLogicVectorStep <= IntToLogicVectorNextStep;
  IntToLogicVectorBinOutput <= iIntToLogicVectorBinOutput;
    
  
  --ToDo Ausgabe der beiden Zaehler mit der Anzahl der verworfenen Messungen
  --Bereitet die naechste Zeile zur Ausgabe, ueber den Prozess ByteWhiteOutput, mit den Daten von FiFo vor
  --Anschliessend wird der Prozess ByteWhiteOutput angestossen. Ist aktiv falls EN = '1' und PrepareNextLineActiv = '1' ist
  --Fomrat der Ausgabe: "x:+/-_____ y:+/-_____ z:+/-_____\n\r"
  --Setzt TextGeneratorReady auf '1' falls der gesamte inhalt der FiFo ausgegebn wurde
  PrepareNextLine: process(Reset, Clk, PrepareNextLineStep)
  BEGIN
    IF (Reset = '1') THEN
		TextGeneratorReady <= '1';
      iByteWhiteOutputBuffer <= (others =>'0');
		iCurrentEntry <= 0;
      IntToLogicVectorIntInput <= 0;
		IntToLogicVectorTrigger <= '0';
      ByteWhiteOutputTrigger <= '0';
    ELSIF (rising_edge(Clk)) THEN       
		IF (PrepareNextLineStep = 0) THEN
			--Grundzustand wartet auf TextGeneratorTrigger
			TextGeneratorReady <= '1';
			iByteWhiteOutputBuffer <= (others =>'0');
			iCurrentEntry <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 1) THEN
			--Triggert die Ausgabe fuer den Text "-x
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer(47 downto 16) <= x"2d783A03"; --Text "-x:"
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '1';
		ELSIF (PrepareNextLineStep = 2) THEN
			--Wartet auf die Ausgabe
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer(47 downto 16) <= x"2d783A03"; --Text "-x:"
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';	
		ELSIF (PrepareNextLineStep = 3) THEN		
			--Triggert den Prozess IntToLogicVector
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer <= (others =>'0');
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= FiFo(iCurrentEntry).acc_x;
			IntToLogicVectorTrigger <= '1';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 4) THEN
			--Wartet auf IntToLogicVector
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer <= (others =>'0');
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= FiFo(iCurrentEntry).acc_x;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 5) THEN
			--Triggert die Ausgabe fuer den Wert von acc_x
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer <= IntToLogicVectorBinOutput;
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '1';
		ELSIF (PrepareNextLineStep = 6) THEN
			--Wartet auf die Ausgabe
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer <= IntToLogicVectorBinOutput;
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 7) THEN
			--Triggert die Ausgabe fuer den Text " y:"
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer(47 downto 16) <= x"20793A03"; --Text " y:"
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '1';
		ELSIF (PrepareNextLineStep = 8) THEN
			--Wartet auf die Ausgabe
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer(47 downto 16) <= x"20793A03"; --Text " y:"
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';	
		ELSIF (PrepareNextLineStep = 9) THEN		
			--Triggert den Prozess IntToLogicVector
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer <= (others =>'0');
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= FiFo(iCurrentEntry).acc_y;
			IntToLogicVectorTrigger <= '1';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 10) THEN
			--Wartet auf IntToLogicVector
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer <= (others =>'0');
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= FiFo(iCurrentEntry).acc_y;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 11) THEN
			--Triggert die Ausgabe fuer den Wert von acc_y
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer <= IntToLogicVectorBinOutput;
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '1';
		ELSIF (PrepareNextLineStep = 12) THEN
			--Wartet auf die Ausgabe
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer <= IntToLogicVectorBinOutput;
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';	
		ELSIF (PrepareNextLineStep = 13) THEN
			--Triggert die Ausgabe fuer den Text " z:"
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer(47 downto 16) <= x"207A3A03"; --Text " z:"
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '1';
		ELSIF (PrepareNextLineStep = 14) THEN
			--Wartet auf die Ausgabe
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer(47 downto 16) <= x"207A3A03"; --Text " z:"
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';	
		ELSIF (PrepareNextLineStep = 15) THEN		
			--Triggert den Prozess IntToLogicVector
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer <= (others =>'0');
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= FiFo(iCurrentEntry).acc_z;
			IntToLogicVectorTrigger <= '1';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 16) THEN
			--Wartet auf IntToLogicVector
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer <= (others =>'0');
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= FiFo(iCurrentEntry).acc_z;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 17) THEN
			--Triggert die Ausgabe fuer den Wert von acc_z
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer <= IntToLogicVectorBinOutput;
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '1';
		ELSIF (PrepareNextLineStep = 18) THEN
			--Wartet auf die Ausgabe
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer <= IntToLogicVectorBinOutput;
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';			
		ELSIF (PrepareNextLineStep = 19) THEN
			--Triggert die Ausgabe fuer den Text "\n\r"
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer(47 downto 24) <= x"0A0D03"; --Text "\n\rETX"
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '1';
		ELSIF (PrepareNextLineStep = 20) THEN
			--Wartet auf die Ausgabe
			TextGeneratorReady <= '0';
			iByteWhiteOutputBuffer(47 downto 24) <= x"0A0D03"; --Text "\n\rETX"
			iCurrentEntry <= CurrentEntry;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 29) THEN
			--Trifft vorbereitungen zur ausgabe weiter Daten
			TextGeneratorReady <= '0';
			iCurrentEntry <= iCurrentEntry + 1;
		ELSIF (PrepareNextLineStep = 30) THEN
			--Wartet bis TextGeneratorTrigger '0' ist
			TextGeneratorReady <= '0';
      END IF;
	END IF;
  END process PrepareNextLine;

  PrepareNextLineNextState: process(Reset, Clk, EN, PrepareNextLineStep, IntToLogicVectorReady, TextGeneratorTrigger, CntRejectedData, ByteWhiteOutputReady)
  BEGIN
	IF Reset = '1' THEN 
		PrepareNextLineNextStep <= 0;
	ELSIF (rising_edge(Clk)) THEN
		 PrepareNextLineNextStep <= PrepareNextLineStep;
		 IF (EN = '1') THEN
			CASE PrepareNextLineStep IS
			  WHEN 0 =>
				IF (TextGeneratorTrigger = '1') THEN PrepareNextLineNextStep <= 1; END IF;
			  WHEN 1 =>
			   IF (ByteWhiteOutputReady = '0') THEN PrepareNextLineNextStep <= 2; END IF;
			  WHEN 2 =>
			   IF (ByteWhiteOutputReady = '1') THEN PrepareNextLineNextStep <= 3; END IF;		
			  WHEN 3 =>
			   IF (IntToLogicVectorReady = '0') THEN PrepareNextLineNextStep <= 4; END IF;
			  WHEN 4 =>
			   IF (IntToLogicVectorReady = '1') THEN PrepareNextLineNextStep <= 5; END IF;
			  WHEN 5 =>
			   IF (ByteWhiteOutputReady = '0') THEN PrepareNextLineNextStep <= 6; END IF;
			  WHEN 6 =>
				IF (ByteWhiteOutputReady = '1') THEN PrepareNextLineNextStep <= 7; END IF;
			  WHEN 7 =>
			   IF (ByteWhiteOutputReady = '0') THEN PrepareNextLineNextStep <= 8; END IF;
			  WHEN 8 =>
			   IF (ByteWhiteOutputReady = '1') THEN PrepareNextLineNextStep <= 9; END IF;		
			  WHEN 9 =>
			   IF (IntToLogicVectorReady = '0') THEN PrepareNextLineNextStep <= 10; END IF;
			  WHEN 10 =>
			   IF (IntToLogicVectorReady = '1') THEN PrepareNextLineNextStep <= 11; END IF;
			  WHEN 11 =>
			   IF (ByteWhiteOutputReady = '0') THEN PrepareNextLineNextStep <= 12; END IF;
			  WHEN 12 =>
				IF (ByteWhiteOutputReady = '1') THEN PrepareNextLineNextStep <= 13; END IF;
			  WHEN 13 =>
			   IF (ByteWhiteOutputReady = '0') THEN PrepareNextLineNextStep <= 14; END IF;
			  WHEN 14 =>
			   IF (ByteWhiteOutputReady = '1') THEN PrepareNextLineNextStep <= 15; END IF;		
			  WHEN 15 =>
			   IF (IntToLogicVectorReady = '0') THEN PrepareNextLineNextStep <= 16; END IF;
			  WHEN 16 =>
			   IF (IntToLogicVectorReady = '1') THEN PrepareNextLineNextStep <= 17; END IF;
			  WHEN 17 =>
			   IF (ByteWhiteOutputReady = '0') THEN PrepareNextLineNextStep <= 18; END IF;
			  WHEN 18 =>
				IF (ByteWhiteOutputReady = '1') THEN PrepareNextLineNextStep <= 19; END IF;			  
			  WHEN 19 =>
			   IF (ByteWhiteOutputReady = '0') THEN PrepareNextLineNextStep <= 20; END IF;
			  WHEN 20 =>
			   IF (ByteWhiteOutputReady = '1') AND (CurrentEntry < BufferSize) THEN PrepareNextLineNextStep <= 29; END IF;  --Es gibt noch weiter Daten zur ausgebe
			   IF (ByteWhiteOutputReady = '1') AND (CurrentEntry >= BufferSize) THEN PrepareNextLineNextStep <= 30; END IF; --Es gibt keine weitern Daten zur ausgebe
			  WHEN 29 =>
				PrepareNextLineNextStep <= 1;
			  WHEN 30 =>
				IF (TextGeneratorTrigger = '0') THEN PrepareNextLineNextStep <= 0; END IF;
			  WHEN OTHERS =>
				 PrepareNextLineNextStep <= 0;
			END CASE;
		 END IF;
	END IF;
  END process PrepareNextLineNextState;
  PrepareNextLineStep <= PrepareNextLineNextStep;
  CurrentEntry <= iCurrentEntry;
  ByteWhiteOutputBuffer <= iByteWhiteOutputBuffer;
end architecture behave;
