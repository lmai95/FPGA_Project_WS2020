
# FPGA Project Winter Semester 2020
Hier entsteht das FPGA Project des Elektrotechnik-Kurses der HS Aalen im Wintersemester 2020.

## Kurzbeschreibung:
Orientierung in 9-Achsen (3-Achsen-Gyroskop, 3-Achsen-Gyroskop, 3-Achsen-Kompass) messen und die Daten sowohl grafisch über die VGA Schnittstelle darstellen als auch über RS232 an einen PC weitergeben.

![Prinzip](https://raw.githubusercontent.com/lmai95/FPGA_Project_WS2020/main/documentation/pics/Beschl-VGA.jpg)
## Sensor
Sensor soll das Modul Adafruit TDK InvenSense ICM-20948 9-DoF IMU sein, da dieser die Möglichkeit bietet, zusätzlich zu Beschleunigung auch noch Rotation und Erdmagnetfeld ausgewertet werden kann.
![Senor Modul by Adafruit](https://cdn-learn.adafruit.com/assets/assets/000/093/833/medium800/sensors_edit4554_iso_ORIG_2020_07.png?1596657840)


## Anbindung des TDK ICM-20948 9-Axis
Der Sensor kann sowohl mit 7MHz SPI als auch mit 400kHz I2C angesteuert werden (die SPI Schnittstelle wird gewählt da diese einfacher zu implementieren ist).

##


## VGA Ausgabe
Auf dem 

### Auflösung
Da auf dem DE0 Board ein 50 MHz Oszillator verbaut ist wird eine Auflösung von 800 x 600 mit einer Frequenz von 72 Hz gewählt.
siehe [tinyvga.com](http://tinyvga.com/vga-timing/800x600@72Hz)
### Framebuffer


### Quellen
#### Ben Eater - The world's worst video card?
[![The world's worst video card?](http://img.youtube.com/vi/l7rce6IQDWs/0.jpg)](http://www.youtube.com/watch?v=l7rce6IQDWs "")
### VGA Timing by Digikey
![Timinig](https://www.digikey.com/eewiki/download/attachments/15925278/signal_timing_diagram.jpg?version=1&modificationDate=1368216804290&api=v2)
