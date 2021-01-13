library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DataCollector is
  generic(
	 FreeRunning : std_logic := '0'	--Bei '1' FreeRunning-Mode: Daten die nicht verarbeitet werden koennen werden verworfen die Datenerfassung wird natlos fortgesetzt
												--Bei '0' Sampling-Mode: Sobald ein Datensatz nicht erfasst werden kann stoppt die Datenerfassung bis die FiFo ausgegbe wurde, PrintRejectedData wird auf '1' gesetzt, die Datenerfassung wird fortgesetzt
  );
  port(
    EN 	  	: in std_logic := '1'; --Enable Signal des DataCollector
    Reset 	: in std_logic := '0'; --Reset Signal des DataCollector
    Clk   	: in std_logic;        --Taktsignal des DataCollector

    data_valid : in std_logic;  						--data valid des Sensor Kontroll-Modul
    acc_x 		 : in integer RANGE -32768 to 32767; 	--x-achse des Sensor Kontroll-Modul; in m^2
    acc_y 		 : in integer RANGE -32768 to 32767; 	--y-achse des Sensor Kontroll-Modul; in m^2
    acc_z 		 : in integer RANGE -32768 to 32767; 	--z-achse des Sensor Kontroll-Modul; in m^2

    FiFoEmpty : in std_logic;			--FiFo ist leer
	 FiFoFull : in std_logic;			--FiFo ist voll
	 FiFoWrreq : out std_logic;		--FiFo Schreibanforderung
    FiFoData : out STD_LOGIC_VECTOR (47 DOWNTO 0) := (others => '0'); --Eingangs Daten der FiFo (acc_x, acc_y, acc_z)
    PrintRejectedData : out std_logic := '0';			--Bei '1': Die Anzahl der nicht verarbeitbaren Messungen (RejectedData) soll ausgaben werden
	 RejectedData : out integer RANGE 0 to 65535 := 0	--Zaehler fuer die Anzahl der nicht verarbeitbaren Messungen waehrend die Daten geasammelt wurden
  );
end entity DataCollector;


architecture behave of DataCollector is
  signal Step : integer RANGE 0 to 6 := 0;      				--aktueller Zustand der FSM
  signal NextStep : integer RANGE 0 to 6 := 0;  				--naechster Zustand der FSM
  
  signal CntRejectedData : integer RANGE 0 to 65535 := 0;	--Anzahl der Datensaetze die Verworfen werden mussten
  signal iCntRejectedData : integer RANGE 0 to 65535 := 0;
BEGIN
  --Sammelt die Eingangswerte und legt sie in der FiFo in der Reihenfolge: acc_x, acc_y, acc_z ab.
  --Wenn es dazu kommt dass neue Eingangswerte vorhanden sind aber kein Platz in der FiFo verfuegbar ist werden die Daten verworfen.
  --Es werden nur Messsdaten die zeitlich direkt hintereinander eingeganen sind ausgegeben. 
  --Falls ein Datensatz verworfen werden musste werden alle weitere eingehenden Daten verworfen bis die FiFo komplett ausgegeb wurde.
  --Anschliesend wird ein Hinweis ausgegeben wie viele Daten nicht verarbeitet werden konnten und ein neues "Sample" wird ausgegeben.	
  CollectData: process(Reset, Clk)
  BEGIN
   IF (Reset = '1') THEN
		FiFoWrreq <= '0';
		FiFoData <= (others => '0');
		PrintRejectedData <= '0';
		iCntRejectedData <= 0;
	ELSIF (rising_edge(Clk)) THEN
		CASE Step IS
			WHEN 0 =>
				--Warten auf Daten vom Sensor
				FiFoWrreq <= '0';
				FiFoData <= (others => '0');
				PrintRejectedData <= '0';
				iCntRejectedData <= CntRejectedData;
			WHEN 1 =>
				--Einfuegen der Daten in FiFo
				FiFoWrreq <= '1';
				FiFoData <= (std_logic_vector(to_signed(acc_x, 16))) & (std_logic_vector(to_signed(acc_y, 16))) & std_logic_vector(to_signed(acc_z, 16));
				PrintRejectedData <= '0';
				iCntRejectedData <= 0;
			WHEN 2 =>
				--Wartet auf data_valid  '0'
				FiFoWrreq <= '0';
				FiFoData <= (std_logic_vector(to_signed(acc_x, 16))) & (std_logic_vector(to_signed(acc_y, 16))) & std_logic_vector(to_signed(acc_z, 16));
				PrintRejectedData <= '0';
				iCntRejectedData <= CntRejectedData;
			WHEN 3 =>
				--Daten muessen verworfen werden
				FiFoWrreq <= '0';
				FiFoData <= (others => '0');
				PrintRejectedData <= '0';
				iCntRejectedData <= CntRejectedData + 1;
			WHEN 4 =>
				--Sampling-Mode: Wartet auf data_valid  '0'
				FiFoWrreq <= '0';
				FiFoData <= (others => '0');
				PrintRejectedData <= '0';
				iCntRejectedData <= CntRejectedData;
			WHEN 5 =>
				--Sampling-Mode: Wartet bis alle Daten in FiFo ausgegeben sind
				FiFoWrreq <= '0';
				FiFoData <= (others => '0');
				PrintRejectedData <= '0';
				iCntRejectedData <= CntRejectedData;
			WHEN 6 =>
				--Sampling-Mode: FiFo ist wieder frei
				FiFoWrreq <= '0';
				FiFoData <= (others => '0');
				PrintRejectedData <= '1';
				iCntRejectedData <= CntRejectedData;
				RejectedData <= CntRejectedData;
			END CASE;
		END IF;  
  END process CollectData;
  
  CollectDataNextState: process(Reset, Clk, EN, Step, data_valid, FiFoFull)
  BEGIN
		IF Reset = '1' THEN
		  NextStep <= 0;
		ELSIF (rising_edge(Clk)) THEN
		  NextStep <= Step;
		  IF (EN = '1') THEN
				CASE Step IS
					WHEN 0 =>
						IF (data_valid = '1') AND (FiFoFull = '0') THEN NextStep <= 1; END IF; --Neue Daten vorhanden, In der FiFo ist genuegend Platz fuer einen weiteren Eintrag
						IF (data_valid = '1') AND (FiFoFull = '1') THEN NextStep <= 3; END IF; --Neue Daten vorhanden, die FiFo ist gefuellt kein weitere Eintraege Moeglich
					WHEN 1 =>
						NextStep <= 2;					
					WHEN 2 =>
						IF (data_valid = '0') THEN NextStep <= 0; END IF;
					WHEN 3 =>
						IF (FreeRunning = '1') THEN NextStep <= 4; END IF; --FreeRunning-Mode
						IF (FreeRunning = '0') THEN NextStep <= 4; END IF; --Sampling-Mode
					WHEN 4 => 
						IF (data_valid = '0') THEN NextStep <= 5; END IF;
					WHEN 5 =>	
						IF (data_valid = '1') THEN NextStep <= 3; END IF;	--Neue Daten vorhanden 
						IF (FiFoEmpty = '1') THEN NextStep <= 6; END IF;	--FiFo ist leer und kann mit neuen Daten befuellt werden
					WHEN 6 =>
						NextStep <= 0;
					WHEN OTHERS =>
						NextStep <= 0;
				END CASE;
			END IF;
		END IF;
  END process CollectDataNextState;
  Step <= NextStep; 
  CntRejectedData <= iCntRejectedData;
end architecture behave;
