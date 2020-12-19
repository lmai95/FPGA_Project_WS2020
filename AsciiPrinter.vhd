library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AsciiPrinter is
generic(
  BufferSize : integer := 9   --Legt die größe der beiden Buffer fest
);
port(
  EN : in std_logic := '1';    --Enable Signal des AsciiPrinters
  Reset : in std_logic := '0'; --Reset Signal des AsciiPrinters

  data_valid : in std_logic; --data valid des Sensor Kontroll-Modul
  acc_x : in signed integer; --x-achse des Sensor Kontroll-Modul; in m^2; ToDo Range
  acc_y : in signed integer; --y-achse des Sensor Kontroll-Modul; in m^2; ToDo Range
  acc_z : in signed integer; --z-achse des Sensor Kontroll-Modul; in m^2; ToDo Range
  TX_BUSY : in std_logic;                             --TX_Busy der UART
  TX_EN : out std_logic := '0';                       --TX_EN der UART
  TX_DATA : out std_logic_vector(7 downto 0):= x"00"  --Eingangsbyte der UART; LSB hat Index 0
);
end entity  AsciiPrinter;


architecture behave of  AsciiPrinter is
  type DataSample is record
    acc_x, acc_y, acc_z : signed integer;
  end record;
  type DataSampleBuffer is array (BufferSize downto 0) of DataSample;

  signal SumRejectedDataFiFo1 : signed integer := 0;--Zähler für die Anzahl der nicht verarbeitbaren Messungen während Daten in FiFo1 geasammelt wurden
  signal SumRejectedDataFiFo2 : signed integer := 0;--Zähler für die Anzahl der nicht verarbeitbaren Messungen während Daten in FiFo2 geasammelt wurden
  signal FiFo1 : DataSampleBuffer;                  --Buffer1 zum zwischenspeichern der eingehenden Daten
  signal FiFo2 : DataSampleBuffer;                  --Buffer2 zum zwischenspeichern der eingehenden Daten

  signal PrepareNextLineActiv : std_logic := '0';     --Wenn '0' kein Buffer wird ausgegeben, wenn '1' ein Buffer wird ausgegebn
  signal PrepareNextLineReady : std_logic := '1';     --Bei '1' PrepareNextLine kann den Inhalt des nächstens Buffers Übertragen
  signal PrepareNextLineSelectFiFo1 : boolean := true;--true: Prozess PrepareNextLine nutzt FiFo1, false: PrepareNextLine nutzt FiFo2

  signal ByteWhiteOutputBuffer : std_logic_vector(224 downto 0) := (others =>'0');--Speicher für die Ausgabe der nächsten Zeile; maximal 28 ASCII-Zeichen: 3xacc=18 + Zeilenumbruch=2 + Leerzeichen=2 + Text=6
  signal OutputActiv : std_logic := '0';                                          --Wenn '0' keine ausgabe an UART, wenn '1' ausgabe an UART
  signal ByteWhiteOutputReady : std_logic := '1';                                 --Bei '1' Prozess ByteWhiteOutput kann neue Daten Übertragen
  signal iTX_EN std_logic := '0';                                                 --internes Signal für den Ausgang TX_EN
  signal iTX_DATA : std_logic_vector(7 downto 0) := x"00";                        --internes Signal für den Ausgang TX_DATA


  --Wandelt eine signed Integer Zahl in ASCI Zeichen um. Annahme 16Bit integer daher mit Vorzeichen 6-ASCI Zeichen
  function IntToStr ( int_input : in signed integer ) return std_logic_vector(48 downto 0) is
    variable temp_bin_output : std_logic_vector(48 downto 0);
    variable uint_input : integer
    variable Digit : integer;
  BEGIN
    uint_input = To_integer(int_input);
    FOR cnt in 0 to 5 LOOP
      Digit = uint_input%10;
      uint_input = uint_input/10;
      CASE Digit IS
        WHEN 0 =>
          temp_bin_output := temp_bin_output+shift_left(B"00110000", cnt*8);
        WHEN 1 =>
          temp_bin_output := temp_bin_output+shift_left(B"00110001", cnt*8);
        WHEN 2 =>
          temp_bin_output := temp_bin_output+shift_left(B"00110010", cnt*8);
        WHEN 3 =>
          temp_bin_output := temp_bin_output+shift_left(B"00110011", cnt*8);
        WHEN 4 =>
          temp_bin_output := temp_bin_output+shift_left(B"00110100", cnt*8);
        WHEN 5 =>
          temp_bin_output := temp_bin_output+shift_left(B"00110101", cnt*8);
        WHEN 6 =>
          temp_bin_output := temp_bin_output+shift_left(B"00110110", cnt*8);
        WHEN 7 =>
          temp_bin_output := temp_bin_output+shift_left(B"00110111", cnt*8);
        WHEN 8 =>
          temp_bin_output := temp_bin_output+shift_left(B"00111000", cnt*8);
        WHEN 9 =>
          temp_bin_output := temp_bin_output+shift_left(B"00111001", cnt*8);
      END CASE;
    END LOOP;
    --Ergänzt das Vorzeichen
    IF (int_input < 0) THEN
      btemp_bin_output(48 downto 40) := B"00101101"; --Text: "-"
    ELSIF
      temp_bin_output(48 downto 40) := B"00101011"; --Text: "+""
    END IF;
    return temp_bin_output;
  end function IntToStr;


BEGIN
  --Sammelt die Eingangswerte
  CollectData: process(Reset, EN)
    variable CurrentFiFo1 : boolean := true; --true: Sammelt gerade Daten in FiFo1, false: Sammelt gerade Daten in FiFo2
    variable CurrentEntry : integer RANGE 0 to (BufferSize+1) := 0;
  BEGIN
    IF (Reset = '1') THEN
      PrepareNextLineActiv <= '0';
      FiFo1 <= (others => (others => 0));
      FiFo2 <= (others => (others => 0));
    ELSE
      IF (EN = '1') THEN
        IF (rising_edge(data_valid)) THEN
          IF (CurrentFiFo) THEN
            --Sammelt gerade Daten in FiFo1
            IF (CurrentEntry <= BufferSize) THEN
              --In der FiFo ist genügend Platz für einen weiteren Eintrag
              FiFo1(CurrentEntry).acc_x <= acc_x;
              FiFo1(CurrentEntry).acc_y <= acc_y;
              FiFo1(CurrentEntry).acc_z <= acc_z;
              CurrentEntry := CurrentEntry + 1;
            ELSE
              --Die FiFo ist gefüllt kein weitere Einträge Möglich
              IF (PrepareNextLineReady = '1') THEN
                --Prozess PrepareNextLine ist bereit die FiFo auszugeben
                CurrentFiFo1 := false;
                CurrentEntry := 0;
                SumRejectedDataFiFo2 <= 0;
                PrepareNextLineSelectFiFo1 <= true;
                PrepareNextLineActiv <= '1';
              ELSE
                --Der Prozess PrepareNextLine ist beschäfigt; Messdaten müssen verworfen werden
                SumRejectedDataFiFo1 <= SumRejectedDataFiFo1 + 1;
              END IF;
            END IF;
          ELSE
            --Sammelt gerade Daten in FiFo2
            IF (CurrentEntry <= BufferSize) THEN
              --In der FiFo ist genügend Platz für einen weiteren Eintrag
              FiFo2(CurrentEntry).acc_x <= acc_x;
              FiFo2(CurrentEntry).acc_y <= acc_y;
              FiFo2(CurrentEntry).acc_z <= acc_z;
              CurrentEntry := CurrentEntry + 1;
            ELSE
              --Die FiFo ist gefüllt kein weitere Einträge Möglich
              IF (PrepareNextLineReady = '1') THEN
                --Prozess PrepareNextLine ist bereit die FiFo auszugeben
                CurrentFiFo1 := true;
                CurrentEntry := 0;
                SumRejectedDataFiFo2 <= 1;
                PrepareNextLineSelectFiFo1 <= false;
                PrepareNextLineActiv <= '1';
              ELSE
                --Der Prozess PrepareNextLine ist beschäfigt; Messdaten müssen verworfen werden
                SumRejectedDataFiFo2 <= SumRejectedDataFiFo2 + 1;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;
  END process CollectData;

  --ToDo Ausgabe der beiden Zähler
  --Bereitet die nächste Zeile zur Ausgabe, über den Prozess ByteWhiteOutput, mit den Daten von FiFo1 oder FiFo2 vor
  --Anschließend wird der Prozess ByteWhiteOutput angestoßen. Ist aktiv falls EN = '1' und PrepareNextLineActiv = '1' ist
  --Fomrat der Ausgabe: "x:+/-_____ y:+/-_____ z:+/-_____\n\r"
  --Setzt PrepareNextLineReady auf '1' falls der gesamte inhalt der FiFo ausgegebn wurde
  PrepareNextLine: process(Reset, EN, PrepareNextLineActiv, ByteWhiteOutputReady)
    variable iByteWhiteOutputBuffer : std_logic_vector(224 downto 0) := (others =>'0');
    variable CurrentEntry : integer RANGE 0 to (BufferSize+1) := 0;
  BEGIN
    IF (Reset = '1') THEN
      PrepareNextLineReady <= '1';
      PrepareNextLineActiv <= '0';
      OutputActiv <= '0';
      CurrentEntry := 0;
      iByteWhiteOutputBuffer := (others =>'0');
    ELSE
      IF ((EN = '1') AND (PrepareNextLineActiv = '1')) THEN
        IF(ByteWhiteOutputReady = '1') THEN
          IF (CurrentEntry >= (BufferSize+1)) THEN
            --Alle Einträge im Puffer sind ausgegeben
            CurrentEntry := 0;
            PrepareNextLineReady <= '1';
            PrepareNextLineActiv <= '0';
          ELSE
            --Bereitet die nächste Zeile zur Ausgabe vor und triggert den Prozess ByteWhiteOutput
            PrepareNextLineReady <= '0';
            iByteWhiteOutputBuffer(224 downto 209) := x"783A"; --Text "x:"
            IF (PrepareNextLineSelectFiFo1) THEN
              iByteWhiteOutputBuffer(208 downto 161) := IntToStr(FiFo1(CurrentEntry).acc_x);
            ELSE
              iByteWhiteOutputBuffer(208 downto 161) := IntToStr(FiFo2(CurrentEntry).acc_x);
            END IF;
            iByteWhiteOutputBuffer(160 downto 137) := x"20793A"; --Text " y:"
            IF (PrepareNextLineSelectFiFo1) THEN
              iByteWhiteOutputBuffer(136 downto 89) := IntToStr(FiFo1(CurrentEntry).acc_y);
            ELSE
              iByteWhiteOutputBuffer(136 downto 89) := IntToStr(FiFo2(CurrentEntry).acc_y);
            END IF;
            iByteWhiteOutputBuffer(88 downto 65) := x"207A3A"; --Text " z:"
            IF (PrepareNextLineSelectFiFo1) THEN
              iByteWhiteOutputBuffer(64 downto 16) := IntToStr(FiFo1(CurrentEntry).acc_z);
            ELSE
              iByteWhiteOutputBuffer(64 downto 16) := IntToStr(FiFo2(CurrentEntry).acc_z);
            END IF;
            iByteWhiteOutputBuffer(15 downto 0) := x"0A0D"; --Text "\n\r"
            CurrentEntry := CurrentEntry + 1;
            OutputActiv <= '1';
          END IF;
        END IF;
      ELSE
        OutputActiv <= '0';
      END IF;
    END IF;
    ByteWhiteOutputBuffer <= iByteWhiteOutputBuffer;
  END process PrepareNextLine;

  --ToDo mit clock synchronisieren
  --Gibt die Bytes aus ByteWhiteOutputBuffer einzel an die UART aus, wenn OutputActiv '1' und EN '1' ist
  --Sobald das Zeichen '\r' in ByteWhiteOutputBuffer erkannt wird stoppt die ausgabe
  --Setzt ByteWhiteOutputReady auf '1' wenn alle Bytes ausgegebn wurden
  ByteWhiteOutput: process(Reset, EN, OutputActiv, TX_BUSY)
    variable CurrentByte : integer RANGE 0 to 28 := 0; --Maximal 224 Bit pro Zeile
  BEGIN
    IF (Reset = '1') THEN
      CurrentByte := 0;
      OutputActiv <= '0';
      ByteWhiteOutputReady <= '1';
      iTX_EN <= '0';
      iTX_DATA <= x"00";
    ELSE
      IF (EN = '1' AND OutputActiv = '1') THEN
        IF  (TX_BUSY = '0') THEN
          IF ((CurrentByte >= 28) OR (iTX_DATA = x"0D")) THEN
            --Alle Bytes übertragen
            ByteWhiteOutputReady <= '1';
            OutputActiv <= '0';
            CurrentByte := 0;
          ELSE
            --Überträgt ein Byte
            ByteWhiteOutputReady <= '0';
            iTX_DATA <= ByteWhiteOutputBuffer((ByteWhiteOutputBuffer'RANGE - (8*CurrentByte)) DOWNTO ((ByteWhiteOutputBuffer'RANGE - (8*(CurrentByte+1))));
            CurrentByte := CurrentByte + 1;
          END IF;
        END IF;
        iTX_EN <= '1';
      ELSE
        iTX_EN <= '0';
      END IF;
    END IF;
  END process ByteWhiteOutput;
  iTX_EN <= TX_EN;
  iTX_DATA <= TX_DATA;
end behave;
