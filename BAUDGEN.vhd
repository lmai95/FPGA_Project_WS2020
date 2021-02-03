 library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BAUDGEN is
port(
	CLK:   in std_logic;
	EN:    in std_logic := '0';
	Reset: in std_logic := '0';
	Max:   in unsigned (11 downto 0);
	STARTBIT: in std_logic := '0';
	
	TX_TICK: out std_logic := '0';
	RX_TICK: out std_logic := '0'
);
end entity BAUDGEN;

architecture behavioural of BAUDGEN is 
	signal CAS_RX, CAS_TX, RX_TICK_i:  std_logic := '0';
	
begin

TIMER12: entity work.TIMER12BIT(behavioural)
port map(
	Max => Max,
	CLK => CLK,
	Reset	=> Reset,
	EN => EN,
	CAS => CAS_RX
);

TIMER4: entity work.TIMER4BIT(behavioural)
port map(
	CLK => CLK,
	Reset	=> Reset,
	EN0 => CAS_RX,
	CAS => CAS_TX,
	EN1 => STARTBIT,
	RX_TICK => RX_TICK_i
);


			 
RX_TICK <= CAS_RX and RX_TICK_i; -- Oversampling
TX_TICK <= CAS_RX and CAS_TX; -- Baud rate tick 


end architecture behavioural;