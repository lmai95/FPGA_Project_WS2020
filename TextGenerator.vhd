library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TextGenerator is
  generic(
    MaxBitPerByteWhiteOutput : integer := 247 --Legt die Anazahl der Bit's fest (inclusive Wert 0..) die ByteWhiteOutput aufeinmal verarbeitet; ->31 ASCII-Zeichen: 3xacc=18 + 3xPunkt + Zeilenumbruch=2 + Leerzeichen=2 + Text=6
  );
  port(
    EN 	  	: in std_logic := '1'; --Enable Signal des TextGenerators
    Reset 	: in std_logic := '0'; --Reset Signal des TextGenerators
    Clk   	: in std_logic;		  --Clock Signal des TextGenerators

    FiFoEmpty : in std_logic;			--FiFo ist leer
	 FiFoRdreq : out std_logic; 		--FiFo Read-Acknowledge
    DataFromFiFo : in STD_LOGIC_VECTOR (47 DOWNTO 0); --Eingangsdaten aus der FiFo
	 PrintRejectedData : in std_logic;						--Bei '1': Die Anzahl der nicht verarbeitbaren Messungen (RejectedData) soll ausgaben werden
    RejectedData : integer RANGE 0 to 65536 := 0; 		--Anzahl der Datensaetze die Verworfen werden mussten

	 ByteWhiteOutputReady : in std_logic;					--Bei '1' bereit die naechste Zeile auszugeben
    ByteWhiteOutputTrigger : out std_logic;				--Startet die Ausgabe duch den Wert '1'
    ByteWhiteOutputBuffer : out std_logic_vector(MaxBitPerByteWhiteOutput downto 0) := (others =>'0')--Die Daten/Die Zeile die Ausgegebn werden soll
  );
end entity TextGenerator;

architecture behave of TextGenerator is
  signal IntToLogicVectorReady : std_logic := '1';		--Bei '1' Prozess IntToLogicVector kann die naechste Wandlung durchfuehren
  signal IntToLogicVectorTrigger : std_logic := '0';	--Startet den Prozess IntToLogicVector durch eine '1'
  signal IntToLogicVectorIntInput : integer RANGE -32768 to 32767 := 0;	--Zu Wandelnder Wert von IntToLogicVector
  signal IntToLogicVectorBinOutput 	: std_logic_vector(47 downto 0) := (others =>'0'); --Ergebnis der Wandlung des Prozesses IntToLogicVector
  signal iIntToLogicVectorBinOutput 	: std_logic_vector(47 downto 0) := (others =>'0');
  signal IntToLogicVectorStep : integer RANGE 0 to	8 := 0;		--aktueller Zustand der FSM des Prozesses IntToLogicVector
  signal IntToLogicVectorNextStep : integer RANGE 0 to 8 := 0; --naechster Zustand der FSM des Prozesses IntToLogicVector

  signal PrepareNextLineStep : integer Range 0 to 30 := 0;
  signal PrepareNextLineNextStep : integer Range 0 to 30 := 0;
  signal iByteWhiteOutputBuffer : std_logic_vector(MaxBitPerByteWhiteOutput downto 0) := (others =>'0'); --Speicher fuer die Ausgabe der naechsten Zeile; 31 ASCII-Zeichen: 3xacc=18 + 3xPunkt + Zeilenumbruch=2 + Leerzeichen=2 + Text=6
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
			iIntToLogicVectorBinOutput <= (others =>'0');
			IntToLogicVectorReady <= '0';
      ELSIF (IntToLogicVectorStep = 2) THEN
        --Ergaenzt das Vorzeichen & erzeugt den absolut Wert
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
  --Erzeugt einen Text in Ascii-Codierung zur Ausgabe. Ist aktiv falls EN = '1' ist.
  --Erzeugt aus den Daten der FiFo den Text: "x:+/-___.__ y:+/-___.__ z:+/-___.__\n\r", wenn Daten vorhanden sind.
  --Falls PrintRejectedData auf '1' gesetz wird, wird der Text: "+/-_____\n\r" erzeugt.
  --Weitere Byteweise ausgabe erfolgt ueber die Entity ByteWhiteOutput.
  PrepareNextLine: process(Reset, Clk)
  BEGIN
    IF (Reset = '1') THEN
		FiFoRdreq <= '0';
      iByteWhiteOutputBuffer <= (others =>'0');
      IntToLogicVectorIntInput <= 0;
		IntToLogicVectorTrigger <= '0';
      ByteWhiteOutputTrigger <= '0';
    ELSIF (rising_edge(Clk)) THEN
		IF (PrepareNextLineStep = 0) THEN
			--Grundzustand wartet auf Daten oder auf PrintRejectedData = '1'
			FiFoRdreq <= '0';
			iByteWhiteOutputBuffer <= (others =>'0');
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';

		--Erzeugt aus den Daten der FiFo den Text: "x:+/-___.__ y:+/-___.__ z:+/-___.__\n\r" & Triggert die Ausgabe
		ELSIF (PrepareNextLineStep = 1) THEN
			--Erzeugt den Text "x:" & Triggert die Wandlung fuer den Wert acc_x
			FiFoRdreq <= '0';
			iByteWhiteOutputBuffer(247 downto 232) <= x"783A"; --Text "x:"
			IntToLogicVectorIntInput <= to_integer(signed(DataFromFiFo(47 DOWNTO 32)));
			IntToLogicVectorTrigger <= '1';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 2) THEN
			--Wartet bis die Wandlung abgeschlossen ist (IntToLogicVectorReady='1')
			FiFoRdreq <= '0';
			iByteWhiteOutputBuffer(231 downto 200) <= IntToLogicVectorBinOutput(47 downto 16);
      iByteWhiteOutputBuffer(199 downto 192) <= x"2E"; -- Text "."
      iByteWhiteOutputBuffer(191 downto 176)<= IntToLogicVectorBinOutput(15 downto 0);
			IntToLogicVectorIntInput <= to_integer(signed(DataFromFiFo(47 DOWNTO 32)));
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 3) THEN
			--Erzeugt den Text " y:" & Triggert die Wandlung fuer den Wert acc_y
			FiFoRdreq <= '0';
			iByteWhiteOutputBuffer(175 downto 152) <= x"20793A"; --Text " y:"
			IntToLogicVectorIntInput <= to_integer(signed(DataFromFiFo(31 DOWNTO 16)));
			IntToLogicVectorTrigger <= '1';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 4) THEN
			--Wartet bis die Wandlung abgeschlossen ist (IntToLogicVectorReady='1')
			FiFoRdreq <= '0';
			iByteWhiteOutputBuffer(151 downto 120) <= IntToLogicVectorBinOutput(47 downto 16);
      iByteWhiteOutputBuffer(119 downto 112) <= x"2E"; -- Text "."
      iByteWhiteOutputBuffer(111 downto 96)<= IntToLogicVectorBinOutput(15 downto 0);
			IntToLogicVectorIntInput <= to_integer(signed(DataFromFiFo(31 DOWNTO 16)));
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 5) THEN
			--Erzeugt den Text " z:" & Triggert die Wandlung fuer den Wert acc_z
			FiFoRdreq <= '0';
			iByteWhiteOutputBuffer(95 downto 72) <= x"207A3A"; --Text " z:"
			IntToLogicVectorIntInput <= to_integer(signed(DataFromFiFo(15 DOWNTO 0)));
			IntToLogicVectorTrigger <= '1';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 6) THEN
			--Wartet bis die Wandlung abgeschlossen ist & die Ausgabe Bereit ist (IntToLogicVectorReady='1' && ByteWhiteOutputReady='1') & Erzeugt den Text "\n\r"
			FiFoRdreq <= '0';
			iByteWhiteOutputBuffer(71 downto 40) <= IntToLogicVectorBinOutput(47 downto 16);
      iByteWhiteOutputBuffer(39 downto 32) <= x"2E"; -- Text "."
      iByteWhiteOutputBuffer(31 downto 16) <= IntToLogicVectorBinOutput(15 downto 0);
      iByteWhiteOutputBuffer(15 downto 0) <= x"0A0D"; --Text "\n\r"
			IntToLogicVectorIntInput <= to_integer(signed(DataFromFiFo(15 DOWNTO 0)));
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 7) THEN
			--Setzt FiFo Read-Acknowledge auf '1'
			FiFoRdreq <= '1';
			ByteWhiteOutputBuffer <= iByteWhiteOutputBuffer;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 8) THEN
			--Triggert die Ausgabe
			FiFoRdreq <= '0';
			ByteWhiteOutputBuffer <= iByteWhiteOutputBuffer;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '1';

		--Erzeugt aus PrintRejectedData den Text: "_____ Messungen verworfen\n\r" & Triggert die Ausgabe
		ELSIF (PrepareNextLineStep = 10) THEN
			--Triggert die Wandlung fuer den Wert RejectedData
			FiFoRdreq <= '0';
			iByteWhiteOutputBuffer <= (others =>'0');
			IntToLogicVectorIntInput <= RejectedData;
			IntToLogicVectorTrigger <= '1';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 11) THEN
			--Wartet bis die Wandlung abgeschlossen ist & die Ausgabe Bereit ist (IntToLogicVectorReady='1' && ByteWhiteOutputReady='1') & Erzeugt den Text " Messungen verworfen\n\r"
			FiFoRdreq <= '0';
			iByteWhiteOutputBuffer(223 downto 8) <= IntToLogicVectorBinOutput(39 DOWNTO 0) & x"204d657373756e67656e20766572776f7266656e0A0D"; --Text " Messungen verworfen\n\r"
			IntToLogicVectorIntInput <= RejectedData;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '0';
		ELSIF (PrepareNextLineStep = 12) THEN
			--Triggert die Ausgabe
			FiFoRdreq <= '0';
			ByteWhiteOutputBuffer <= iByteWhiteOutputBuffer;
			IntToLogicVectorIntInput <= 0;
			IntToLogicVectorTrigger <= '0';
			ByteWhiteOutputTrigger <= '1';
      END IF;

	END IF;
  END process PrepareNextLine;

  PrepareNextLineNextState: process(Reset, Clk, EN, FiFoEmpty, PrintRejectedData, IntToLogicVectorReady, ByteWhiteOutputReady)
  BEGIN
	IF Reset = '1' THEN
		PrepareNextLineNextStep <= 0;
	ELSIF (rising_edge(Clk)) THEN
		 PrepareNextLineNextStep <= PrepareNextLineStep;
		 IF (EN = '1') THEN
			CASE PrepareNextLineStep IS
			  WHEN 0 =>
				IF (FiFoEmpty = '0') THEN PrepareNextLineNextStep <= 1; END IF;
				IF (PrintRejectedData = '1') THEN PrepareNextLineNextStep <= 10; END IF;
			  WHEN 1 =>
				IF (IntToLogicVectorReady = '0') THEN PrepareNextLineNextStep <= 2; END IF;
			  WHEN 2 =>
				IF (IntToLogicVectorReady = '1') THEN PrepareNextLineNextStep <= 3; END IF;
			  WHEN 3 =>
				IF (IntToLogicVectorReady = '0') THEN PrepareNextLineNextStep <= 4; END IF;
			  WHEN 4 =>
				IF (IntToLogicVectorReady = '1') THEN PrepareNextLineNextStep <= 5; END IF;
			  WHEN 5 =>
				IF (IntToLogicVectorReady = '0') THEN PrepareNextLineNextStep <= 6; END IF;
			  WHEN 6 =>
				IF (IntToLogicVectorReady = '1') and (ByteWhiteOutputReady = '1') THEN PrepareNextLineNextStep <= 7; END IF;
			  WHEN 7 =>
				PrepareNextLineNextStep <= 8;
			  WHEN 8 =>
			   IF (ByteWhiteOutputReady = '0') THEN PrepareNextLineNextStep <= 0; END IF;

			  WHEN 10 =>
			   IF (IntToLogicVectorReady = '0') THEN PrepareNextLineNextStep <= 11; END IF;
			  WHEN 11 =>
			   IF (IntToLogicVectorReady = '1') and (ByteWhiteOutputReady = '1') THEN PrepareNextLineNextStep <= 12; END IF;
			  WHEN 12 =>
			   IF (ByteWhiteOutputReady = '0') THEN PrepareNextLineNextStep <= 0; END IF;

			  WHEN OTHERS =>
				 PrepareNextLineNextStep <= 0;
			END CASE;
		 END IF;
	END IF;
  END process PrepareNextLineNextState;
  PrepareNextLineStep <= PrepareNextLineNextStep;
end architecture behave;
