library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SPI_Master is
  generic (
    SPI_MODE          : integer := 0;
    CLKS_PER_HALF_BIT : integer := 2
    );
  port (
   -- Control/Data Signals,
   i_Rst_L : in std_logic;
   i_Clk   : in std_logic;
   
   -- TX (MOSI) Signals
   i_TX_Byte   : in std_logic_vector(7 downto 0);
   i_TX_DV     : in std_logic;
   o_TX_Ready  : buffer std_logic; 
   
   -- RX (MISO) Signals		
   o_RX_DV   : out std_logic;
   o_RX_Byte : out std_logic_vector(7 downto 0);

   -- SPI Interface
   o_SPI_Clk  : out std_logic;
   i_SPI_MISO : in  std_logic;
   o_SPI_MOSI : out std_logic
   );
end entity SPI_Master;

architecture RTL of SPI_Master is

  signal w_CPOL : std_logic;
  signal w_CPHA : std_logic;

  signal r_SPI_Clk_Count : integer range 0 to CLKS_PER_HALF_BIT*2-1;
  signal r_SPI_Clk       : std_logic;
  signal r_SPI_Clk_Edges : integer range 0 to 16;
  signal r_Leading_Edge  : std_logic;
  signal r_Trailing_Edge : std_logic;
  signal r_TX_DV         : std_logic;
  signal r_TX_Byte       : std_logic_vector(7 downto 0);

  signal r_RX_Bit_Count : unsigned(2 downto 0);
  signal r_TX_Bit_Count : unsigned(2 downto 0);

begin
	
  w_CPOL <= '1' when (SPI_MODE = 2) or (SPI_MODE = 3) else '0';
  w_CPHA <= '1' when (SPI_MODE = 1) or (SPI_MODE = 3) else '0';

  -- Purpose: Generate SPI Clock correct number of times when DV pulse comes
  Edge_Indicator : process (i_Clk, i_Rst_L)
  begin
    if i_Rst_L = '0' then
      o_TX_Ready      <= '0';
      r_SPI_Clk_Edges <= 0;
      r_Leading_Edge  <= '0';
      r_Trailing_Edge <= '0';
      r_SPI_Clk       <= w_CPOL;
      r_SPI_Clk_Count <= 0;
    elsif rising_edge(i_Clk) then

      -- Default assignments
      r_Leading_Edge  <= '0';
      r_Trailing_Edge <= '0';
      
      if i_TX_DV = '1' then
        o_TX_Ready      <= '0';
        r_SPI_Clk_Edges <= 16;
      elsif r_SPI_Clk_Edges > 0 then
        o_TX_Ready <= '0';
        -- fallende flanke erzeugen
        if r_SPI_Clk_Count = CLKS_PER_HALF_BIT*2-1 then
          r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1;
          r_Trailing_Edge <= '1';
          r_SPI_Clk_Count <= 0;
          r_SPI_Clk       <= not r_SPI_Clk;
		  -- steigende flanke erzeugen
        elsif r_SPI_Clk_Count = CLKS_PER_HALF_BIT-1 then
          r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1;
          r_Leading_Edge  <= '1';
          r_SPI_Clk_Count <= r_SPI_Clk_Count + 1;
          r_SPI_Clk       <= not r_SPI_Clk;
        else
		-- weiterzaelen
          r_SPI_Clk_Count <= r_SPI_Clk_Count + 1;
        end if;
      else
	  -- wieder freigeben
        o_TX_Ready <= '1';
      end if;
    end if;
  end process Edge_Indicator;

         
  -- Purpose: Register i_TX_Byte when Data Valid is pulsed.
  -- Keeps local storage of byte in case higher level module changes the data
  Byte_Reg : process (i_Clk, i_Rst_L)
  begin
    if i_Rst_L = '0' then
      r_TX_Byte <= X"00";
      r_TX_DV   <= '0';
    elsif rising_edge(i_clk) then
      r_TX_DV <= i_TX_DV;
      if i_TX_DV = '1' then
        r_TX_Byte <= i_TX_Byte;
      end if;
    end if;
  end process Byte_Reg;


  -- Purpose: Generate MOSI data
  MOSI_Data : process (i_Clk, i_Rst_L)
  begin
    if i_Rst_L = '0' then
      o_SPI_MOSI     <= '0';
      r_TX_Bit_Count <= "111";
    elsif rising_edge(i_Clk) then
      -- If ready is high, reset bit counts to default
      if o_TX_Ready = '1' then
        r_TX_Bit_Count <= "111";

      -- Catch the case where we start transaction and CPHA = 0
      elsif (r_TX_DV = '1' and w_CPHA = '0') then
        o_SPI_MOSI     <= r_TX_Byte(7);
        r_TX_Bit_Count <= "110";
      elsif (r_Leading_Edge = '1' and w_CPHA = '1') or (r_Trailing_Edge = '1' and w_CPHA = '0') then
        r_TX_Bit_Count <= r_TX_Bit_Count - 1;
        o_SPI_MOSI     <= r_TX_Byte(to_integer(r_TX_Bit_Count));
      end if;
    end if;
  end process MOSI_Data;


  -- Purpose: Read in MISO data.
  MISO_Data : process (i_Clk, i_Rst_L)
  begin
    if i_Rst_L = '0' then
      o_RX_Byte      <= X"00";
      o_RX_DV        <= '0';
      r_RX_Bit_Count <= "111";
    elsif rising_edge(i_Clk) then
      -- Default Assignments
      o_RX_DV <= '0';

      if o_TX_Ready = '1' then
        r_RX_Bit_Count <= "111";
      elsif (r_Leading_Edge = '1' and w_CPHA = '0') or (r_Trailing_Edge = '1' and w_CPHA = '1') then
        o_RX_Byte(to_integer(r_RX_Bit_Count)) <= i_SPI_MISO;
        r_RX_Bit_Count <= r_RX_Bit_Count - 1;
        if r_RX_Bit_Count = "000" then
          o_RX_DV <= '1';
        end if;
      end if;
    end if;
  end process MISO_Data;
  
  
  -- Purpose: Add clock delay to signals for alignment.
  SPI_Clock : process (i_Clk, i_Rst_L)
  begin
    if i_Rst_L = '0' then
      o_SPI_Clk  <= w_CPOL;
    elsif rising_edge(i_Clk) then
      o_SPI_Clk <= r_SPI_Clk;
    end if;
  end process SPI_Clock;
  
end architecture RTL;
