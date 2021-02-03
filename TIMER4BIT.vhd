library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

entity TIMER4BIT is
port(
	CLK:   in std_logic;
	EN0:    in std_logic;
	Reset: in std_logic := '0';
	EN1:in std_logic;
	
	RX_TICK: out std_logic := '0';  
	CAS:   out std_logic := '0'
);
end entity TIMER4BIT;

architecture behavioural of TIMER4BIT is
	signal Q_0, Q_1:   unsigned(3 downto 0):= x"0";
	 
begin
	RX_TICK  <= '1' when (Q_1 = x"8") else '0'; 
	CAS <= '1' when (Q_0 = x"F") else '0';
INCREMENT: process(CLK,Reset) is
	begin
		if (Reset='1') then
			Q_0 <= x"0";
		elsif rising_edge(CLK) then 
			if(EN0 = '1') then
				if (Q_0 = x"F") then
					Q_0 <= x"0";
				else
					Q_0 <= Q_0 + 1;
				end if;
				
				if(EN1 = '1')then
					if (Q_1 = x"F") then
						Q_1 <= x"0";
						else
						Q_1 <= Q_1 + 1;
					end if;
				else
					Q_1 <= x"0";				
				end if;
			end if;
		end if;
end process INCREMENT;



end architecture behavioural;
	
	