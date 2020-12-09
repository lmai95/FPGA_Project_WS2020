
# FPGA Project Winter Semester 2020
Hier entsteht das FPGA Project des Elektrotechnik-Kurses der HS Aalen im Wintersemester 2020.
Das Project wird auf einem [terasic DE0 Entwicklungsboard](https://www.terasic.com.tw/cgi-bin/page/archive_download.pl?Language=English&No=364&FID=0c266381d75ef92a8291c5bbdd5b07eb) bzw. einem [terasic DE1 Entwicklungsboard](https://www.terasic.com.tw/cgi-bin/page/archive_download.pl?Language=English&No=836&FID=3a3708b0790bb9c721f94909c5ac96d6) implementiert. Als Entwicklungsumgebung wird Quartus II 13.1 bzw. ?? verwendet, die Simulation der Designs erfolgt mit ModelSim Altera 10.1d.

## Kurzbeschreibung des Projekts:
Orientierung bzw. Beschleunigung messen und die Daten sowohl grafisch über die VGA Schnittstelle darstellen als auch über RS232 an einen PC weitergeben.
![Prinzip](https://raw.githubusercontent.com/lmai95/FPGA_Project_WS2020/main/documentation/pics/Beschl-VGA.jpg)
## Sensor
Sensor soll ein Modul von [Adafruit](https://learn.adafruit.com/adafruit-tdk-invensense-icm-20948-9-dof-imu) dessen Herzstück ein [TDK InvenSense ICM-20948 Sensor](https://invensense.tdk.com/products/motion-tracking/9-axis/icm-20948/) ist, da dieser die Möglichkeit bietet, zusätzlich zu Beschleunigung auch noch Rotation und Erdmagnetfeld auszuwerten.
![Senor Modul by Adafruit](https://cdn-learn.adafruit.com/assets/assets/000/093/833/medium800/sensors_edit4554_iso_ORIG_2020_07.png?1596657840)

### Anbindung des TDK ICM-20948
Der Sensor kann sowohl mit 7MHz SPI als auch mit 400kHz I2C angesteuert werden (die SPI Schnittstelle wird gewählt da diese einfacher zu implementieren ist).

## Sensor Interface
Die SPI Schnittstelle wird ...

### SPI

### Kommunikationsmuster

## Signalverarbeitung

## Speicherung

## PC Ausgabe
Hierfür soll eine RS232-Schnittstelle implementiert werden.

## VGA Ausgabe
Auf dem terasic DE0 Board ist ein VGA-Schnittstelle mit drei (RGB)  4 Bit Digital/Analog Converter vorbereitet, diese soll verwendet werden.  Außerdem werden noch h_sync und v_sync Signal benötigt welche ebenfalls bereits vorbereitet sind.![DE0 Board VGA Port](https://raw.githubusercontent.com/lmai95/FPGA_Project_WS2020/interface_video/documentation/pics/VGA_DA_Wandler_DE_0.jpg)
### Auflösung
Da auf dem DE0 Board ein 50 MHz Oszillator verbaut ist wird eine Auflösung von 800 x 600 mit einer Frequenz von 72 Hz gewählt.
siehe [tinyvga.com](http://tinyvga.com/vga-timing/800x600@72Hz)
### VGA Grundlagen
Ein VGA Signal ist stark von dem Funktionsprinzip eines Röhrenmonitors  beeinflusst.

 ![Rasterscan](https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Raster-scan.svg/1280px-Raster-scan.svg.png)

 Abhängig von der imaginären Position des Elektronenstrahls wird auf die jeweiligen Kanäle (Rot Grün Blau) ein analoges Signal (0 bis 0,7 V) geschaltet. Da es es in der in der Röhrentechnik notwendig war den Elektronenstrahl wieder zurück zum Begin der Zeile zu führen, wird auch beim VGA Signal eine Zeit lang nichts übertragen (Blanking Time).    

![Timinig](https://www.digikey.com/eewiki/download/attachments/15925278/signal_timing_diagram.jpg?version=1&modificationDate=1368216804290&api=v2)

Auf Grund der Taktung des h_sync und v_sync Signals kann der Monitor erkennen welche Auflösung gesendet wird.
### Timing für 800 x 600 @ 72Hz
#### Horizontal
|Scanline part	|Pixels	|Time [µs]|
|---:            |:---:    |---:|
|Visible area	  |800	  |16,00       |
|Front porch    |	56	  |1,12     |
|Sync pulse     |	120	  |2,40      |
|Back porch     |	64	  |1,28     |
|Whole line     |	1040  |20,80     |

#### Vertikal
|Frame part	    |Lines	 |Time [µs]|
|---:            |:---:     | ---:      |
|Visible area	  |600	   |12480,00
|Front porch    |	37	   |769,60
|Sync pulse	    |6	     |124,80
|Back porch	    |23	     |478,40
|Whole frame	  |666	   |13852,80

Das Timing wird hierbei mit zwei Zählern erreicht welche von 0 bis 1040 und 0 bis 666 zählen erreicht, abhängig wird das passende Signal an die VGA Schnittstelle ausgegeben.

### Framebuffer
Der Framebuffer besteht mindestens aus drei `800 x 600 x 4 Bit = 1,92Mbit => 240kbyte`  großen Speichern.

Wird dieser Ansatz verfolgt kann nur während des Blankings schreibend auf den Framebuffer zugegriffen werden. Alternativ kann sogenanntes Double-Buffering verwendet werden, d.h. es wird ein Framebuffer A und ein Framebuffer B angelegt. Zu erst wird A dargestellt und B mit neuen Daten beschrieben, nach Abschluss des Frame A folgt die Darstellung von Frame B während A neu beschrieben wird.
### Quellen
#### Ben Eater - The world's worst video card?
[![The world's worst video card?](http://img.youtube.com/vi/l7rce6IQDWs/0.jpg)](http://www.youtube.com/watch?v=l7rce6IQDWs "")
