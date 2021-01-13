library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity VGA is
	port(
		clk	: in std_logic;
		rst	: in std_logic;
		hsync : out std_logic;
		vsync : out std_logic;
		
		screen_on : out std_logic;
		hori_pos : out integer;
		vert_pos : out integer
	);
	
end entity VGA;

architecture behave of VGA is
	
	-- VGA Timing Werte aus TinyVGA.com
	constant HD		: integer := 639;	-- Visible Area
	constant HFP	: integer := 16;	-- Front Porch
	constant HSP	: integer := 96;	-- Sync Pulse
	constant HBP	: integer := 48;	-- Back Porch
	
	constant VD		: integer := 479;	-- Visible Area 
	constant VFP	: integer := 10;	-- Front Porch
	constant VSP	: integer := 2;	-- Sync Pulse
	constant VBP	: integer := 33;	-- Back Porch
	
	signal hpos		: integer := 0;	-- Momentane horizontal Position
	signal vpos 	: integer := 0;	-- Momentane vertikale Postition
	
	signal on_screen : std_logic := '0';

begin
	
	-- Horzontaler Zähler von links nach rechts
	HPOS_counter : process(clk, rst)
		begin
			if rst = '0' then
				hpos <= 0;
			elsif rising_edge(clk) then
				if(hpos = (HD + HFP + HSP + HBP)) then
					hpos <= 0;
				else
					hpos <= hpos + 1;
				end if;
			end if;
		end process;
	
	-- Vertikaler Zähler von oben nach unten
	VPOS_counter : process(clk, rst, hpos)
		begin
			if rst = '0' then
				vpos <= 0;
			elsif rising_edge(clk) then
				if(hpos = (HD + HFP + HSP + HBP)) then
					if(vpos = (VD + VFP + VSP + VBP)) then
						vpos <= 0;
					else
						vpos <= vpos + 1;
					end if;
				end if;
			end if;
		end process;
	
	-- Horizontal Synchrosignal 
	H_Synchro : process(clk, rst, hpos)
		begin
			if rst = '0' then
				hsync <= '0';
			elsif rising_edge(clk) then
				if((hpos <= (HD + HFP)) or (hpos > HD + HFP + HSP)) then
					hsync <= '1';
				else
					hsync <= '0';
				end if;
			end if;
		end process;
			
	-- Vertikal Synchrosignal
	V_Synchro : process(clk, rst, vpos)
		begin
			if rst = '0' then
				vsync <= '0';
			elsif rising_edge(clk) then
				if((vpos <= (VD + VFP)) or (vpos > VD + VFP + VSP)) then
					vsync <= '1';
				else
					vsync <= '0';
				end if;
			end if;
		end process;
	
	-- 1 == Zähler ist im Bildschirm ==> Darstellung OK!
	-- 0 == Zähler ist nicht im sichtbaren Teil ==> Darstellung NG!
	on_screen_check : process(clk, rst, hpos, vpos)
		begin
			if rst = '0' then
				on_screen <= '0';
			elsif rising_edge(clk) then
				if(hpos <= HD and vpos <= VD) then
					on_screen <= '1';
				else
					on_screen <= '0';
				end if;
			end if;
		end process;
	
	-- Signale "abfangen" um sie außerhalb dieses Moduls zu verwenden
	hori_pos <= hpos;
	vert_pos <= vpos;
	screen_on <= on_screen;
	
end architecture behave;