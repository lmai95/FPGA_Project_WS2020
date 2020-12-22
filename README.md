# signal_processing

Die Signalverarbeitung erhält entsprechende Beschläunigungsdaten von der SPI-Schnittstelle und verarbeitet diese.
Die Daten werden an einen Zwischenspeicher geschoben, wWlcher  Rohdaten  an die UART-Schnittstelle übergibt oder an eine Berechnung der Bildsignale zur anschließenden Ausgabe an einer VGA-Schnittstelle.

-----Sensor Modul-------------------------
Eingänge:

* x-achse (signed integer range) :in m/s²

* y-achse (signed integer range) :in m/s²

* z-achse (signed integer range) :in m/s²



---------UART ---------------------------

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
