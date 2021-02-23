library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TRANSMIT_TEST is
port(
	CLOCK_50:   in std_logic;
	UART_TXD:    out std_logic;
	BUTTON0:	 in std_logic
);
end entity TRANSMIT_TEST;

architecture behaviour of TRANSMIT_TEST is
	signal Reset:	std_logic := '0';
	signal EN:   	std_logic := '1';
	signal TX_EN:  std_logic := '0';
	
	signal RX_EN:   std_logic := '0';
	signal TX_DATA: std_logic_vector(7 downto 0) := b"0000_0000";
	signal TX_BUSY: std_logic := '0';
	signal Counter: integer:=0;

begin

--Debounce Reset BUTTON0 --
Debouncer: entity work.DEBOUNCE(logic)

port map (
	CLK => CLOCK_50,  --input clock
   button  => not BUTTON0,  --input signal to be debounced
   result  => Reset --debounced signal
);

UART_A: entity work.UART(behavioural)

generic map(
	No_Parity => '0', -- Parity enable bit
	ram_depth => 16, -- FIFO size
	even_odd  => '0', --even or odd parity 
	baudrate  => 115200
)
port map(
	CLK   => CLOCK_50,
	Reset => Reset,
	TXD   =>  UART_TXD,
	TX_DATA => TX_DATA,
	TX_EN   =>  TX_EN,
	TX_BUSY => TX_BUSY
);

----Transmit Counter-----
Counter_inc: process (CLOCK_50, Reset)
begin
if (Reset = '1') then
	Counter <= 0;
elsif rising_edge(CLOCK_50) then
	if (TX_BUSY = '0') then -- if FIFO_TX not full
		if (Counter = 61) then
			Counter <= 0;	
		else
			Counter <= Counter + 1;
		end if;
	end if;	
end if;
end process Counter_inc;

TX_EN <= not TX_BUSY; -- because of constant transmission enable writing when FIFO_TX is not full              
-- write "Das ist ein Test " into FIFO_TX		  
--TX_DATA <= b"01000100" when (Counter = 0) else
--			  b"01100001" when (Counter = 1) else
--			  b"01110011" when (Counter = 2) else
--			  b"00100000" when (Counter = 3) else			  
--			  b"01101001" when (Counter = 4) else
--			  b"01110011" when (Counter = 5) else
--			  b"01110100" when (Counter = 6) else
--			  b"00100000" when (Counter = 7) else
--			  b"01100101" when (Counter = 8) else
--			  b"01101001" when (Counter = 9) else
--			  b"01101110" when (Counter = 10) else
--			  b"00100000" when (Counter = 11) else
--			  b"01010100" when (Counter = 12) else
--			  b"01100101" when (Counter = 13) else
--			  b"01110011" when (Counter = 14) else
--			  b"01110100" when (Counter = 15) else
--			  b"00100000" when (Counter = 16);

                              


TX_DATA <= b"00001101" when (Counter = 0) else
			  b"01111000" when (Counter = 1) else
			  b"00111010" when (Counter = 2) else
			  b"00101101" when (Counter = 3) else			  
			  b"00110011" when (Counter = 4) else
			  b"00110010" when (Counter = 5) else
			  b"00110111" when (Counter = 6) else
			  b"00101110" when (Counter = 7) else 
			  b"00110110" when (Counter = 8) else
			  b"00111000" when (Counter = 9) else
			  b"00100000" when (Counter = 10) else
			  b"01111001" when (Counter = 11) else 
			  b"00111010" when (Counter = 12) else
			  b"00101101" when (Counter = 13) else
			  b"00110000" when (Counter = 14) else
			  b"00110000" when (Counter = 15) else
			  b"00110011" when (Counter = 16) else
			  b"00101110" when (Counter = 17) else
			  b"00110001" when (Counter = 18) else
			  b"00110100" when (Counter = 19) else
			  b"00100000" when (Counter = 20) else
			  b"01111010" when (Counter = 21) else
			  b"00111010" when (Counter = 22) else
			  b"00101011" when (Counter = 23) else
			  b"00110011" when (Counter = 24) else
			  b"00110010" when (Counter = 25) else
			  b"00110001" when (Counter = 26) else
			  b"00101110" when (Counter = 27) else
			  b"00110000" when (Counter = 28) else
			  b"00110000" when (Counter = 29) else
			  b"00001010" when (Counter = 30) else --
			                                
			  
			  b"00001101" when (Counter = 31) else
			  b"01111000" when (Counter = 32) else
			  b"00111010" when (Counter = 33) else
			  b"00101011" when (Counter = 34) else			  
			  b"00110001" when (Counter = 35) else
			  b"00111001" when (Counter = 36) else
			  b"00110011" when (Counter = 37) else
			  b"00101110" when (Counter = 38) else
			  b"00110011" when (Counter = 39) else
			  b"00110001" when (Counter = 40) else
			  b"00100000" when (Counter = 41) else
			  b"01111001" when (Counter = 42) else
			  b"00111010" when (Counter = 43) else
			  b"00101011" when (Counter = 44) else
			  b"00110000" when (Counter = 45) else
			  b"00110000" when (Counter = 46) else
			  b"00110111" when (Counter = 47) else
			  b"00101110" when (Counter = 48) else
			  b"00110111" when (Counter = 49) else
			  b"00111000" when (Counter = 50) else
			  b"00100000" when (Counter = 51) else
			  b"01111010" when (Counter = 52) else
			  b"00111010" when (Counter = 53) else
			  b"00101101" when (Counter = 54) else
			  b"00110010" when (Counter = 55) else
			  b"00110100" when (Counter = 56) else
			  b"00110100" when (Counter = 57) else
			  b"00101110" when (Counter = 58) else
			  b"00110000" when (Counter = 59) else
			  b"00110000" when (Counter = 60) else
			  b"00001010" when (Counter = 61) ;		  
			  
			  
			  
end architecture behaviour;