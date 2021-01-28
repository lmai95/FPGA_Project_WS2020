# Sensor Interface

Das Modul icm_20948 bildet die Schnittstelle zwischen dem Beschleunigungssensor ICM20948
und der Datenverarbeitung.

## Schnittstelle zu Hardware

|     Name    | Datenrichtung |  Datentyp |           Beschreibung           |
|:-----------:|:-------------:|:---------:|:--------------------------------:|
| i_board_clk |     input     | std_logic | Haupt-Taktsiganl des Designs     |
| o_MOSI      |     output    | std_logic | Daten von SPI Masters, zu Sensor |
| i_MISO      |     input     | std_logic | Daten zu SPI Master, von Sensor  |
| o_CLK       |     output    | std_logic | SPI Taktsignal                   |
| o_CS        |     output    | std_logic | SPI-Chipselect, low-active       |
| i_Interrupt |     input     | std_logic | Interrpt von Sensor              |

## Schnittstelle zu Datenverarbeitung

|    Name   | Datenrichtung |  Datentyp |              Beschreibung             |
|:---------:|:-------------:|:---------:|:-------------------------------------:|
| o_Accel_X |     output    |  integer  | Beschleunigung X-Achse in m/s^2       |
| o_Accel_Y |     output    |  integer  | Beschleunigung Y-Achse in m/s^Y       |
| o_Accel_Z |     output    |  integer  | Beschleunigung Z-Achse in m/s^2       |
| o_DV      |     output    | std_logic | Aktiv wenn neue Daten verfuegbar sind |

Die Daten der Beschleunigung stehen am Ausgang des Moduls als 16-bit großer,
vorzeichenbehafteter Integer zur Verfügung. Die Dezimalstelle wird fest nach zwei Stellen
gesetzt.

Beispiel:   o_Accel_X = 1205 -> Beschl. in X-Achse: 12.05 m/s^2

Das Verhalten des Sensors kann anhand einiger Konfigurationsregister, die zu Beginn der
Messung gesetzt werden, angepasst werden. Die Register werden anhand von gesetzten
Generic-Daten berechnet. Auch die Geschwindigkeit der SPI-Schnittstelle
kann auf diese Weise angepasst werden.

## Verfügbare Einstellungem des Moduls

|      Name      | Datentyp |                 Beschreibung                 |
|:--------------:|:--------:|:--------------------------------------------:|
| BOARD_CLK_FREQ |  integer | Haupt-Takt der FPGA Hardware in Hz           |
| SPI_FREQ       |  integer | Frequenz der SPI-Schnittstelle in kHz        |
| SAMPLERATE     |  integer | Sample Rate des Sensors in Hz (1Hz - 1225Hz) |
| SENSOR_RANGE   |  integer | Sensor Mess-Reichweite in g (2,4,8,16)       |