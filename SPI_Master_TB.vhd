library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master_tb is
end entity spi_master_tb;

architecture tb of spi_master_tb is

	constant spi_mode 			: integer := 0;
	constant clks_per_half_bit 	: integer := 4;

	-- signals to connect the modules
	signal r_rst_l    			: std_logic := '0';
	signal r_spi_clk			: std_logic;
	signal r_clk      			: std_logic := '0';
	signal r_spi_mosi 			: std_logic;

	-- signals for the spi master
	signal r_master_tx_byte  	: std_logic_vector(7 downto 0) := x"00";
	signal r_master_tx_dv    	: std_logic := '0';
	signal r_master_cs_n     	: std_logic := '1';
	signal r_master_tx_ready 	: std_logic;
	signal r_master_rx_dv    	: std_logic := '0';
	signal r_master_rx_byte  	: std_logic_vector(7 downto 0) := x"00";

	begin

		-- main clock
		r_clk <= not r_clk after 2 ns;

		-- device under test: SPI-Master
		dut : entity work.spi_master
			generic map (
			spi_mode          => spi_mode,
			clks_per_half_bit => clks_per_half_bit)
			port map (
			-- control signals
			i_rst_l    => r_rst_l,           		-- device reset
			i_clk      => r_clk,              		-- main clock
			-- tx signals
			i_tx_byte  => r_master_tx_byte,         -- byte to transmit
			i_tx_dv    => r_master_tx_dv,           -- data valid pulse
			o_tx_ready => r_master_tx_ready,        -- transmit ready for byte
			-- rx signals
			o_rx_dv    => r_master_rx_dv,           -- data valid pulse
			o_rx_byte  => r_master_rx_byte,      	-- byte received on miso
			-- spi hardware intreface
			o_spi_clk  => r_spi_clk, 
			i_spi_miso => r_spi_mosi,				-- rx to tx
			o_spi_mosi => r_spi_mosi
		);
		
		-- This testbench sends one byte to over the spi-interface. The transmit port is connected to the receive port.
		-- In this way we can test the sending and receiving at the same time.
	tester : process is
	begin

		wait for 50 ns;		-- reset the device
		r_rst_l <= '0';
		wait for 50 ns;
		r_rst_l <= '1';

		-- send and receive one byte
		wait until rising_edge(r_clk);		-- make sure the design works synchronously
		r_master_tx_byte <= X"A9";			-- write one dummy byte to the transmit buffer
		r_master_tx_dv   <= '1';			-- start transmitting
		wait until rising_edge(r_clk);		
		r_master_tx_dv   <= '0';
		wait until rising_edge(r_master_rx_dv);		-- wait until one byte was received
		assert(r_master_rx_byte = X"A9") report "Failed to receive one byte." severity error; 	--check if the received byte matches the sent byte
		
		wait for 50 ns;
		assert false report "Test Complete" severity failure;	-- test complete, stop the process
		
	end process tester;

end architecture tb;