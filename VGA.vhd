library ieee;
use ieee.std_logic_1164.all;
use work.LM_VGA.all;

entity VGA IS
	generic (
    frequenzy : integer := 50_000_000;
    h_visible : integer := 799;
    h_front_porch : integer := 855;
    h_Sync_pulse : integer := 975;
    h_back_porch : integer := 1039;
    v_visible : integer := 599;
    v_front_porch : integer := 636;
    v_Sync_pulse : integer := 642;
    v_back_porch : integer := 665;
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
	signal v : sync_signals :=('0','0','0','0');
	signal h : sync_signals :=('0','0','0','0');
  Signal internal_px :  color := black;
  signal A_or_B : boolean := false;
begin
clocked_proc: PROCESS (CLK_50MHz, Reset)
variable v_pos : Position;
variable vertical : sync_signals :=('0','0','0','0');
variable horizontal : sync_signals :=('0','0','0','0');
  			BEGIN
  			IF (Reset = '1') THEN
					v_pos := OO;
					internal_px <= black;
  			ELSIF rising_edge(CLK_50MHz) THEN
				horizontal := ('0','0','0','0');
				vertical   := ('0','0','0','0');
				CASE v_pos.X IS
					WHEN 0  to  h_visible => horizontal.visible := '1';
					WHEN (h_visible+1) to h_front_porch => horizontal.front_porch := '1';
					WHEN (h_front_porch+1) to h_Sync_pulse => horizontal.sync := '1';
					WHEN h_Sync_pulse+1 to h_back_porch => horizontal.back_porch := '1';
					WHEN OTHERS =>
						v_pos.Y := internal_pos.Y + 1;
						v_pos.X := 0;
						horizontal.visible := '1';
				END CASE;
				CASE v_pos.Y IS
					WHEN 0  to  v_visible => vertical.visible := '1';
					WHEN (v_visible+1) to v_front_porch => vertical.front_porch := '1';
					WHEN (v_front_porch+1) to v_Sync_pulse => vertical.sync := '1';
					WHEN v_Sync_pulse+1 to v_back_porch => vertical.back_porch := '1';
					WHEN OTHERS => v_pos.Y  := 0;
				END CASE;
				IF (vertical.visible = '1' AND horizontal.visible = '1') THEN
					IF A_or_B THEN
						internal_px <= white;
						--internal_px <= frame_buf_A(v_pos.X, v_pos.Y);
					ELSE
						internal_px <= white;
						--internal_px <= frame_buf_B(v_pos.X, v_pos.Y);
					END IF;
				ELSE
					internal_px <= black;
				END IF;
				v <= vertical;
				h <= horizontal;
				internal_pos <= v_pos;
				v_pos.X := v_pos.X + 1;
			END IF;
END PROCESS clocked_proc;
v_sync  <= NOT v.sync;
h_sync  <= NOT h.sync;
out_px  <= internal_px;
current_Position <= internal_pos;
end architecture behave;
