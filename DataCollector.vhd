library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.BufferData.all;

entity DataCollector is
  generic(
    BufferSize : integer := 9       --Legt die groesse der beiden Buffer fest
  );
  port(
    EN 	  	: in std_logic := '1'; --Enable Signal des DataCollector
    Reset 	: in std_logic := '0'; --Reset Signal des DataCollector
    Clk   	: in std_logic;        --Taktsignal des DataCollector

    data_valid : in std_logic;  		--data valid des Sensor Kontroll-Modul
    acc_x 		 : in integer; 		--x-achse des Sensor Kontroll-Modul; in m^2; ToDo Range
    acc_y 		 : in integer; 		--y-achse des Sensor Kontroll-Modul; in m^2; ToDo Range
    acc_z 		 : in integer; 		--z-achse des Sensor Kontroll-Modul; in m^2; ToDo Range

    TextGeneratorReady : in std_logic;
    TextGeneratorTrigger : out std_logic;
    FiFo : out DataSampleBuffer(BufferSize downto 0); --Buffer mit eingegangen Daten
    CntRejectedData : out integer RANGE 0 to 65536 --Zaehler fuer die Anzahl der nicht verarbeitbaren Messungen waehrend die Daten geasammelt wurden
  );
end entity DataCollector;


architecture behave of DataCollector is
  signal Step : integer RANGE 0 to 15 := 0;      --aktueller Zustand der FSM
  signal NextStep : integer RANGE 0 to 15 := 0;  --naechster Zustand der FSM
  signal CurrentEntry : integer RANGE 0 to (BufferSize+1) := 0;
  signal iCurrentEntry : integer RANGE 0 to (BufferSize+1) := 0;
  signal CntRejectedDataFiFo1 : integer RANGE 0 to 65536 := 0;
  signal iCntRejectedDataFiFo1 : integer RANGE 0 to 65536 := 0;
  signal CntRejectedDataFiFo2 : integer RANGE 0 to 65536 := 0;
  signal iCntRejectedDataFiFo2 : integer RANGE 0 to 65536 := 0;
  signal FiFo1 : DataSampleBuffer(BufferSize downto 0) := (others => (others => 0));--Buffer1 zum zwischenspeichern der eingehenden Daten
  signal iFiFo1 : DataSampleBuffer(BufferSize downto 0) := (others => (others => 0));
  signal FiFo2 : DataSampleBuffer(BufferSize downto 0) := (others => (others => 0));--Buffer2 zum zwischenspeichern der eingehenden Daten
  signal iFiFo2 : DataSampleBuffer(BufferSize downto 0) := (others => (others => 0));
BEGIN





  --Sammelt die Eingangswerte
  CollectData: process(Reset, Clk)
  BEGIN
    IF (Reset = '1') THEN
		TextGeneratorTrigger <= '0';
		iCurrentEntry <= 0;
		FiFo <= (others => (others => 0));
		iFiFo1 <= (others => (others => 0));
		iFiFo2 <= (others => (others => 0));
		CntRejectedData <= 0;
		iCntRejectedDataFiFo1 <= 0;
      iCntRejectedDataFiFo2 <= 0;
	ELSIF (rising_edge(Clk)) THEN
		CASE Step IS
			WHEN 0 =>
				--Grundzustand
				TextGeneratorTrigger <= '0';
				iCurrentEntry <= 0;
				FiFo <= (others => (others => 0));
				iFiFo1 <= (others => (others => 0));
				iFiFo2 <= (others => (others => 0));
				CntRejectedData <= 0;
				iCntRejectedDataFiFo1 <= 0;
				iCntRejectedDataFiFo2 <= 0;
			WHEN 1 =>
				--FiFo1: Warten auf Daten vom Sensor
				TextGeneratorTrigger <= '0';
				iCurrentEntry <= CurrentEntry;
				FiFo <= FiFo2;
				iFiFo1 <= FiFo1;
				iFiFo2 <= FiFo2;
				CntRejectedData <= CntRejectedDataFiFo2;
				iCntRejectedDataFiFo1 <= CntRejectedDataFiFo1;
				iCntRejectedDataFiFo2 <= CntRejectedDataFiFo2;
			WHEN 2 =>
				--FiFo1: Anfuegen der Daten
				TextGeneratorTrigger <= '0';
				iCurrentEntry <= iCurrentEntry + 1;
				FiFo <= FiFo2;
				iFiFo1(CurrentEntry).acc_x <= acc_x;
            iFiFo1(CurrentEntry).acc_y <= acc_y;
            iFiFo1(CurrentEntry).acc_z <= acc_z;
				iFiFo2 <= FiFo2;
				CntRejectedData <= CntRejectedDataFiFo2;
				iCntRejectedDataFiFo1 <= CntRejectedDataFiFo1;
				iCntRejectedDataFiFo2 <= CntRejectedDataFiFo2;
			WHEN 3 =>
				--Wartet auf data_valid  '0'
				TextGeneratorTrigger <= '0';
				iCurrentEntry <= CurrentEntry;
				FiFo <= FiFo2;
				iFiFo1 <= FiFo1;
				iFiFo2 <= FiFo2;
				CntRejectedData <= CntRejectedDataFiFo2;
				iCntRejectedDataFiFo1 <= CntRejectedDataFiFo1;
				iCntRejectedDataFiFo2 <= CntRejectedDataFiFo2;
			WHEN 4 =>
				--FiFo1: Daten muessen verworfen werden
				TextGeneratorTrigger <= '0';
				iCurrentEntry <= CurrentEntry;
				FiFo <= FiFo2;
				iFiFo1 <= FiFo1;
				iFiFo2 <= FiFo2;
				CntRejectedData <= CntRejectedDataFiFo2;
				iCntRejectedDataFiFo1 <= CntRejectedDataFiFo1 + 1;
				iCntRejectedDataFiFo2 <= CntRejectedDataFiFo2;
			WHEN 5 =>
				--Ausgabe der FiFo1
				TextGeneratorTrigger <= '1';
				iCurrentEntry <= 0;
				FiFo <= FiFo1;
				iFiFo1 <= FiFo1;
				iFiFo2 <= FiFo2;
				CntRejectedData <= CntRejectedDataFiFo1;
				iCntRejectedDataFiFo1 <= CntRejectedDataFiFo1;
				iCntRejectedDataFiFo2 <= CntRejectedDataFiFo2;
			WHEN 11 =>
				--FiFo2: Warten auf Daten vom Sensor
				TextGeneratorTrigger <= '0';
				iCurrentEntry <= CurrentEntry;
				FiFo <= FiFo1;
				iFiFo1 <= FiFo1;
				iFiFo2 <= FiFo2;
				CntRejectedData <= CntRejectedDataFiFo1;
				iCntRejectedDataFiFo1 <= CntRejectedDataFiFo1;
				iCntRejectedDataFiFo2 <= CntRejectedDataFiFo2;
			WHEN 12 =>
				--FiFo2: Anfuegen der Daten
				TextGeneratorTrigger <= '0';
				iCurrentEntry <= iCurrentEntry + 1;
				FiFo <= FiFo1;
				iFiFo1 <= FiFo1;
				iFiFo2(CurrentEntry).acc_x <= acc_x;
            iFiFo2(CurrentEntry).acc_y <= acc_y;
            iFiFo2(CurrentEntry).acc_z <= acc_z;
				CntRejectedData <= CntRejectedDataFiFo1;
				iCntRejectedDataFiFo1 <= CntRejectedDataFiFo1;
				iCntRejectedDataFiFo2 <= CntRejectedDataFiFo2;
			WHEN 13 =>
				--Wartet auf data_valid  '0'
				TextGeneratorTrigger <= '0';
				iCurrentEntry <= CurrentEntry;
				FiFo <= FiFo1;
				iFiFo1 <= FiFo1;
				iFiFo2 <= FiFo2;
				CntRejectedData <= CntRejectedDataFiFo1;
				iCntRejectedDataFiFo1 <= CntRejectedDataFiFo1;
				iCntRejectedDataFiFo2 <= CntRejectedDataFiFo2;
			WHEN 14 =>
				--FiFo2: Daten muessen verworfen werden
				TextGeneratorTrigger <= '0';
				iCurrentEntry <= CurrentEntry;
				FiFo <= FiFo1;
				iFiFo1 <= FiFo1;
				iFiFo2 <= FiFo2;
				CntRejectedData <= CntRejectedDataFiFo1;
				iCntRejectedDataFiFo1 <= CntRejectedDataFiFo1;
				iCntRejectedDataFiFo2 <= CntRejectedDataFiFo2 + 1;
			WHEN 15 =>
				--Ausgabe der FiFo2
				TextGeneratorTrigger <= '1';
				iCurrentEntry <= 0;
				FiFo <= FiFo2;
				iFiFo1 <= FiFo1;
				iFiFo2 <= FiFo2;
				CntRejectedData <= CntRejectedDataFiFo2;
				iCntRejectedDataFiFo1 <= CntRejectedDataFiFo1;
				iCntRejectedDataFiFo2 <= CntRejectedDataFiFo2;
			WHEN OTHERS =>
				TextGeneratorTrigger <= '0';
				iCurrentEntry <= 0;
				FiFo <= (others => (others => 0));
				iFiFo1 <= (others => (others => 0));
				iFiFo2 <= (others => (others => 0));
				CntRejectedData <= 0;
				iCntRejectedDataFiFo1 <= 0;
				iCntRejectedDataFiFo2 <= 0;
			END CASE;
		END IF;  
  END process CollectData;
  
  CollectDataNextState: process(Reset, Clk, EN, Step, CurrentEntry, data_valid, TextGeneratorReady)
  BEGIN
		IF Reset = '1' THEN
		  NextStep <= 0;
		ELSIF (rising_edge(Clk)) THEN
		  NextStep <= Step;
		  IF (EN = '1') THEN
				CASE Step IS
					WHEN 0 =>
						NextStep <= 1;	--Grundzustand
					WHEN 1 =>
						IF (CurrentEntry > BufferSize) AND (TextGeneratorReady = '1') THEN NextStep <= 5; END IF;  --FiFo1 Voll, ausgabe bereit
						IF (data_valid = '1') AND (CurrentEntry <= BufferSize) THEN NextStep <= 2; END IF; --Neue Daten vorhanden, In der FiFo ist genuegend Platz fuer einen weiteren Eintrag
						IF (data_valid = '1') AND (CurrentEntry > BufferSize) THEN NextStep <= 4; END IF;  --Neue Daten vorhanden, die FiFo ist gefuellt kein weitere Eintraege Moeglich
					WHEN 2 =>
						NextStep <= 3;
					WHEN 3 =>
						IF (data_valid = '0') THEN NextStep <= 1; END IF;
					WHEN 4 =>
						NextStep <= 3;
					WHEN 5 => 
						IF (TextGeneratorReady = '0') THEN NextStep <= 11; END IF;--Ausgabe FiFo1
					WHEN 11 =>
						IF (CurrentEntry > BufferSize) AND (TextGeneratorReady = '1') THEN NextStep <= 15; END IF;  --FiFo2 Voll, ausgabe bereit
						IF (data_valid = '1') AND (CurrentEntry <= BufferSize) THEN NextStep <= 12; END IF; --Neue Daten vorhanden, In der FiFo ist genuegend Platz fuer einen weiteren Eintrag
						IF (data_valid = '1') AND (CurrentEntry > BufferSize) THEN NextStep <= 14; END IF;  --Neue Daten vorhanden, die FiFo ist gefuellt kein weitere Eintraege Moeglich
					WHEN 12 =>
						NextStep <= 13;
					WHEN 13 =>
						IF (data_valid = '0') THEN NextStep <= 11; END IF;
					WHEN 14 =>
						NextStep <= 13;
					WHEN 15 => 
						IF (TextGeneratorReady = '0') THEN NextStep <= 1; END IF;--Ausgabe FiFo2
					WHEN OTHERS =>
						NextStep <= 0;
				END CASE;
			END IF;
		END IF;
  END process CollectDataNextState;
  Step <= NextStep; 
  CurrentEntry <= iCurrentEntry;
  CntRejectedDataFiFo1 <= iCntRejectedDataFiFo1;
  CntRejectedDataFiFo2 <= iCntRejectedDataFiFo2;
  FiFo1 <= iFiFo1;
  FiFo2 <= iFiFo2;
end architecture behave;
