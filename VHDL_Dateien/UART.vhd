library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART is 
generic (
	no_parity: 	std_logic := '1'; -- Parity enable bit
	even_odd: 	std_logic := '0'; -- odd = 1 or even = 0 parity 
	ram_width: 	natural   := 8;   -- FIFO width size 
	ram_depth:  natural   := 32;  -- FIFO depth size (desired size + 1)
	baudrate:	natural   := 115200
);
port(
	CLK:     in std_logic; 
	Reset:   in std_logic := '0';
	TX_EN:   in std_logic := '0'; --Transmission enable bit
	TX_DATA: in std_logic_vector (ram_width - 1 downto 0) := (ram_width - 1 downto 0 => '0'); --Transmission data bit
	RX_BUSY: in std_logic := '0'; --can't accept more bits
	RXD:     in std_logic := '0'; --receive from PC


	TX_BUSY:  out std_logic := '0'; --FIFO is full
	RX_EN:    out std_logic := '0'; --Receive enable bit
	RX_DATA:  out std_logic_vector (ram_width - 1 downto 0) := (ram_width - 1 downto 0 => '0'); --Receive data bit
	RX_ERROR: out std_logic := '0'; --failed parity / no stop bit received 
	TXD:      out std_logic := '1'  --Trasmit data to PC pin

--	-----for simulation purposes--
--	TX_Ti: out std_logic; 							--<----------uncomment for receive simulation-
--	RX_Ti: out std_logic;
--	Count_RX, Count_TX: out std_logic_vector (3 downto 0);
--	in_ready_t, in_valid_t, out_ready_t, out_valid_t: out std_logic;
--	in_data_t, out_data_t: out std_logic_vector (7 downto 0)

	
	
);
end entity UART;

architecture behavioural of UART is
	signal Max:       unsigned (11 downto 0); -- Maximum counter value for Baud_Generator dependig on Baudrate
	signal Counter_RX, Counter_TX:   unsigned (3 downto 0) := x"0"; --counters for bits transmitted (TX) and bits received (RX)
	signal RX_Tick, TX_Tick: std_logic; --TX_Tick (Baudrate) RX_Tick (Baudrate 16x)
	signal Parity_RX: std_logic := even_odd; -- 0 means even parity, 1 odd parity 
	signal Parity_TX: std_logic := even_odd; -- 0 means even parity, 1 odd parity
	signal in_ready_tx, out_ready_tx, out_valid_tx: std_logic; -- FIFO_RX in/out control bits and in/out data bits
	signal out_data_tx, in_data_tx: std_logic_vector (ram_width - 1 downto 0) :=  (ram_width - 1 downto 0 => '0'); 
	signal ctrl_tx: std_logic := '0'; -- Transmission control bit
	signal STARTBIT: std_logic:='0';
	
begin
--Baud generator instantiation
Baud_Generator: entity work.BAUDGEN(behavioural)
port map(
	Max => Max,
	CLK => CLK,
	EN  => '1',
	Reset	=> Reset,
	STARTBIT => STARTBIT,
	TX_TICK => TX_Tick,
	RX_TICK => RX_Tick
);
--FIFO instantiation for transmission
FIFO_TX: entity work.FIFO(behavioural)
generic map(
	ram_width => ram_width,
	ram_depth => ram_depth
)
port map(
	CLK    => CLK,
	Reset  => Reset,
 
	in_ready => in_ready_tx,
	in_valid => TX_EN,
	in_data  => TX_DATA,
 
	out_ready => out_ready_tx,
	out_valid => out_valid_tx,
	out_data  => out_data_tx
);

--Read from FIFO_TX and write over TXD
READ_AND_TRANSMIT: process (CLK, Reset)
begin
--------
--RESET
--------
if (Reset = '1') then
	Counter_TX <= x"0";  -- resetting the counter
	parity_TX <= even_odd; -- set parity result to default value
	ctrl_tx <= '0'; -- flow control
	out_ready_tx <= '0'; -- set read status to not reading
	TXD <= '1'; -- send stop bit
elsif rising_edge (CLK) then
	out_ready_tx <= '0'; --set read status to not reading
------------
--START BIT
------------
	if (Counter_TX = x"1" and ctrl_tx = '1') then  -- Counter = 1
		--TRANSMITTING START BIT--
		TXD <= '0'; -- send start-bit
	   ctrl_tx <= '0'; -- enable counting / start bit sent
	end if;
------------
--DATA BITS	
------------
	if (Counter_TX >= x"2" and Counter_TX <= x"9" and ctrl_tx = '1') then -- 1 <  Counter  < 10
		--TRANSMITTING DATA BIT--
		TXD <= out_data_tx (to_integer(Counter_TX)-2);
		--STOP READING--
		ctrl_tx <= '0'; -- enable counting
		if (out_data_tx(to_integer(Counter_TX)-2) = '1' and no_Parity ='0') then -- count 1's and decide if odd or even
			---CALCULATING PARITY---
			Parity_TX <= not Parity_TX;
		end if;
	end if;	
---------------------
--PARITY OR STOP BIT
---------------------	
	if (Counter_TX = x"A" and ctrl_tx = '1') then -- Counter = 10
		ctrl_tx <= '0'; -- enable counting
		out_ready_tx <= '1'; -- get next byte from FIFO_TX
		if (no_Parity = '0') then -- if parity available
			--TRANSMITTING PARITY BIT--
			TXD <= Parity_TX; -- send parity bit
		else -- parity not available
			--TRANSMITTING STOP BIT--
			TXD <= '1'; -- send stop-bit
			--RESETTING THE COUNTER
			Counter_TX <= x"0"; --reset counter
			Parity_TX <= even_odd; --default value of parity
		end if;
	end if;
-----------
--STOP BIT	
-----------	
	if (Counter_TX = x"B" and ctrl_tx = '1') then -- Counter = 11 
		ctrl_tx <= '0'; -- enable counting
		--TRANSMITTING STOP BIT--
		TXD <= '1'; --send stop-bit
		--RESETTING THE COUNTER / PARITY--
		Counter_TX <= x"0"; --reset counter
		Parity_TX <= even_odd; --default value of parity
	end if;	
----------------------
--PREPARE TRANSMISSION
----------------------	
	if (TX_Tick = '1' and out_valid_tx = '1' and ctrl_tx = '0') then -- when FIFO_TX has valid data and baudrate puls appears
		ctrl_tx <= '1'; -- enable transmission
		if (Counter_TX = x"0") then -- if Counter was reset
			Counter_TX <= x"1"; -- set to 1 for startbit
		elsif (Counter_TX >= x"1" and Counter_TX <= x"A") then -- if data bits were transmitted
			Counter_TX <= Counter_TX + 1;  -- increment the counter for further transmission
		end if;
	end if;
end if;
end process READ_AND_TRANSMIT;

--Receive from PC and send over TXD
RECEIVE: process (CLK, Reset)
begin
--------
--RESET
--------
if (Reset = '1') then
	Counter_RX <= x"0"; -- resetting the counter
	Parity_RX <= even_odd; -- set parity result to default value
	RX_EN <= '0'; -- set receive read status to zero  
	RX_ERROR <= '0'; -- set error report to default (no errors)
	RX_DATA <= b"0000_0000"; -- initialize with all zeros
elsif rising_edge (CLK) then
	RX_EN <= '0'; -- set receive read status to zero	
	-------------
	-- START BIT
	-------------
	if (Counter_RX = x"0" and RXD = '0') then
		Counter_RX <= x"1";	
		STARTBIT <= '1';
	end if;
			
	if (RX_Tick = '1' ) then --sampling in the center of the edge
		--INCREMENTING THE COUNTER--	
		Counter_RX <= Counter_RX + 1;

	-------------
	-- DATA BITS
	-------------
		if (Counter_RX > x"1" and Counter_RX < x"A") then -- write 8 data bits
			---SAMPLING AND WRITING--
			RX_DATA(to_integer(Counter_RX) - 2) <= RXD; -- write receiving bit to RX_DATA
			if (RXD = '1' and no_Parity = '0' and RX_Tick = '1') then --count 1's and decide if odd or even
				---CALCULATING PARITY---
				Parity_RX <= not Parity_RX;
			end if;
	----------------------
	-- PARITY OR STOP BIT
	----------------------
		elsif (Counter_RX = x"A") then
			RX_EN <= '1'; -- preparing for receivment
			if (no_Parity = '0') then --if 9th bit parity
				if (RXD /= Parity_RX) then --if bit does not match parity
					--REPORTING ERROR--
					RX_ERROR <= '1';
				else
					--REPORTING SUCCESSFUL TRANSMISSION--
					RX_ERROR <= '0';
				end if;
			else  -- if no parity -> stop-bit
				--RESETTING THE COUNTER--
				Counter_RX <= x"0";
				STARTBIT <= '0';
				Parity_RX <= even_odd; --default value of parity
				if (RXD = '0') then
					--REPORTING ERROR--
					RX_ERROR <= '1';
				else
					--REPORTING SUCCESSFUL TRANSMISSION--
					RX_ERROR <= '0';
				end if;
			end if;

		--PROVING PARITY--
		elsif (Counter_RX = x"B" and no_Parity = '0') then --if parity available
			RX_ERROR <= '0';
			if (RXD = '0') then -- if no stop-bit available
				--REPORTING ERROR--
				RX_ERROR <= '1';
			end if;
			--RESETTING THE COUNTER--
			Counter_RX <= x"0"; --reset the counter
			STARTBIT <= '0';
			Parity_RX <= even_odd; --default value of parity
		end if;
		
		
		
	end if;
	
end if;
end process RECEIVE;

 
--report FIFO_TX space status
TX_BUSY <= not in_ready_tx;

-- calculate and set timer value from desired baud rate	
Max <= to_unsigned((50000000 / (Baudrate*16) - 1), 12);

-------FOR SIMULATION PURPOSES-----		 
--TX_Ti <= TX_Tick;    --<----------uncomment for receive simulation-
--RX_Ti <= RX_Tick;
--
--Count_TX <= std_logic_vector(Counter_TX);
--Count_RX <= std_logic_vector(Counter_RX);
--
--in_ready_t <= in_ready_tx; 
--in_valid_t <= TX_EN;  
--in_data_t <= TX_DATA;  
--out_ready_t <= out_ready_tx;  
--out_valid_t <= out_valid_tx; 
--out_data_t <= out_data_tx; 	 
--			 
end architecture;