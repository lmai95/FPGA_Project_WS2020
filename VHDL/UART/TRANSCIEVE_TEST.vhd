library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TRANSCIEVE_TEST is
port(
	CLOCK_50: in std_logic;
	UART_RXD: in std_logic;
	UART_TXD: out std_logic;
	LEDG0:    out std_logic;
	BUTTON0:	 in std_logic
);
end entity TRANSCIEVE_TEST;

architecture behaviour of TRANSCIEVE_TEST is
	signal RX_DATA, TX_DATA: std_logic_vector (7 downto 0);
	signal RX_EN, TX_EN, TX_BUSY:   std_logic;
	
	type ram_type is array (16 downto 0) 
   of std_logic_vector(7 downto 0); -- Array of 8 x 17 (Test vector)
	
	signal Data:    ram_type; 
	signal Counter: integer range 0 to 17 := 0;
	signal Reset: std_logic;

begin

--Debounce Reset BUTTON0 --
Debouncer: entity work.DEBOUNCE(logic)
port map (
	CLK => CLOCK_50,  --input clock
   button  => not BUTTON0,  --input signal to be debounced
   result  => Reset --debounced signal
);


-- UART instantiation
UART_A: entity work.UART(behavioural)
generic map(
	No_Parity => '1', -- Parity enable bit
	even_odd  => '0', -- even or odd parity
	ram_depth => 32,
	baudrate  => 115200
	
)
port map(
	CLK     => CLOCK_50,
	Reset   => Reset,
	TXD	  => UART_TXD,
	RXD     => UART_RXD,
	RX_DATA => RX_DATA,
	TX_DATA => TX_DATA,
	RX_EN   => RX_EN,
	TX_EN	  => TX_EN,
	TX_BUSY => TX_BUSY
);

-- Receive counter
Counter_inc: process (CLOCK_50, Reset)
begin

if (Reset = '1') then
	Counter <= 0;
	Data <= (16 downto 0 => b"0000_0000");
elsif rising_edge (ClOCK_50) then 
	if (RX_EN = '1') then -- when RX_EN = '1' data has been received and can be read
		Data(Counter) <= RX_DATA; -- write received data into the test vector
		Counter <= Counter + 1;
	end if;
	
end if;	
end process Counter_inc;

--Flash LEDG0 when receivment matches test vector
-- String: "Das ist ein Test "   (space after "Test")
LEDG0 <= '1' when (Data(0) = b"01000100"
						and Data(1) = b"01100001" 
						and Data(2) = b"01110011" 
						and Data(3) = b"00100000" 
						and Data(4) = b"01101001" 
						and Data(5) = b"01110011" 
						and Data(6) = b"01110100"
						and Data(7) = b"00100000" 
						and Data(8) = b"01100101" 
						and Data(9) = b"01101001" 
						and Data(10) = b"01101110" 
						and Data(11) = b"00100000" 
						and Data(12) = b"01010100" 
						and Data(13) = b"01100101" 
						and Data(14) = b"01110011" 
						and Data(15) = b"01110100" 
						and Data(16) = b"00100000")  else '0';		
						
TX_DATA <= RX_DATA; -- echo received data
TX_EN <= RX_EN;
end architecture behaviour;

