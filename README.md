# signal_processing

Die Signalverarbeitung erhält gemessene Beschleunigungsdaten von der SPI-Schnittstelle und verarbeitet diese.

Die Daten werden in einen Zwischenspeicher geschoben, welcher die Rohdaten  an eine UART-Schnittstelle übergibt oderals zweiten Datenpfad an eine Bildsignaleberechnung zur anschließenden Ausgabe an einer VGA-Schnittstelle.

Nachfolgend die Schnittstelle aus Sicht der Signalverarbeitung:


## --------------------------Sensor Modul----------------------------------

Eingänge:

* **EN** 	  : std_logic = 1 {Enable Signal}
* **Reset** :	std_logic = 0 {Reset Signal}
* **Clk**   :	std_logic     {Clock Signal}

* **acc_x** : signed integer range) {in m/s²}
* **acc_y** : signed integer range) {in m/s²}
* **acc_z** : signed integer range) {in m/s²}



## -------------------------------UART -------------------------------------

Eingänge:

* **RX_EN** : Bit
* **RX_DATA[N...0]**
* **RX_ERROR**
* **TX_BUSY**         : std_logic {Busy Signal des UART}


Ausgänge:

* **CLK**
* **Reset**
* **TX_EN**           : std_logic = 0 {Enable Signal des UART}
* **TX_DATA[N...0]**  : std_logic_vector[7..0] = x00 {Daten zum UART}
* **RX_BUSY**

## -------------------------------VGA --------------------------------------

Eingänge:

Ausgänge:
