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

    data_valid : in std_logic;  --data valid des Sensor Kontroll-Modul
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
  signal data_validLastState : std_logic := '1';
  signal iTextGeneratorTrigger : std_logic := '0';
  signal CurrentEntry : integer RANGE 0 to (BufferSize+1) := 0;
  signal CntRejectedDataFiFo1 : integer RANGE 0 to 65536 := 0;
  signal CntRejectedDataFiFo2 : integer RANGE 0 to 65536 := 0;
  signal UseFiFo1 : std_logic := '1';
  signal FiFo1 : DataSampleBuffer(BufferSize downto 0) := (others => (others => 0));--Buffer1 zum zwischenspeichern der eingehenden Daten
  signal FiFo2 : DataSampleBuffer(BufferSize downto 0) := (others => (others => 0));--Buffer2 zum zwischenspeichern der eingehenden Daten
BEGIN
  --Sammelt die Eingangswerte
  CollectData: process(Reset, EN, data_valid, data_validLastState, TextGeneratorReady)
    variable CurrentFiFo1 : boolean := true; --true: Sammelt gerade Daten in FiFo1, false: Sammelt gerade Daten in FiFo2
  BEGIN
    IF (Reset = '1') THEN
      iTextGeneratorTrigger <= '0';
      UseFiFo1 <= '1';
      CurrentEntry <= 0;
      CntRejectedDataFiFo1 <= 0;
      CntRejectedDataFiFo2 <= 0;
      FiFo1 <= (others => (others => 0));
      FiFo2 <= (others => (others => 0));
    ELSIF (rising_edge(Clk)) THEN
      IF ((EN = '1') AND (data_validLastState = '0') AND (data_valid = '1'))THEN
         IF (CurrentFiFo1) THEN
            --Sammelt gerade Daten in FiFo1
            IF (CurrentEntry <= BufferSize) THEN
              --In der FiFo ist genuegend Platz fuer einen weiteren Eintrag
              FiFo1(CurrentEntry).acc_x <= acc_x;
              FiFo1(CurrentEntry).acc_y <= acc_y;
              FiFo1(CurrentEntry).acc_z <= acc_z;
              CurrentEntry <= CurrentEntry + 1;
            ELSE
              --Die FiFo ist gefuellt kein weitere Eintraege Moeglich
              IF (TextGeneratorReady = '1') THEN
                --Prozess PrepareNextLine ist bereit die FiFo auszugeben
                CurrentFiFo1 := false;
                CurrentEntry <= 0;
                CntRejectedDataFiFo2 <= 0;
                iTextGeneratorTrigger <= '1';
                UseFiFo1 <= '1';
              ELSE
                --Der Prozess PrepareNextLine ist beschaefigt; Messdaten muessen verworfen werden
                CntRejectedDataFiFo1 <= CntRejectedDataFiFo1 + 1;
              END IF;
            END IF;
          ELSE
            --Sammelt gerade Daten in FiFo2
            IF (CurrentEntry <= BufferSize) THEN
              --In der FiFo ist genuegend Platz fuer einen weiteren Eintrag
              FiFo2(CurrentEntry).acc_x <= acc_x;
              FiFo2(CurrentEntry).acc_y <= acc_y;
              FiFo2(CurrentEntry).acc_z <= acc_z;
              CurrentEntry <= CurrentEntry + 1;
            ELSE
              --Die FiFo ist gefuellt kein weitere Eintraege Moeglich
              IF (TextGeneratorReady = '1') THEN
                --Prozess PrepareNextLine ist bereit die FiFo auszugeben
                CurrentFiFo1 := true;
                CurrentEntry <= 0;
                CntRejectedDataFiFo1 <= 0;
                iTextGeneratorTrigger <= '1';
                UseFiFo1 <= '0';
              ELSE
                --Der Prozess PrepareNextLine ist beschaefigt; Messdaten muessen verworfen werden
                CntRejectedDataFiFo2 <= CntRejectedDataFiFo2 + 1;
              END IF;
            END IF;
          END IF;
      END IF;
      data_validLastState <= data_valid;
    END IF;
  END process CollectData;
  FiFo<=FiFo1 WHEN UseFiFo1 = '1' ELSE FiFo2;
  CntRejectedData<=CntRejectedDataFiFo1 WHEN UseFiFo1 = '1' ELSE CntRejectedDataFiFo2;
  TextGeneratorTrigger <= iTextGeneratorTrigger;
end architecture behave;
