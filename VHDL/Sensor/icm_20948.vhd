LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY icm_20948 IS
	GENERIC
	(
		BOARD_CLK_FREQ : INTEGER := 50000; --[kHz]

		SPI_FREQ     : INTEGER := 500; --[kHz]
		SAMPLERATE   : INTEGER := 100;   --[Hz]
		SENSOR_RANGE : INTEGER := 8    --[g] 	

	);
	PORT (
		i_board_clk : IN STD_LOGIC;
		o_MOSI      : OUT STD_LOGIC;
		i_MISO      : IN STD_LOGIC;
		o_CLK       : OUT STD_LOGIC;
		o_CS        : OUT STD_LOGIC;
		i_Interrupt : IN STD_LOGIC;
		o_Accel_X   : OUT INTEGER RANGE -32768 TO 32767;
		o_Accel_Y   : OUT INTEGER RANGE -32768 TO 32767;
		o_Accel_Z   : OUT INTEGER RANGE -32768 TO 32767;
		o_DV        : OUT STD_LOGIC := '0'
	);

END icm_20948;

ARCHITECTURE behavioral OF icm_20948 IS

	SIGNAL RAW_TO_ACCEL            : INTEGER;
	CONSTANT SET_SPI_MODE          : INTEGER := 0;
	CONSTANT SET_CLKS_PER_HALF_BIT : INTEGER := BOARD_CLK_FREQ/(2 * SPI_FREQ);

	-- icm_209448 specific registers
	TYPE fourByte_REG IS ARRAY (0 TO 5) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	TYPE CONFIG_REG IS ARRAY (0 TO 33) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	TYPE DATA IS ARRAY (0 TO 6) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	TYPE twoByte IS ARRAY (0 TO 1) OF STD_LOGIC_VECTOR(7 DOWNTO 0);

	CONSTANT REG_SAMPLERATE   : STD_LOGIC_VECTOR (15 DOWNTO 0) := STD_LOGIC_VECTOR(to_unsigned((1125 / SAMPLERATE) - 1, 16));
	CONSTANT REG_SAMPLERATE_H : STD_LOGIC_VECTOR (7 DOWNTO 0)  := REG_SAMPLERATE(15 DOWNTO 8);
	CONSTANT REG_SAMPLERATE_L : STD_LOGIC_VECTOR (7 DOWNTO 0)  := REG_SAMPLERATE(7 DOWNTO 0);

	CONSTANT RESET    : fourByte_REG := (x"80", x"FF", x"7F", x"00", x"06", x"81");
	SIGNAL SET_CONFIG : CONFIG_REG   := (x"06", x"05",
	x"7F", x"20", x"10", REG_SAMPLERATE_H, x"11", REG_SAMPLERATE_L, x"7F", x"00",
	x"11", x"01",
	x"91", x"FF",
	x"05", x"20", x"7F", x"00",
	x"85", x"FF",
	x"7F", x"00", x"07", x"07",
	x"87", x"FF",
	x"7F", x"20", x"14", x"06", x"94", x"FF", x"7F", x"00");
	CONSTANT GET_DATA    : DATA    := (x"AD", OTHERS => x"FF");
	CONSTANT USER_BANK_0 : twoByte := (x"7F", x"00");

	SIGNAL r_Sensorrange : STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL r_SPI_Rst_L   : STD_LOGIC := '1'; -- reset default auf disable
	-- Master Specific
	SIGNAL r_Master_TX_Byte  : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"00";
	SIGNAL r_Master_RX_Byte  : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"00";
	SIGNAL r_Master_TX_DV    : STD_LOGIC                    := '0';
	SIGNAL w_Master_TX_Ready : STD_LOGIC;
	SIGNAL r_Master_RX_DV    : STD_LOGIC := '0';

	TYPE SPI_BUFFER IS ARRAY (6 DOWNTO 0) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL RECEIVE_BUFFER         : SPI_BUFFER := (OTHERS => (OTHERS => '0'));
	SIGNAL r_acceleleration_ready : STD_LOGIC  := '0';
	SIGNAL r_Accel_X_raw          : STD_LOGIC_VECTOR (15 DOWNTO 0);
	SIGNAL r_Accel_Y_raw          : STD_LOGIC_VECTOR (15 DOWNTO 0);
	SIGNAL r_Accel_Z_raw          : STD_LOGIC_VECTOR (15 DOWNTO 0);

	SIGNAL r_Interrupt_DFF0 : STD_LOGIC;
	SIGNAL r_Interrupt_DFF1 : STD_LOGIC;

	TYPE t_SM_Main IS (s_Init, s_Reset, s_Reset_Delay, s_set_Config, s_Idle, s_User_Bank_0, s_get_Data, s_Wait_TX_Ready);

	SIGNAL r_SM_Main           : t_SM_Main                            := s_Init;
	SIGNAL r_SM_MAIN_NEXT      : t_SM_Main                            := s_Init;
	SIGNAL r_byte_counter      : INTEGER RANGE 0 TO SET_CONFIG'length := 0;
	SIGNAL Reset_Delay_Counter : INTEGER RANGE 0 TO (BOARD_CLK_FREQ) * 20; -- 20ms delay

	CONSTANT TX_delay       : INTEGER := 2 * 6 * SET_CLKS_PER_HALF_BIT;
	SIGNAL TX_delay_counter : INTEGER RANGE 0 TO TX_delay * 3 + 1;

	CONSTANT byte_delay       : INTEGER := 2 * 3 * SET_CLKS_PER_HALF_BIT;
	SIGNAL byte_delay_counter : INTEGER RANGE 0 TO byte_delay * 4;

BEGIN

	spi_master : ENTITY work.SPI_Master
		GENERIC
		MAP (
		SPI_MODE          => SET_SPI_MODE,
		CLKS_PER_HALF_BIT => SET_CLKS_PER_HALF_BIT)
		PORT MAP(
			i_Rst_L => r_SPI_Rst_L,
			i_Clk   => i_board_clk,

			i_TX_Byte  => r_Master_TX_Byte,
			i_TX_DV    => r_Master_TX_DV,
			o_TX_Ready => w_Master_TX_Ready,

			o_RX_DV   => r_Master_RX_DV,
			o_RX_Byte => r_Master_RX_Byte,

			o_SPI_Clk  => o_CLK,
			i_SPI_MISO => i_MISO,
			o_SPI_MOSI => o_MOSI
		);

	xDFF0 : ENTITY work.xDFF(behave)
		PORT MAP(
			D     => i_Interrupt,
			En    => '1',
			Clk   => i_board_clk,
			Reset => '0',
			Q     => r_Interrupt_DFF0
		);

	xDFF1 : ENTITY work.xDFF(behave)
		PORT MAP(
			D     => r_Interrupt_DFF0,
			En    => '1',
			Clk   => i_board_clk,
			Reset => '0',
			Q     => r_Interrupt_DFF1
		);

	WITH SENSOR_RANGE SELECT
		r_Sensorrange <= x"00" WHEN 2,
		x"02" WHEN 4,
		x"04" WHEN 8,
		x"06" WHEN 16,
		x"04" WHEN OTHERS;

	WITH SENSOR_RANGE SELECT
		RAW_TO_ACCEL <= 60 WHEN 2,
		120 WHEN 4,
		240 WHEN 8,
		479 WHEN 16,
		240 WHEN OTHERS;

	SET_CONFIG(29) <= r_Sensorrange;

	measure_acceleration : PROCESS (i_board_clk)

	BEGIN
		IF rising_edge(i_board_clk) THEN
			CASE r_SM_Main IS

				WHEN s_Init =>
					o_CS             <= '1';
					r_byte_counter   <= 0;
					r_SM_Main        <= s_Reset;
					TX_delay_counter <= 0;
				WHEN s_Reset =>
					o_CS <= '0';

					IF r_byte_counter < 4 AND w_Master_TX_Ready = '1' THEN
						IF TX_delay_counter < TX_delay THEN
							TX_delay_counter <= TX_delay_counter + 1;
							o_CS             <= '1';
						ELSIF TX_delay_counter < TX_delay * 2 AND TX_delay_counter >= TX_delay THEN
							TX_delay_counter <= TX_delay_counter + 1;
							o_CS             <= '0';
						ELSE
							r_Master_TX_Byte <= RESET(r_byte_counter);
							r_Master_TX_DV   <= '1';
							r_byte_counter   <= r_byte_counter + 1;
							r_SM_Main        <= s_Wait_TX_Ready;
							r_SM_MAIN_NEXT   <= s_Reset;
						END IF;
					ELSIF r_byte_counter = 4 AND w_Master_TX_Ready = '1' THEN
						TX_delay_counter <= TX_delay_counter + 1;
						IF TX_delay_counter = TX_delay * 3 THEN
							r_SM_Main        <= s_Reset_Delay;
							r_byte_counter   <= 0;
							TX_delay_counter <= 0;
							o_CS             <= '1';
						END IF;
					END IF;
				WHEN s_Reset_Delay =>
					o_CS <= '1';
					IF Reset_Delay_Counter = (BOARD_CLK_FREQ) * 20 - 1 THEN
						r_SM_Main      <= s_set_Config;
						r_byte_counter <= 0;
					ELSE
						Reset_Delay_Counter <= Reset_Delay_Counter + 1;
						r_SM_Main           <= s_Reset_Delay;
					END IF;
				WHEN s_set_Config =>
					o_CS <= '0';

					IF r_byte_counter < SET_CONFIG'length AND w_Master_TX_Ready = '1' THEN
						IF TX_delay_counter < TX_delay THEN
							TX_delay_counter <= TX_delay_counter + 1;
							o_CS             <= '1';
						ELSIF TX_delay_counter < TX_delay * 2 AND TX_delay_counter >= TX_delay THEN
							TX_delay_counter <= TX_delay_counter + 1;
							o_CS             <= '0';
						ELSE
							r_Master_TX_Byte <= SET_CONFIG(r_byte_counter);
							r_Master_TX_DV   <= '1';
							r_byte_counter   <= r_byte_counter + 1;
							r_SM_Main        <= s_Wait_TX_Ready;
							r_SM_MAIN_NEXT   <= s_set_Config;
						END IF;
					ELSIF r_byte_counter = SET_CONFIG'length AND w_Master_TX_Ready = '1' THEN
						TX_delay_counter <= TX_delay_counter + 1;
						IF TX_delay_counter = TX_delay * 3 THEN
							r_SM_Main        <= s_Idle;
							r_byte_counter   <= 0;
							TX_delay_counter <= 0;
							o_CS             <= '1';
						END IF;
					END IF;

				WHEN s_Idle =>

					IF r_Interrupt_DFF1 = '1' THEN
						r_SM_Main <= s_User_Bank_0;
					ELSE
						o_CS                   <= '1';
						r_acceleleration_ready <= '0';
						r_SM_Main              <= s_Idle;
					END IF;

				WHEN s_User_Bank_0 =>
					o_CS <= '0';

					IF r_byte_counter < USER_BANK_0'length AND w_Master_TX_Ready = '1' THEN
						IF TX_delay_counter < TX_delay THEN
							TX_delay_counter <= TX_delay_counter + 1;
							o_CS             <= '1';
						ELSIF TX_delay_counter < TX_delay * 2 AND TX_delay_counter >= TX_delay THEN
							TX_delay_counter <= TX_delay_counter + 1;
							o_CS             <= '0';
						ELSE
							r_Master_TX_Byte <= USER_BANK_0(r_byte_counter);
							r_Master_TX_DV   <= '1';
							r_byte_counter   <= r_byte_counter + 1;
							r_SM_Main        <= s_Wait_TX_Ready;
							r_SM_MAIN_NEXT   <= s_User_Bank_0;
						END IF;
					ELSIF r_byte_counter = USER_BANK_0'length AND w_Master_TX_Ready = '1' THEN
						TX_delay_counter <= TX_delay_counter + 1;
						IF TX_delay_counter = TX_delay * 3 THEN
							r_SM_Main        <= s_get_Data;
							r_byte_counter   <= 0;
							TX_delay_counter <= 0;
							o_CS             <= '1';
						END IF;
					END IF;

				WHEN s_get_Data =>
					o_CS <= '0';

					IF r_byte_counter < GET_DATA'length AND w_Master_TX_Ready = '1' THEN
						IF TX_delay_counter < TX_delay THEN
							TX_delay_counter <= TX_delay_counter + 1;
							o_CS             <= '1';
						ELSIF TX_delay_counter < TX_delay * 2 AND TX_delay_counter >= TX_delay THEN
							TX_delay_counter <= TX_delay_counter + 1;
							o_CS             <= '0';
						ELSE
							r_Master_TX_Byte <= GET_DATA(r_byte_counter);
							r_Master_TX_DV   <= '1';
							r_byte_counter   <= r_byte_counter + 1;
							r_SM_Main        <= s_Wait_TX_Ready;
							r_SM_MAIN_NEXT   <= s_get_Data;
						END IF;
					ELSIF r_byte_counter = GET_DATA'length AND w_Master_TX_Ready = '1' THEN
						TX_delay_counter <= TX_delay_counter + 1;
						IF TX_delay_counter = TX_delay * 3 THEN
							r_SM_Main              <= s_Idle;
							r_byte_counter         <= 0;
							TX_delay_counter       <= 0;
							o_CS                   <= '1';
							r_acceleleration_ready <= '1';
						END IF;
					END IF;

				WHEN s_Wait_TX_Ready =>
					r_Master_TX_DV <= '0';
					IF w_Master_TX_Ready = '0' THEN
						r_SM_Main <= s_Wait_TX_Ready;
					ELSIF w_Master_TX_Ready = '1' THEN
						byte_delay_counter <= byte_delay_counter + 1;
						IF byte_delay_counter = byte_delay THEN
							r_SM_Main          <= r_SM_MAIN_NEXT;
							byte_delay_counter <= 0;
							IF r_byte_counter MOD 2 = 0 AND r_SM_MAIN_NEXT /= s_get_Data THEN
								TX_delay_counter <= 0;
							END IF;
						END IF;
					END IF;

			END CASE;
		END IF;
	END PROCESS measure_acceleration;

	RECEIVE_BUFFER(r_byte_counter) <= r_Master_RX_Byte WHEN r_Master_RX_DV = '1';
	r_Accel_X_raw (7 DOWNTO 0)     <= RECEIVE_BUFFER(1);
	r_Accel_X_raw (15 DOWNTO 8)    <= RECEIVE_BUFFER(2);
	r_Accel_Y_raw (7 DOWNTO 0)     <= RECEIVE_BUFFER(3);
	r_Accel_Y_raw (15 DOWNTO 8)    <= RECEIVE_BUFFER(4);
	r_Accel_Z_raw (7 DOWNTO 0)     <= RECEIVE_BUFFER(5);
	r_Accel_Z_raw (15 DOWNTO 8)    <= RECEIVE_BUFFER(6);
	update_data_reg : PROCESS (i_board_clk)
	BEGIN
		IF rising_edge(i_board_clk) THEN
			IF r_acceleleration_ready = '1' THEN
				o_Accel_X <= (to_integer(signed(r_Accel_X_raw))) * RAW_TO_ACCEL/1000;
				o_Accel_Y <= (to_integer(signed(r_Accel_Y_raw))) * RAW_TO_ACCEL/1000;
				o_Accel_Z <= (to_integer(signed(r_Accel_Z_raw))) * RAW_TO_ACCEL/1000;
				o_DV      <= '1';
			ELSE
				o_DV <= '0';
			END IF;
		END IF;
	END PROCESS;
END ARCHITECTURE;
