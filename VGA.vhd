library ieee;
use ieee.std_logic_1164.all;
use work.LM_VGA.all;

entity VGA IS
	generic (
    frequenzy : integer := 50_000_000;
    h_visible : integer := 799;
    h_front_porch : integer := 855;
    h_Sync_pulse : integer := 975;
    h_back_porch : integer := 1040;
    v_visible : integer := 599;
    v_front_porch : integer := 636;
    v_Sync_pulse : integer := 642;
    v_back_porch : integer := 666;
	 TCO 	: time := 10ns;
	 TD		: time := 2ns
	);
	port(
    CLK_50MHz : in std_logic;
    Reset : in std_logic;
    in_col : in color :=black;
--VGA Outputs
    current_Position : out Position := OO;
    h_sync : out std_logic :='1';
    v_sync : out std_logic :='1';
    out_px : out color := black
	);
end entity VGA;

architecture behave OF VGA IS
  --signal frame_buf_A : gfx_buffer := (others => (others => black )); --https://www.nandland.com/vhdl/examples/example-array-type-vhdl.html
  --signal frame_buf_B : gfx_buffer := (others => (others => black ));
  signal internal_pos : Position := OO;
  signal i_h_sync : std_logic;
  signal i_v_sync : std_logic;
  Signal internal_px :  color := black;
  signal A_or_B : boolean := false;
begin
clocked_proc: PROCESS (CLK_50MHz, Reset)
  			BEGIN
  			IF (Reset = '1') THEN
  				internal_pos <= (x => 0, y => 0);
  			ELSIF rising_edge(CLK_50MHz) THEN
          --if inside of visible area send px value
          if (internal_pos.X <= h_visible AND internal_pos.Y <= v_visible AND (NOT A_or_B)) then
            internal_px <=  black;--frame_buf_A(internal_pos.X, internal_pos.Y);
            --frame_buf_B(internal_pos.X, internal_pos.Y) <= in_col;
          elsif (internal_pos.X <= h_visible AND internal_pos.Y <= v_visible AND  A_or_B) then
            internal_px <=  white; --frame_buf_B(internal_pos.X, internal_pos.Y);
            --frame_buf_A(internal_pos.X, internal_pos.Y) <= in_col;
          else
            internal_px <= black;
          end if;
          --if inside of h_front porch
          if (internal_pos.X > h_front_porch AND internal_pos.X < h_Sync_pulse) then
            i_h_sync <= '0';
          else
            i_h_sync <= '1';
          end if;
          --if inside of v_front porch
          if (internal_pos.Y > v_front_porch AND internal_pos.Y < v_Sync_pulse) then
            i_v_sync <= '0';
          else
            i_v_sync <= '1';
          end if;
          if (internal_pos.X < h_back_porch) then
            internal_pos.X <= internal_pos.X + 1;
          elsif (internal_pos.y < v_back_porch) then
            internal_pos.y <= internal_pos.y +1;
            internal_pos.X <= 0;
          else
            internal_pos <= (x => 0, y => 0);
            --Flip Double Buffer
            A_or_B <= NOT A_or_B;
          end if;
  		  END IF;
        v_sync  <= i_v_sync;
        h_sync  <= i_h_sync;
        out_px  <= internal_px;
END PROCESS clocked_proc;
current_Position <= internal_pos;
out_px <= internal_px;
end architecture behave;
