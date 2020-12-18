
library ieee;
use ieee.std_logic_1164.all;
use work.LM_VGA.all;
use work.Symbols.all;



entity plotter IS
	port(
	--external Inputs
    CLK_50MHz : in std_logic;
    Reset : in std_logic;
	--VGA Inputs
  	sym : in Symbol;
    startpoint : in position;
    color : in R4G4B4;
    signal_valid : in std_logic;
	--VGA Outputs
    bus_used : out std_logic;
  	VRAM_address : 	out natural range 0 to 480000 := 0;
    data : out std_logic_vector(11 downto 0) := x"0_0_0";
    frame_buffer_WriteEnable :out std_logic
	);
end entity plotter;

architecture behave OF plotter IS
type typewriter_state is (Idle, busy);
signal current_state : typewriter_state;
signal next_state : typewriter_state;
BEGIN
clocked_proc: PROCESS (CLK_50MHz, Reset)
  variable pos : Position;
  variable col : R4G4B4;
  variable drawing : boolean;
  variable X : integer range 0 to 6;
  variable Y : integer range 0 to 10;
BEGIN
  IF (Reset = '1') THEN
  --Reset Case set drawing Position to 0 0 and output black
  pos := OO;
  current_state <= Idle;
  ELSIF rising_edge(CLK_50MHz) THEN
    current_state <= next_state;
    frame_buffer_WriteEnable <= '0';
    CASE current_state IS
      WHEN IDLE =>
        bus_used <= '0';
        x := 0;
        y := 0;
        drawing := false;
        IF (signal_valid ='1') THEN
        pos := startpoint;
        col := color;
        next_state <= busy;
        END IF;
      WHEN busy =>
        bus_used <= '1';
        drawing := true ;--(sym(x,y) = '1');
        IF drawing THEN 
			data <= col;
		  ELSE 
			data <= black;
		  END IF; 
        VRAM_address <= pos.x + x + ((pos.y + y)*800);
        frame_buffer_WriteEnable <= '1';
        x := x + 1;
        IF (x = 5) THEN
          x := 0;
          y := y + 1;
        END IF;
        IF (y = 10) THEN
          next_state <= Idle;
        END IF;
    END CASE;
  END IF;
  END process;
END behave;
