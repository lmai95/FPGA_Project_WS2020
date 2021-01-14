LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
USE work.bitmaps.ALL;

ENTITY VGA IS
	PORT
	(
		clk   : IN STD_LOGIC;
		rst   : IN STD_LOGIC;
		hsync : OUT STD_LOGIC;
		vsync : OUT STD_LOGIC;

		screen_on : OUT STD_LOGIC;
		hori_pos  : OUT INTEGER;
		vert_pos  : OUT INTEGER
	);

END ENTITY VGA;

ARCHITECTURE behave OF VGA IS

	SIGNAL hpos : INTEGER := 0; -- Momentane horizontal Position
	SIGNAL vpos : INTEGER := 0; -- Momentane vertikale Postition

	SIGNAL on_screen : STD_LOGIC := '0';

BEGIN

	-- Horzontaler Zähler von links nach rechts
	HPOS_counter : PROCESS (clk, rst)
	BEGIN
		IF rst = '0' THEN
			hpos <= 0;
		ELSIF rising_edge(clk) THEN
			IF (hpos = (HD + HFP + HSP + HBP)) THEN
				hpos <= 0;
			ELSE
				hpos <= hpos + 1;
			END IF;
		END IF;
	END PROCESS;

	-- Vertikaler Zähler von oben nach unten
	VPOS_counter : PROCESS (clk, rst, hpos)
	BEGIN
		IF rst = '0' THEN
			vpos <= 0;
		ELSIF rising_edge(clk) THEN
			IF (hpos = (HD + HFP + HSP + HBP)) THEN
				IF (vpos = (VD + VFP + VSP + VBP)) THEN
					vpos <= 0;
				ELSE
					vpos <= vpos + 1;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	-- Horizontal Synchrosignal 
	H_Synchro : PROCESS (clk, rst, hpos)
	BEGIN
		IF rst = '0' THEN
			hsync <= '0';
		ELSIF rising_edge(clk) THEN
			IF ((hpos <= (HD + HFP)) OR (hpos > HD + HFP + HSP)) THEN
				hsync <= '1';
			ELSE
				hsync <= '0';
			END IF;
		END IF;
	END PROCESS;

	-- Vertikal Synchrosignal
	V_Synchro : PROCESS (clk, rst, vpos)
	BEGIN
		IF rst = '0' THEN
			vsync <= '0';
		ELSIF rising_edge(clk) THEN
			IF ((vpos <= (VD + VFP)) OR (vpos > VD + VFP + VSP)) THEN
				vsync <= '1';
			ELSE
				vsync <= '0';
			END IF;
		END IF;
	END PROCESS;

	-- 1 == Zähler ist im Bildschirm ==> Darstellung OK!
	-- 0 == Zähler ist nicht im sichtbaren Teil ==> Darstellung NG!
	on_screen_check : PROCESS (clk, rst, hpos, vpos)
	BEGIN
		IF rst = '0' THEN
			on_screen <= '0';
		ELSIF rising_edge(clk) THEN
			IF (hpos <= HD AND vpos <= VD) THEN
				on_screen <= '1';
			ELSE
				on_screen <= '0';
			END IF;
		END IF;
	END PROCESS;

	-- Signale "abfangen" um sie außerhalb dieses Moduls zu verwenden
	hori_pos <= hpos;
	vert_pos <= vpos;
	screen_on <= on_screen;

END ARCHITECTURE behave;
