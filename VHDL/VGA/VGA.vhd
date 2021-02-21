LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.bitmaps.ALL;

ENTITY VGA IS
	PORT (
		clk   : IN STD_LOGIC;
		rst   : IN STD_LOGIC;
		hsync : OUT STD_LOGIC;
		vsync : OUT STD_LOGIC;
		red   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		blue  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		green : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		data_valid   : IN STD_LOGIC;
		x_in : IN INTEGER RANGE -9999 TO 9999;
		y_in : IN INTEGER RANGE -9999 TO 9999;
		z_in : IN INTEGER RANGE -9999 TO 9999
	);
END ENTITY VGA;

ARCHITECTURE behave OF VGA IS
	SIGNAL clk_25    : STD_LOGIC;
	SIGNAL screen_on : STD_LOGIC := '0';
	SIGNAL hpos      : INTEGER   := 0;
	SIGNAL vpos      : INTEGER   := 0;
	SIGNAL rgb       : STD_LOGIC_VECTOR(11 DOWNTO 0);

	SIGNAL x_wert : INTEGER := 4962;
	SIGNAL y_wert : INTEGER := 5678;
	SIGNAL z_wert : INTEGER := - 9150;

BEGIN

	red   <= rgb(11 DOWNTO 8);
	green <= rgb(7 DOWNTO 4);
	blue  <= rgb(3 DOWNTO 0);

	clk_divider : ENTITY work.clk_generator
	GENERIC
	MAP(
	freq_MHZ => 25
	)
	PORT MAP(
		clk_in  => clk,
		clk_out => clk_25
	);

	Syncgen : ENTITY work.VGA_Syncgen
	GENERIC MAP(
	HD  => HD,  -- Visible Area
	HFP => HFP, -- Front Porch
	HSP => HSP, -- Sync Pulse
	HBP => HBP, -- Back Porch

	VD  => VD,  -- Visible Area 
	VFP => VFP, -- Front Porch
	VSP => VSP, -- Sync Pulse
	VBP => VBP  -- Back Porch
	)
	PORT MAP(
		clk       => clk,
		clk_en    => clk_25,
		rst       => rst,
		hsync     => hsync,
		vsync     => vsync,
		screen_on => screen_on,
		hori_pos  => hpos,
		vert_pos  => vpos
	);

	Darstellung : ENTITY work.VGA_Darstellung
	GENERIC MAP(
	hpos_total => HD + HFP + HSP + HBP,
	vpos_total => VD + VFP + VSP + VBP
	)
	PORT MAP(
		clk       => clk,
		rst       => rst,
		screen_on => screen_on,
		hpos      => hpos,
		vpos      => vpos,
		data_valid => data_valid,
		x_int     => x_in,
		y_int     => y_in,
		z_int     => z_in,
		rgb       => rgb
	);

END ARCHITECTURE behave;
