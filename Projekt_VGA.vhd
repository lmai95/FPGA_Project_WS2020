library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Projekt_VGA is
	port(
			clk	: in std_logic;
			rst	: in std_logic;
			hsync : out std_logic;
			vsync : out std_logic;
			red	: out std_logic_vector(3 downto 0);
			blue	: out std_logic_vector(3 downto 0);
			green	: out std_logic_vector(3 downto 0)
		);
end entity Projekt_VGA;

architecture behave of Projekt_VGA is
	
	component VGA is
		port(
			clk	: in std_logic;
			rst	: in std_logic;
			hsync : out std_logic;
			vsync : out std_logic;
			screen_on : out std_logic;
			hori_pos : out integer;
			vert_pos : out integer
		);
	end component;
	
	component clk_generator is
		generic(
		freq_MHZ : integer := 25
		);
		port(
			clk_in	: in std_logic;
			clk_out 	: out std_logic
		);
	end component;
	
	component VGA_WerteDarstellung is
		port(
			clk	: in std_logic;
			rst	: in std_logic;
			screen_on : in std_logic;
			X : in integer;
			Y : in integer;
			rgb	: out std_logic_vector(11 downto 0)
		);
	end component;
	
	signal clk_25 : std_logic;
	signal screen_on : std_logic := '0';
	signal hpos : integer := 0;
	signal vpos : integer := 0;
	
	signal rgb : std_logic_vector(11 downto 0);
	
begin

	red <= rgb(11 downto 8);
	green <= rgb(7 downto 4);
	blue <= rgb(3 downto 0);

	clk_25MHz : clk_generator
		generic map(
			freq_MHZ => 25
		)
		port map(
			clk_in	=> clk,
			clk_out 	=> clk_25
		);

	vga_controller : VGA
	port map(
		clk	=> clk_25,
		rst	=> rst,
		hsync => hsync,
		vsync => vsync,
		screen_on => screen_on,
		hori_pos => hpos,
		vert_pos => vpos
	);
	
	darstellung : VGA_WerteDarstellung
	port map(
			clk	=> clk_25,
			rst	=> rst,
			screen_on => screen_on,
			X => hpos,
			y => vpos,
			rgb	=> rgb
		);

end architecture behave;