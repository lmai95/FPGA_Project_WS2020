# signal_processing

Die Signalverarbeitung erhält gemessene Beschleunigungsdaten von der SPI-Schnittstelle und verarbeitet diese.

Die Daten werden in einen Zwischenspeicher geschoben, welcher die Daten als ASCII-Werte an eine UART-Schnittstelle übergibt, oder als zweiten Datenpfad an eine Bildsignalberechnung zur anschließenden Ausgabe an einer VGA-Schnittstelle.

Die Daten werden als folgende ASCII Zeichenfolge ausgegeben:
**"x:+00000 y:+00000 z:ETX+00000 LF CR"**

*Anmerkung: "+" kann auch "-" sein und pro Achse werden jeweils 5 Datenbits übertragen*

Nachfolgend die Schnittstellen aus Sicht der Signalverarbeitung:


## --------------------------Sensor Modul----------------------------------

Eingänge:

* **EN** 	        : std_logic = 1 {Enable Signal}
* **Reset**       :	std_logic = 0 {Reset Signal}
* **Clk**         :	std_logic     {Clock Signal}
* **data_valid**  : std_logic     {valide Daten liegen am Ausgang der SPI-Schnittstelle an}

* **acc_x**       : signed integer {in m/s²}
* **acc_y**     	: signed integer {in m/s²}
* **acc_z**       : signed integer {in m/s²}

## -------------------------------UART -------------------------------------

Eingänge:

* **TX_BUSY**    : std_logic {Busy Signal des UART}

**NICHT IMPLEMENTIERT:**
* RX_EN
* RX_DATA[]
* RX_ERROR


Ausgänge:

* **TX_EN**      : std_logic = 0                 {Enable Signal des UART}
* **TX_DATA[]**  : std_logic_vector[7..0] = x00  {Daten zum UART}

**NICHT IMPLEMENTIERT:**
* RX_BUSY

## -------------------------------VGA --------------------------------------

Eingänge:

Ausgänge:

* **Clear**      : std_logic = 0                 {synchron. Clear Signal}
* **Clk**        : std_logic                     {Clock Signal}
* **TX_EN**      : std_logic = 0                 {Enable Signal des UART}
* **TX_DATA[]**  : std_logic_vector[7..0] = x00  {Daten zum UART}
