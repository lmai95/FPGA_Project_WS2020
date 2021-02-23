library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master is
	generic (
		spi_mode          : integer := 0;		-- spi mode according to spi stardard modes
		clks_per_half_bit : integer := 2		-- main clock edged per half bit on the spi interface
	);
	port (
		-- control signals
		i_rst_l : in std_logic;
		i_clk   : in std_logic;

		-- tx  signals
		i_tx_byte   : in std_logic_vector(7 downto 0);	-- transmit buffer
		i_tx_dv     : in std_logic;						-- start transmit
		o_tx_ready  : buffer std_logic; 				-- indicates if the transmitter is ready

		-- rx signals		
		o_rx_dv   : out std_logic;						-- indeicates if one byte was received
		o_rx_byte : out std_logic_vector(7 downto 0);	-- receive buffer

		-- spi hardware interface
		o_spi_clk  : out std_logic;						-- spi clock signal
		i_spi_miso : in  std_logic;						-- spi master-in slave-out
		o_spi_mosi : out std_logic						-- spi master-out slave-in
	);
end entity spi_master;

architecture rtl of spi_master is

	signal r_cpol : std_logic;							-- clock polarity
	signal r_cpha : std_logic;							-- clock phase

	signal r_spi_clk_count : integer range 0 to clks_per_half_bit*2-1;	-- counter for clock generator
	signal r_spi_clk       : std_logic;	
	signal r_spi_clk_edges : integer range 0 to 16;
	signal r_leading_edge  : std_logic;
	signal r_falling_edge : std_logic;
	signal r_tx_dv         : std_logic;
	signal r_tx_byte       : std_logic_vector(7 downto 0);

	signal r_rx_bit_count : unsigned(2 downto 0);		-- 8-bit sized counter
	signal r_tx_bit_count : unsigned(2 downto 0);

	begin
	
	-- set the clock polarity and clock phase according to the spi mode
	r_cpol <= '1' when (spi_mode = 2) or (spi_mode = 3) else '0';
	r_cpha <= '1' when (spi_mode = 1) or (spi_mode = 3) else '0';

	-- clock_generator: generate spi clock when the tx-dv signal is set
	clock_generator : process (i_clk, i_rst_l)
	begin
		if i_rst_l = '0' then
			o_tx_ready      <= '0';
			r_spi_clk_edges <= 0;
			r_leading_edge  <= '0';
			r_falling_edge <= '0';
			r_spi_clk       <= r_cpol;
			r_spi_clk_count <= 0;
			
		elsif rising_edge(i_clk) then

			-- default
			r_leading_edge  <= '0';
			r_falling_edge <= '0';
			-- wait for tx-dv
			if i_tx_dv = '1' then
				o_tx_ready      <= '0';
				r_spi_clk_edges <= 16;
			elsif r_spi_clk_edges > 0 then
				o_tx_ready <= '0';
			-- create falling edged on uneven numbers
			if r_spi_clk_count = clks_per_half_bit*2-1 then
				r_spi_clk_edges <= r_spi_clk_edges - 1;
				r_falling_edge <= '1';
				r_spi_clk_count <= 0;
				r_spi_clk       <= not r_spi_clk;
			-- create rising edge on even numbers
			elsif r_spi_clk_count = clks_per_half_bit-1 then
				r_spi_clk_edges <= r_spi_clk_edges - 1;
				r_leading_edge  <= '1';
				r_spi_clk_count <= r_spi_clk_count + 1;
				r_spi_clk       <= not r_spi_clk;
			else
			-- keep counting up
				r_spi_clk_count <= r_spi_clk_count + 1;
			end if;
			else
			-- indicate that the spi master is ready when finsihed sending one byte
				o_tx_ready <= '1';
			end if;
		end if;
	end process clock_generator;

	-- tx_byte_reg: save the transmt byte from the transmit buffer if tx-dv is set
	tx_byte_reg : process (i_clk, i_rst_l)
	begin
		-- reset module
		if i_rst_l = '0' then
			r_tx_byte <= x"00";
			r_tx_dv   <= '0';
		elsif rising_edge(i_clk) then
			r_tx_dv <= i_tx_dv;
			if i_tx_dv = '1' then
				-- save teh byte from the tx-buffer
				r_tx_byte <= i_tx_byte;
			end if;
		end if;
	end process tx_byte_reg;

	-- spi_send: transmit sone byte according to the spi mode settings
	spi_send : process (i_clk, i_rst_l)
	begin
		if i_rst_l = '0' then
		o_spi_mosi     <= '0';
		r_tx_bit_count <= "111";
		elsif rising_edge(i_clk) then
			-- reset bit-counter
			if o_tx_ready = '1' then
				r_tx_bit_count <= "111";
			-- clock phase is not set
			elsif (r_tx_dv = '1' and r_cpha = '0') then
				o_spi_mosi     <= r_tx_byte(7);
				r_tx_bit_count <= "110";
			-- clock phase is set
			elsif (r_leading_edge = '1' and r_cpha = '1') or (r_falling_edge = '1' and r_cpha = '0') then
				r_tx_bit_count <= r_tx_bit_count - 1;
				o_spi_mosi     <= r_tx_byte(to_integer(r_tx_bit_count));
			end if;
		end if;
	end process spi_send;

	-- spi_receive: receive one byte from the spi interface
	spi_receive : process (i_clk, i_rst_l)
	begin
		-- reset
		if i_rst_l = '0' then
			o_rx_byte      <= x"00";
			o_rx_dv        <= '0';
			r_rx_bit_count <= "111";
		elsif rising_edge(i_clk) then
			-- default
			o_rx_dv <= '0';
		if o_tx_ready = '1' then
			r_rx_bit_count <= "111";
		-- either sample on leasing or falling edge depending on spi mode
		elsif (r_leading_edge = '1' and r_cpha = '0') or (r_falling_edge = '1' and r_cpha = '1') then
			o_rx_byte(to_integer(r_rx_bit_count)) <= i_spi_miso;
			r_rx_bit_count <= r_rx_bit_count - 1;
			if r_rx_bit_count = "000" then
				o_rx_dv <= '1';
			end if;
			end if;
		end if;
	end process spi_receive;

	-- spi_clock_delay: delay the spi clock by one clock cycle so synchronize the output with the design
	spi_clock_delay : process (i_clk, i_rst_l)
	begin
		if i_rst_l = '0' then
			o_spi_clk  <= r_cpol;
		elsif rising_edge(i_clk) then
			o_spi_clk <= r_spi_clk;
		end if;
	end process spi_clock_delay;

end architecture rtl;
