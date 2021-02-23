LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.bitmaps.ALL;

ENTITY Projekt_WS2020_2021 IS
	PORT (
		clk   : IN STD_LOGIC;
		rst   : IN STD_LOGIC;
		
		hsync : OUT STD_LOGIC;
		vsync : OUT STD_LOGIC;
		red   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		blue  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		green : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		
		o_MOSI : OUT STD_LOGIC;
		i_MISO : IN STD_LOGIC;
		o_CLK  : OUT STD_LOGIC;
		o_CS   : OUT STD_LOGIC;
		i_Interrupt : IN STD_LOGIC;
		
		TXD : OUT STD_LOGIC;
		RXD : IN STD_LOGIC;
		RX_ERROR : OUT STD_LOGIC;
		RX_EN : OUT STD_LOGIC
	);
END ENTITY Projekt_WS2020_2021;

ARCHITECTURE behave OF Projekt_WS2020_2021 IS

SIGNAL Accel_X_sens_to_proc :INTEGER RANGE -32768 TO 32767;
SIGNAL Accel_Y_sens_to_proc :INTEGER RANGE -32768 TO 32767;
SIGNAL Accel_Z_sens_to_proc :INTEGER RANGE -32768 TO 32767;
SIGNAL Accel_X_proc_to_VGA :INTEGER RANGE -9999 TO 9999;
SIGNAL Accel_Y_proc_to_VGA :INTEGER RANGE -9999 TO 9999;
SIGNAL Accel_Z_proc_to_VGA :INTEGER RANGE -9999 TO 9999;
SIGNAL Data_valid_sens_to_proc :STD_LOGIC;
SIGNAL Data_valid_proc_to_VGA :STD_LOGIC;
SIGNAL TX_BUSY :STD_LOGIC;
SIGNAL TX_EN :STD_LOGIC;
SIGNAL TX_DATA :std_logic_vector(7 downto 0);
SIGNAL RX_DATA : std_logic_vector (7 downto 0);
BEGIN
Sensor : ENTITY work.icm_20948
	PORT MAP(
		i_board_clk => clk,
		o_MOSI => o_MOSI,
		i_MISO => i_MISO,
		o_CLK => o_clk,
		o_CS => o_CS,
		i_Interrupt =>i_interrupt,
		o_Accel_X => Accel_X_sens_to_proc,		
		o_Accel_Y => Accel_y_sens_to_proc,
		o_Accel_Z => Accel_z_sens_to_proc,
		o_DV => Data_valid_sens_to_proc
	);
Display : ENTITY work.VGA 
	PORT MAP(
		clk   => clk,
		rst   => rst,
		hsync => hsync,
		vsync => vsync,
		red   => red,
		blue  => blue,
		green => green, 
		data_valid => Data_valid_proc_to_VGA,
		x_in => Accel_X_proc_to_VGA,
		y_in => Accel_Y_proc_to_VGA,
		z_in => Accel_Z_proc_to_VGA
	);
Signal_processing: EntITY work.signal_processing
	generic map(
		FreeRunning => '0'--: std_logic := '0'	--Bei '1' FreeRunning-Mode: Daten die nicht verarbeitet werden koennen werden verworfen die Datenerfassung wird natlos fortgesetzt
													--Bei '0' Sampling-Mode: Sobald ein Datensatz nicht erfasst werden kann stoppt die Datenerfassung bis die FiFo ausgegbe wurde, PrintRejectedData wird auf '1' gesetzt, die Datenerfassung wird fortgesetzt
	)
	port map(
		EN 	  	=> '1',
		Reset 	=> NOT rst,
		Clk   	=> clk,
		data_valid => Data_valid_sens_to_proc,									--data valid des Sensor Kontroll-Modul
		acc_x 		 => Accel_X_sens_to_proc, --: in integer RANGE -32768 to 32767; 			--x-achse des Sensor Kontroll-Modul; in cm/s^2	7FFF = 32767
		acc_y 		 => Accel_Y_sens_to_proc, --: in integer RANGE -32768 to 32767; 			--y-achse  "     "           "        "   "			
		acc_z 		 => Accel_Z_sens_to_proc, --: in integer RANGE -32768 to 32767; 			--z-achse  "     "           "        "   "	
		TX_BUSY 	 => TX_BUSY,--: in std_logic;                      			 	--TX_Busy der UART
		TX_EN 	 => TX_EN,--: out std_logic := '0';                		 	--TX_EN der UART
		TX_DATA 	 => TX_DATA,--: out std_logic_vector(7 downto 0):= x"00"; 	--Eingangsbyte der UART; LSB hat Index 0

		data_valid_in => Data_valid_proc_to_VGA, --: out std_logic := '0';	             		--Ausgabe von data valid an das VGA-Modl
		x_in => Accel_X_proc_to_VGA, --: out integer range -9999 to 9999 := 0;        		--Ausgabe der Beschleunigung der x-achse in cm/s^2 an das VGA-Modul
		y_in => Accel_Y_proc_to_VGA, --: out integer range -9999 to 9999 := 0;        		--	  " 	  " 			"			"  y-achse  "   "     "  "     "
		z_in => Accel_z_proc_to_VGA --: out integer range -9999 to 9999 := 0         		--	  " 	  " 			"			"  z-achse  "   "     "  "     "
	);
UART: EntITY work.UART
generic map(
	no_parity 	=> '1', -- Parity enable bit
	even_odd => '0', -- odd = 1 or even = 0 parity 
	ram_width  => 8,   -- FIFO width size 
	ram_depth   => 32,  -- FIFO depth size (desired size + 1)
	baudrate   => 115200
)
port map(
	CLK => clk, --:     in std_logic; 
	Reset => NOT rst,--:   in std_logic := '0';
	TX_EN => TX_EN, --:   in std_logic := '0'; --Transmission enable bit
	TX_DATA => TX_DATA,--:  in std_logic_vector (ram_width - 1 downto 0) := (ram_width - 1 downto 0 => '0'); --Transmission data bit
	RX_BUSY => '0',--: in std_logic := '0'; --can't accept more bits
	RXD => RXD,--:     in std_logic := '0'; --receive from PC


	TX_BUSY => TX_BUSY,--:  out std_logic := '0'; --FIFO is full
	RX_EN => RX_EN, --:    out std_logic := '0'; --Receive enable bit
	RX_DATA => RX_DATA,--:  out std_logic_vector (ram_width - 1 downto 0) := (ram_width - 1 downto 0 => '0'); --Receive data bit
	RX_ERROR => RX_ERROR,--: out std_logic := '0'; --failed parity / no stop bit received 
	TXD => TXD--:      out std_logic := '1'  --Trasmit data to PC pin
);

END ARCHITECTURE behave;
