# signal_processing

Die Signalverarbeitung erhält gemessene Beschleunigungsdaten von der SPI-Schnittstelle und verarbeitet diese.

Die Daten werden in einen Zwischenspeicher geschoben, welcher die Rohdaten  an eine UART-Schnittstelle übergibt oderals zweiten Datenpfad an eine Bildsignaleberechnung zur anschließenden Ausgabe an einer VGA-Schnittstelle.

Nachfolgend die Schnittstelle:

--------------------Sensor Modul-------------------------
Eingänge:

* x-achse (signed integer range) :in m/s²

* y-achse (signed integer range) :in m/s²

* z-achse (signed integer range) :in m/s²



------------------------UART ---------------------------

Eingänge:

* RX_EN (Bit)

* RX_DATA[N...0]

* RX_ERROR

* TX_BUSY


Ausgänge:

* CLK

* Reset

* TX_EN (Bit)

* TX_DATA[N...0]

* RX_BUSY
