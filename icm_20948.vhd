library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity icm_20948 is 
	generic (
		BOARD_CLK_FREQ : integer := 50000; --[kHz]
		
		SPI_FREQ : integer := 500; --[kHz]
		SAMPLERATE : integer := 100; --[Hz]
		SENSOR_RANGE : integer := 8 --[g] 	
		
	);
	port ( 
	
		i_board_clk : in std_logic;

		o_MOSI 	: out std_logic;
		i_MISO 	: in std_logic;
		o_CLK	: out std_logic;
		o_CS	: out std_logic;
		
		i_Interrupt : in std_logic;
		
		o_Accel_X : out integer range -32768 to 32767;
		o_Accel_Y : out integer range -32768 to 32767;
		o_Accel_Z : out integer range -32768 to 32767;
		
		o_DV : out std_logic := '0'

	);

end icm_20948;

architecture behavioral of icm_20948 is

	signal RAW_TO_ACCEL			: integer ;
	constant SET_SPI_MODE 			: integer := 0;
	constant SET_CLKS_PER_HALF_BIT 	: integer := BOARD_CLK_FREQ/(2*SPI_FREQ);
	
	-- icm_209448 specific registers
	type fourByte_REG 	is array (0 to 5) of std_logic_vector(7 downto 0);
	type CONFIG_REG 	is array (0 to 33) of std_logic_vector(7 downto 0);
	type DATA			is array (0 to 6) of std_logic_vector(7 downto 0);
	type twoByte		is array (0 to 1) of std_logic_vector(7 downto 0);

	constant REG_SAMPLERATE		: std_logic_vector (15 downto 0):= std_logic_vector(to_unsigned((1125 / SAMPLERATE) -1,16));
	constant REG_SAMPLERATE_H 	: std_logic_vector (7 downto 0) := REG_SAMPLERATE(15 downto 8);
	constant REG_SAMPLERATE_L 	: std_logic_vector (7 downto 0) := REG_SAMPLERATE(7 downto 0);
	
	constant RESET 			: fourByte_REG 		:= (x"80",x"FF",x"7F", x"00", x"06", x"81");
	signal SET_CONFIG		: CONFIG_REG 		:= (x"06", x"05",
													x"7F", x"20",x"10", REG_SAMPLERATE_H, x"11", REG_SAMPLERATE_L, x"7F", x"00", 
													x"11", x"01",
													x"91", x"FF",
													x"05", x"20", x"7F", x"00",
													x"85", x"FF",
													x"7F", x"00", x"07", x"07",
													x"87", x"FF",
													x"7F", x"20", x"14", x"06", x"94", x"FF", x"7F", x"00");
	constant GET_DATA		: DATA				:= (x"AD", others => x"FF");
	constant USER_BANK_0	: twoByte			:= (x"7F", x"00");
	
	signal r_Sensorrange : std_logic_vector (7 downto 0);
	

	signal r_SPI_Rst_L    : std_logic := '1'; -- reset default auf disable
	 -- Master Specific
	signal r_Master_TX_Byte  : std_logic_vector(7 downto 0) := X"00";
	signal r_Master_RX_Byte  : std_logic_vector(7 downto 0) := X"00";
	signal r_Master_TX_DV    : std_logic := '0';
	signal w_Master_TX_Ready : std_logic;
	signal r_Master_RX_DV    : std_logic := '0';
	
	type SPI_BUFFER is array (6 downto 0) of std_logic_vector(7 downto 0);
	signal RECEIVE_BUFFER 	: SPI_BUFFER := (others => (others => '0'));
	signal r_acceleleration_ready : std_logic := '0';
	signal r_Accel_X_raw : std_logic_vector (15 downto 0);
	signal r_Accel_Y_raw : std_logic_vector (15 downto 0);
	signal r_Accel_Z_raw : std_logic_vector (15 downto 0);
	
	signal r_Interrupt_DFF0 : std_logic;
	signal r_Interrupt_DFF1 : std_logic;

	type t_SM_Main is 	(	s_Init, s_Reset, s_Reset_Delay, s_set_Config, s_Idle, s_User_Bank_0, s_get_Data, s_Wait_TX_Ready);
							
	signal r_SM_Main 		: t_SM_Main := s_Init;
	signal r_SM_MAIN_NEXT	: t_SM_Main := s_Init;

	
	signal r_byte_counter : integer range 0 to SET_CONFIG'length := 0;
	signal Reset_Delay_Counter : integer range 0 to (BOARD_CLK_FREQ)*20; -- 20ms delay
	
	constant TX_delay : integer := 2*6* SET_CLKS_PER_HALF_BIT;
	signal TX_delay_counter : integer range 0 to TX_delay*3 +1;
	
	constant byte_delay : integer := 2*3* SET_CLKS_PER_HALF_BIT;
	signal byte_delay_counter : integer range 0 to byte_delay*4;

begin

	spi_master : entity work.SPI_Master
	generic map (
		SPI_MODE 			=> SET_SPI_MODE,
		CLKS_PER_HALF_BIT 	=> SET_CLKS_PER_HALF_BIT)
	port map (
		i_Rst_L		=> r_SPI_Rst_L,
		i_Clk		=> i_board_clk,
		
		i_TX_Byte  	=> r_Master_TX_Byte,
		i_TX_DV  	=> r_Master_TX_DV,
		o_TX_Ready 	=> w_Master_TX_Ready,
	   
		o_RX_DV  	=> r_Master_RX_DV,
		o_RX_Byte 	=> r_Master_RX_Byte,
	   
		o_SPI_Clk  => o_CLK, 
		i_SPI_MISO => i_MISO,
		o_SPI_MOSI => o_MOSI
	   );
	   
		xDFF0 : entity work.xDFF(behave)
		port map(
			D		=> i_Interrupt,
			En 		=> '1',
			Clk		=> i_board_clk,
			Reset 	=> '0',
			Q		=> r_Interrupt_DFF0
		);
		
		xDFF1 : entity work.xDFF(behave)
		port map(
			D		=> r_Interrupt_DFF0,
			En 		=> '1',
			Clk		=> i_board_clk,
			Reset 	=> '0',
			Q		=> r_Interrupt_DFF1
		);

		with SENSOR_RANGE select
			r_Sensorrange <=	x"00" when 2,
								x"02" when 4,
								x"04" when 8,
								x"06" when 16,
								x"04" when others;
								
		with SENSOR_RANGE select
			RAW_TO_ACCEL <=	60 when 2,
							120 when 4,
							240 when 8,
							479 when 16,
							240 when others;
		
		SET_CONFIG(29) <= r_Sensorrange;
	   
		measure_acceleration : process(i_board_clk)
		
		begin
			if rising_edge(i_board_clk) then
				case r_SM_Main is
				
					when s_Init =>
						o_CS <= '1';
						r_byte_counter <= 0;	
						r_SM_Main <= s_Reset;
						TX_delay_counter <= 0;
					
											
					when s_Reset =>
						o_CS <= '0';
						
						if r_byte_counter < 4 and w_Master_TX_Ready = '1' then
							if TX_delay_counter < TX_delay then
								TX_delay_counter <= TX_delay_counter + 1;
								o_CS <= '1';
							elsif TX_delay_counter  < TX_delay *2 and TX_delay_counter >= TX_delay then
								TX_delay_counter <= TX_delay_counter + 1;
								o_CS <= '0';
							else
								r_Master_TX_Byte 	<= RESET(r_byte_counter);
								r_Master_TX_DV 		<= '1';
								r_byte_counter		<= r_byte_counter + 1;
								r_SM_Main			<= s_Wait_TX_Ready;
								r_SM_MAIN_NEXT		<= s_Reset;
							end if;
						elsif r_byte_counter = 4 and w_Master_TX_Ready = '1' then
							TX_delay_counter <= TX_delay_counter + 1;				
							if TX_delay_counter = TX_delay * 3 then
								r_SM_Main <= s_Reset_Delay;							
								r_byte_counter <= 0;
								TX_delay_counter <= 0;
								o_CS <= '1';
							end if;
						end if;
						
					
					when s_Reset_Delay =>
						o_CS <= '1';
						if Reset_Delay_Counter = (BOARD_CLK_FREQ)*20 -1 then
							r_SM_Main <= s_set_Config;
							r_byte_counter <= 0;
						else 
							Reset_Delay_Counter <= Reset_Delay_Counter +1;
							r_SM_Main <= s_Reset_Delay;
						end if;
							
				
					when s_set_Config =>
						o_CS <= '0';
						
						if r_byte_counter < SET_CONFIG'length and w_Master_TX_Ready = '1' then
							if TX_delay_counter < TX_delay then
								TX_delay_counter <= TX_delay_counter + 1;
								o_CS <= '1';
							elsif TX_delay_counter  < TX_delay *2 and TX_delay_counter >= TX_delay then
								TX_delay_counter <= TX_delay_counter + 1;
								o_CS <= '0';
							else
								r_Master_TX_Byte 	<= SET_CONFIG(r_byte_counter);
								r_Master_TX_DV 		<= '1';
								r_byte_counter		<= r_byte_counter + 1;
								r_SM_Main			<= s_Wait_TX_Ready;
								r_SM_MAIN_NEXT		<= s_set_Config;
							end if;
						elsif r_byte_counter = SET_CONFIG'length and w_Master_TX_Ready = '1' then
							TX_delay_counter <= TX_delay_counter + 1;				
							if TX_delay_counter = TX_delay * 3 then
								r_SM_Main <= s_Idle;							
								r_byte_counter <= 0;
								TX_delay_counter <= 0;
								o_CS <= '1';
							end if;
						end if;
					
					when s_Idle =>
					
						if r_Interrupt_DFF1 = '1' then
							r_SM_Main <= s_User_Bank_0;
						else
							o_CS <= '1';
							r_acceleleration_ready <= '0';
							r_SM_Main <= s_Idle;
						end if;
						
					when s_User_Bank_0 =>
						o_CS <= '0';
						
						if r_byte_counter < USER_BANK_0'length and w_Master_TX_Ready = '1' then
							if TX_delay_counter < TX_delay then
								TX_delay_counter <= TX_delay_counter + 1;
								o_CS <= '1';
							elsif TX_delay_counter  < TX_delay *2 and TX_delay_counter >= TX_delay then
								TX_delay_counter <= TX_delay_counter + 1;
								o_CS <= '0';
							else
								r_Master_TX_Byte 	<= USER_BANK_0(r_byte_counter);
								r_Master_TX_DV 		<= '1';
								r_byte_counter		<= r_byte_counter + 1;
								r_SM_Main			<= s_Wait_TX_Ready;
								r_SM_MAIN_NEXT		<= s_User_Bank_0;
							end if;
						elsif r_byte_counter = USER_BANK_0'length and w_Master_TX_Ready = '1' then
							TX_delay_counter <= TX_delay_counter + 1;				
							if TX_delay_counter = TX_delay * 3 then
								r_SM_Main <= s_get_Data;							
								r_byte_counter <= 0;
								TX_delay_counter <= 0;
								o_CS <= '1';
							end if;
						end if;				
					
					when s_get_Data =>
						o_CS <= '0';
						
						if r_byte_counter < GET_DATA'length and w_Master_TX_Ready = '1' then
							if TX_delay_counter < TX_delay then
								TX_delay_counter <= TX_delay_counter + 1;
								o_CS <= '1';
							elsif TX_delay_counter  < TX_delay *2 and TX_delay_counter >= TX_delay then
								TX_delay_counter <= TX_delay_counter + 1;
								o_CS <= '0';
							else
								r_Master_TX_Byte 	<= GET_DATA(r_byte_counter);
								r_Master_TX_DV 		<= '1';
								r_byte_counter		<= r_byte_counter + 1;
								r_SM_Main			<= s_Wait_TX_Ready;
								r_SM_MAIN_NEXT		<= s_get_Data;
							end if;
						elsif r_byte_counter = GET_DATA'length and w_Master_TX_Ready = '1' then
							TX_delay_counter <= TX_delay_counter + 1;				
							if TX_delay_counter = TX_delay * 3 then
								r_SM_Main <= s_Idle;							
								r_byte_counter <= 0;
								TX_delay_counter <= 0;
								o_CS <= '1';
								r_acceleleration_ready <= '1';
							end if;
						end if;

					when s_Wait_TX_Ready =>
						r_Master_TX_DV 		<= '0';
						if w_Master_TX_Ready = '0' then
							r_SM_Main	<= s_Wait_TX_Ready;
						elsif w_Master_TX_Ready = '1' then
							byte_delay_counter <= byte_delay_counter + 1;
							if byte_delay_counter = byte_delay then
								r_SM_Main 	<= r_SM_MAIN_NEXT;
								byte_delay_counter <= 0;
								if r_byte_counter mod 2 = 0 and r_SM_MAIN_NEXT /= s_get_Data then 
									TX_delay_counter <= 0;
								end if;
							end if;
						end if;
						
				end case;
			end if;
		end process measure_acceleration;
				
		RECEIVE_BUFFER(r_byte_counter)	<= r_Master_RX_Byte when r_Master_RX_DV = '1';
		r_Accel_X_raw (7 downto 0) <= RECEIVE_BUFFER(1);
		r_Accel_X_raw (15 downto 8) <= RECEIVE_BUFFER(2);
		r_Accel_Y_raw (7 downto 0) <= RECEIVE_BUFFER(3);
		r_Accel_Y_raw (15 downto 8) <= RECEIVE_BUFFER(4);
		r_Accel_Z_raw (7 downto 0) <= RECEIVE_BUFFER(5);
		r_Accel_Z_raw (15 downto 8) <= RECEIVE_BUFFER(6);
	
		
		update_data_reg : process(i_board_clk)
		begin
				if rising_edge(i_board_clk) then
					if r_acceleleration_ready = '1' then	
						o_Accel_X <= (to_integer(signed(r_Accel_X_raw))) * RAW_TO_ACCEL/1000;
						o_Accel_Y <= (to_integer(signed(r_Accel_Y_raw))) * RAW_TO_ACCEL/1000;
						o_Accel_Z <= (to_integer(signed(r_Accel_Z_raw))) * RAW_TO_ACCEL/1000;
						o_DV <= r_acceleleration_ready;
					end if;
				end if;
		end process;
end architecture;