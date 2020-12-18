library ieee;
use ieee.std_logic_1164.all;
use work.LM_VGA.all;
use work.Symbols.all;

entity VGA IS
	generic (
    --VGA Line numbers
	 h_visible : integer := 799;
    h_front_porch : integer := 855;
    h_Sync_pulse : integer := 975;
    h_back_porch : integer := 1039;
    v_visible : integer := 599;
    v_front_porch : integer := 636;
    v_Sync_pulse : integer := 642;
    v_back_porch : integer := 665;
	 --Simulation time parameter
	 TCO 	: time := 10ns;
	 TD		: time := 2ns
	);
	port(
	--external Inputs
    CLK_50MHz : in std_logic;
    Reset : in std_logic;
	--VGA Inputs
  	data_in : in std_logic_vector(11 downto 0) := x"0_0_0";
	--VGA Outputs
  	VRAM_address  	: 	out natural range 0 to 480000 := 0;
    h_sync : out std_logic :='1';
    v_sync : out std_logic :='1';
		red : out std_logic_vector (3 downto 0):= x"0";
		green : out std_logic_vector (3 downto 0):= x"0";
		blue : out std_logic_vector (3 downto 0):= x"0"
	);
end entity VGA;

architecture behave OF VGA IS
	signal v : sync_signals ;
	signal h : sync_signals ;
  Signal internal_px :  std_logic_vector(11 downto 0) := x"0_0_0";
begin
clocked_proc: PROCESS (CLK_50MHz, Reset)
	variable pos : Position;
	variable vertical : sync_signals;
	variable horizontal : sync_signals;
  BEGIN
  	IF (Reset = '1') THEN
		--Reset Case set drawing Position to 0 0 and output black
			pos := OO;
			internal_px <= x"0_0_0";
  	ELSIF rising_edge(CLK_50MHz) THEN
			--set mode based on vertical Position
			CASE pos.X IS
				WHEN 0  to  h_visible => horizontal:= visible;
				WHEN (h_visible+1) to h_front_porch => horizontal:=front_porch ;
				WHEN (h_front_porch+1) to h_Sync_pulse => horizontal:=sync;
				WHEN h_Sync_pulse+1 to h_back_porch => horizontal:=back_porch;
				WHEN OTHERS =>
					pos.Y := pos.Y + 1;
					pos.X := 0;
					horizontal :=visible;
			END CASE;
				--set mode based on horizontal Position
			CASE pos.Y IS
				WHEN 0  to  v_visible => vertical:= visible;
				WHEN (v_visible+1) to v_front_porch => vertical:=front_porch;
				WHEN (v_front_porch+1) to v_Sync_pulse => vertical:=sync;
				WHEN v_Sync_pulse+1 to v_back_porch => vertical:=back_porch;
				WHEN OTHERS => pos.Y  := 0;
			END CASE;
				--if visible write Data to the VGA port
				IF (vertical = visible  AND horizontal = visible ) THEN
					internal_px <= data_in;
					--select the next VRAM address to get the next value for the Frambuffer
					VRAM_address <= pos.X + (pos.Y * 800);
				ELSE
					internal_px <= x"0_0_0";
				END IF;
				v <= vertical;
				h <= horizontal;
				pos.X := pos.X + 1;
			END IF;
END PROCESS clocked_proc;
v_sync  <= '0' when v = sync else '1';
h_sync  <= '0' when h = sync else '1';
red <= internal_px(11 downto  8);
green <= internal_px(7 downto 4);
blue <= internal_px(3 downto 0);

end architecture behave;
