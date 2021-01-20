library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity signal_processing is
	generic(
		FreeRunning : std_logic := '0'	--Bei '1' FreeRunning-Mode: Daten die nicht verarbeitet werden koennen werden verworfen die Datenerfassung wird natlos fortgesetzt
																		--Bei '0' Sampling-Mode: Sobald ein Datensatz nicht erfasst werden kann stoppt die Datenerfassung bis die FiFo ausgegbe wurde, PrintRejectedData wird auf '1' gesetzt, die Datenerfassung wird fortgesetzt
	);
	port(
		EN 	  	: in std_logic := '1'; --Enable Signal des AsciiPrinters
		Reset 	: in std_logic := '0'; --Reset Signal des AsciiPrinters
		Clk   	: in std_logic;

		data_valid : in std_logic;											--data valid des Sensor Kontroll-Modul
		acc_x 		 : in integer RANGE -32768 to 32767; 	--x-achse des Sensor Kontroll-Modul; in in cm/s^2
		acc_y 		 : in integer RANGE -32768 to 32767; 	--y-achse des Sensor Kontroll-Modul; in in cm/s^2		7FFF = 32767
		acc_z 		 : in integer RANGE -32768 to 32767; 	--z-achse des Sensor Kontroll-Modul; in in cm/s^2
		TX_BUSY 	 : in std_logic;                      			 	--TX_Busy der UART
		TX_EN 	 : out std_logic := '0';                		 		--TX_EN der UART
		TX_DATA 	 : out std_logic_vector(7 downto 0):= x"00"; 	--Eingangsbyte der UART; LSB hat Index 0

		data_valid_in : out std_logic := '0';	              --Ausgabe von data valid an das VGA-Modl
		x_in : out integer range -9999 to 9999 := 0;        --Ausgabe der Beschleunigung der x-achse in cm/s^2 an das VGA-Modul
		y_in : out integer range -9999 to 9999 := 0;        --Ausgabe der Beschleunigung der y-achse in cm/s^2 an das VGA-Modul
		z_in : out integer range -9999 to 9999 := 0         --Ausgabe der Beschleunigung der z-achse in cm/s^2 an das VGA-Modul
	);
end entity signal_processing;

architecture behave of signal_processing is
BEGIN
	UARTHandling: entity work.AsciiPrinter(behave)
	generic map(
		FreeRunning => FreeRunning
	)
	port map(
		EN => EN,    								--Enable Signal
		Reset => Reset, 						--Reset Signal
		Clk => Clk,
		data_valid => data_valid,		--data valid des Sensor Kontroll-Modul
		acc_x => acc_x,							--x-achse des Sensor Kontroll-Modul; in cm/s^2
		acc_y => acc_y,							--y-achse des Sensor Kontroll-Modul; in cm/s^2
		acc_z => acc_y,							--z-achse des Sensor Kontroll-Modul; in cm/s^2
		TX_BUSY => TX_BUSY,         --TX_Busy der UART
		TX_EN => TX_EN,             --TX_EN der UART
		TX_DATA => TX_DATA					--Eingangsbyte der UART; LSB hat Index 0
	);

	VGAHandling: entity work.VGAPrinter(behave)
	port map(
		EN => EN,    										--Enable Signal
		Reset => Reset, 								--Reset Signal
		Clk => Clk,
		data_valid => data_valid,				--data valid des Sensor Kontroll-Modul
		acc_x => acc_x,									--x-achse des Sensor Kontroll-Modul; in cm/s^2
		acc_y => acc_y,									--y-achse des Sensor Kontroll-Modul; in cm/s^2
		acc_z => acc_y,									--z-achse des Sensor Kontroll-Modul; in cm/s^2
		data_valid_in => data_valid_in, --Ausgabe von data valid an das VGA-Modl
		x_in => x_in,										--Ausgabe der Beschleunigung der x-achse in cm/s^2 an das VGA-Modul
		y_in => y_in,										--Ausgabe der Beschleunigung der y-achse in cm/s^2 an das VGA-Modul
		z_in => z_in										--Ausgabe der Beschleunigung der z-achse in cm/s^2 an das VGA-Modul
);
end architecture behave;
