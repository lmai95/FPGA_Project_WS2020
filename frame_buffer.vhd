library ieee;
use ieee.std_logic_1164.all;
use work.LM_VGA.all;
use work.Symbols.all;

entity frame_buffer is
	port
	(
		GPU_data_in	: in std_logic_vector(11 downto 0); 		--Data input from GPU
		GPU_WriteEnable	: in std_logic := '1';
		GPU_addr	: in natural range 0 to 480000;						--address to write data from GPU to memory
		VGA_addr	: in natural range 0 to 480000;						--address to read data from memory
		VGA_data_out	: out std_logic_vector(11 downto 0);	--Data output to VGA
		clk		: in std_logic																--
	);
end frame_buffer;

architecture behave of frame_buffer is
	-- Build a 2-D array type for the RAM
	type memory_t is array(0 to 480000) of R4G4B4;
	-- Declare the RAM
	shared variable ram : memory_t;
begin
	--write to memory from GPU
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(GPU_WriteEnable = '1') then
				ram(GPU_addr) := GPU_data_in;
			end if;
		end if;
	end process;
	--read from  memory to the VGA Port
	process(clk)
	begin
		if(rising_edge(clk)) then
			VGA_data_out <= ram(VGA_addr);
			--VGA_data_out <= (OTHERS => '1');
		end if;
	end process;
end behave;
