library ieee;
use ieee.std_logic_1164.all;
use work.LM_VGA.all;
use work.Symbols.all;

entity GPU IS
	generic (
		T		: time := 20ns;
		TCO 	: time := 5ns;
		TD		: time := 1ns
	);
	port(
  CLK_50MHz : in std_logic;
  enable_plotter :in std_logic;
  Reset : in std_logic;
	h_sync : out std_logic :='1';
	v_sync : out std_logic :='1';
	red : out std_logic_vector (3 downto 0):= x"0";
	green : out std_logic_vector (3 downto 0):= x"0";
	blue : out std_logic_vector (3 downto 0):= x"0"
	);
end entity GPU;

architecture behave of GPU IS

signal bus_busy :std_logic;
signal VGA_VRAM_address :natural range 0 to 480000 := 0;
signal VGA_pixel_data : std_logic_vector(11 downto 0) := x"0_0_0";
signal GPU_pixel_data : std_logic_vector(11 downto 0) := x"0_0_0";
signal GPU_VRAM_address :natural range 0 to 480000 := 0;
signal GPU_WriteEnable : std_logic;
begin

VGA: entity work.VGA(behave)
  port map (
	--VGA -input
	CLK_50MHz => CLK_50MHz,--: in std_logic;
	Reset => Reset,--: in std_logic;
	--Internal_bus
	data_in => VGA_pixel_data,--: in std_logic_vector(11 downto 0) := x"00_00_00";
	VRAM_address => VGA_VRAM_address, --: 	out natural range 0 to 480000 := 0;
	--VGA Outputs
	h_sync => h_sync,--: out std_logic :='1';
	v_sync => v_sync,--: out std_logic :='1';
	red => red,--: out std_logic_vector (3 downto 0):= x"0";
	green => green,--: out std_logic_vector (3 downto 0):= x"0";
	blue => blue--: out std_logic_vector (3 downto 0):= x"0"
  );

plotter : entity work.plotter(behave)
		port map(
		--external Inputs
			CLK_50MHz => CLK_50MHz, --: in std_logic;
			Reset => Reset,-- : in std_logic;
		--VGA Inputs
			sym => x21,-- : in Symbol;
			startpoint => (0,0),-- : in position;
			color => X"F_0_0",-- : in R4G4B4;
			signal_valid => enable_plotter,-- : in std_logic;
		--VGA Outputs
			bus_used => bus_busy,-- : out std_logic;
			VRAM_address => GPU_VRAM_address,-- : 	out natural range 0 to 480000 := 0;
			data => GPU_pixel_data,-- : out std_logic_vector(11 downto 0) := x"0_0_0"
			frame_buffer_WriteEnable => GPU_WriteEnable--:out std_logic
		);

frame_buffer: entity work.frame_buffer(behave)
		port map(
		GPU_data_in	=> GPU_pixel_data,--: in std_logic_vector(11 downto 0); 		--Data input from GPU
		GPU_WriteEnable	=> GPU_WriteEnable,--: in std_logic := '1';
		GPU_addr	=> GPU_VRAM_address,--: in natural range 0 to 480000;						--address to write data from GPU to memory
		VGA_addr	=> VGA_VRAM_address, --: in natural range 0 to 480000;						--address to read data from memory
		VGA_data_out	=> VGA_pixel_data, --: out std_logic_vector(11 downto 0);	--Data output to VGA
		clk		=> CLK_50MHz--: in std_logic
);


end architecture behave;
