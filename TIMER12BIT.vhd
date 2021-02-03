library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

entity TIMER12BIT is
port(
	Max:   in unsigned (11 downto 0) ;
	CLK:   in std_logic;
	EN:    in std_logic;
	Reset: in std_logic := '0';

	CAS:   out std_logic := '0'
);
end entity TIMER12BIT;


architecture behavioural of TIMER12BIT is
	signal Q_i: unsigned (11 downto 0) := x"000";

begin
	CAS <= '1' when(Q_i = Max) else '0';
INCREMENT: process(CLK,Reset) is
	begin
		if (Reset='1') then
			Q_i <= x"000";
		elsif rising_edge(CLK) then
			if(EN = '1') then
				if (Q_i = Max) then
					Q_i <= x"000";
				else
					Q_i <= Q_i + 1;
				end if;
			end if;
		end if;
end process INCREMENT;

end architecture behavioural;
	
	