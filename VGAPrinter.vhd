library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------------------------
--	VGA Printer bereitet die SPI Daten für die VGA Schnittstelle vor
-- Dazu zählt eine Begrenzung der Werte auf +- 9999
--------------------------------------------------------------------
entity VGAPrinter is
	port(
		EN 	  	: in std_logic := '1'; --Enable Signal der VGA
		Reset 	: in std_logic := '0'; --Reset Signal der VGA
		Clk   	: in std_logic;

		data_valid : in std_logic;						         --data valid des Sensor Kontroll-Modul
		acc_x 		 : in integer RANGE -32768 to 32767; 	--x-achse des Sensor Kontroll-Modul in cm/s^2 		7FFF = 32767
		acc_y 		 : in integer RANGE -32768 to 32767; 	--y-achse  "     "           "       "   "	
		acc_z 		 : in integer RANGE -32768 to 32767; 	--z-achse  "     "           "       "   "	

		data_valid_in : out std_logic := '0';	            --Ausgabe von data valid an das VGA-Modl
		x_in : out integer range -9999 to 9999 := 0;       --Ausgabe der Beschleunigung der x-achse in cm/s^2 an das VGA-Modul
		y_in : out integer range -9999 to 9999 := 0;       --	  " 	  " 			"			"  y-achse  "   "     "  "     "
		z_in : out integer range -9999 to 9999 := 0        --	  " 	  " 			"			"  z-achse  "   "     "  "     "
	);
end entity VGAPrinter;

architecture behave of VGAPrinter is
  signal idata_valid_in : std_logic := '0';					--internes data_valid Signal
  signal ix_in : integer range -9999 to 9999 := 0;			--interne x, y, z Signale
  signal iy_in : integer range -9999 to 9999 := 0;
  signal iz_in : integer range -9999 to 9999 := 0;
BEGIN
    LimitValues: process(Reset, Clk)
    BEGIN
      IF (Reset = '1') THEN						--im Resetfall interne Beschleunigungswerte reseten
        idata_valid_in <= '0';
        ix_in <= 0;
        iy_in <= 0;
        iz_in <= 0;
      ELSIF (rising_edge(Clk)) THEN				--bei steigender Flanke Abfrage der x-Beschleunigungswerte
        IF (acc_x >= 9999) THEN
          ix_in <= 9999;
        ELSIF (acc_x <= -9999) THEN				--falls Wert größer/gleich 9999, dann wird dieser auf +9999 limitiert
          ix_in <= -9999;							--falls Wert kleiner/gleich -9999, dann wird dieser auf -9999 limitiert
        ELSE											--liegt der Wert zwischen den Grenzen, wird dieser ohen Konvertierung ausgegeben
          ix_in <= acc_x;							
        END IF;

        IF (acc_y >= 9999) THEN					--bei steigender Flanke Abfrage der y-Beschleunigungswerte
          iy_in <= 9999;
        ELSIF (acc_y <= -9999) THEN				
          iy_in <= -9999;
        ELSE
          iy_in <= acc_y;
        END IF;

        IF (acc_z >= 9999) THEN					--bei steigender Flanke Abfrage der z-Beschleunigungswerte
          iz_in <= 9999;
        ELSIF (acc_z <= -9999) THEN
          iz_in <= -9999;
        ELSE
          iz_in <= acc_z;
        END IF;
        idata_valid_in <= data_valid;
      END IF;
    END process LimitValues;

    data_valid_in <= idata_valid_in;			--Ausgangssignale beschreiben
    x_in <= ix_in;
    y_in <= iy_in;
    z_in <= iz_in;
end architecture behave;
