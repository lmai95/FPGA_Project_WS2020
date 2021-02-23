LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY SPI_Master IS
  GENERIC
  (
    SPI_MODE          : INTEGER := 0;
    CLKS_PER_HALF_BIT : INTEGER := 2
  );
  PORT (
    -- Control/Data Signals,
    i_Rst_L : IN STD_LOGIC;
    i_Clk   : IN STD_LOGIC;

    -- TX (MOSI) Signals
    i_TX_Byte  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    i_TX_DV    : IN STD_LOGIC;
    o_TX_Ready : BUFFER STD_LOGIC;

    -- RX (MISO) Signals		
    o_RX_DV   : OUT STD_LOGIC;
    o_RX_Byte : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- SPI Interface
    o_SPI_Clk  : OUT STD_LOGIC;
    i_SPI_MISO : IN STD_LOGIC;
    o_SPI_MOSI : OUT STD_LOGIC
  );
END ENTITY SPI_Master;

ARCHITECTURE RTL OF SPI_Master IS

  SIGNAL w_CPOL : STD_LOGIC;
  SIGNAL w_CPHA : STD_LOGIC;

  SIGNAL r_SPI_Clk_Count : INTEGER RANGE 0 TO CLKS_PER_HALF_BIT * 2 - 1;
  SIGNAL r_SPI_Clk       : STD_LOGIC;
  SIGNAL r_SPI_Clk_Edges : INTEGER RANGE 0 TO 16;
  SIGNAL r_Leading_Edge  : STD_LOGIC;
  SIGNAL r_Trailing_Edge : STD_LOGIC;
  SIGNAL r_TX_DV         : STD_LOGIC;
  SIGNAL r_TX_Byte       : STD_LOGIC_VECTOR(7 DOWNTO 0);

  SIGNAL r_RX_Bit_Count : unsigned(2 DOWNTO 0);
  SIGNAL r_TX_Bit_Count : unsigned(2 DOWNTO 0);

BEGIN

  w_CPOL <= '1' WHEN (SPI_MODE = 2) OR (SPI_MODE = 3) ELSE
    '0';
  w_CPHA <= '1' WHEN (SPI_MODE = 1) OR (SPI_MODE = 3) ELSE
    '0';

  -- Purpose: Generate SPI Clock correct number of times when DV pulse comes
  Edge_Indicator : PROCESS (i_Clk, i_Rst_L)
  BEGIN
    IF i_Rst_L = '0' THEN
      o_TX_Ready      <= '0';
      r_SPI_Clk_Edges <= 0;
      r_Leading_Edge  <= '0';
      r_Trailing_Edge <= '0';
      r_SPI_Clk       <= w_CPOL;
      r_SPI_Clk_Count <= 0;
    ELSIF rising_edge(i_Clk) THEN

      -- Default assignments
      r_Leading_Edge  <= '0';
      r_Trailing_Edge <= '0';

      IF i_TX_DV = '1' THEN
        o_TX_Ready      <= '0';
        r_SPI_Clk_Edges <= 16;
      ELSIF r_SPI_Clk_Edges > 0 THEN
        o_TX_Ready <= '0';
        -- fallende flanke erzeugen
        IF r_SPI_Clk_Count = CLKS_PER_HALF_BIT * 2 - 1 THEN
          r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1;
          r_Trailing_Edge <= '1';
          r_SPI_Clk_Count <= 0;
          r_SPI_Clk       <= NOT r_SPI_Clk;
          -- steigende flanke erzeugen
        ELSIF r_SPI_Clk_Count = CLKS_PER_HALF_BIT - 1 THEN
          r_SPI_Clk_Edges <= r_SPI_Clk_Edges - 1;
          r_Leading_Edge  <= '1';
          r_SPI_Clk_Count <= r_SPI_Clk_Count + 1;
          r_SPI_Clk       <= NOT r_SPI_Clk;
        ELSE
          -- weiterzaelen
          r_SPI_Clk_Count <= r_SPI_Clk_Count + 1;
        END IF;
      ELSE
        -- wieder freigeben
        o_TX_Ready <= '1';
      END IF;
    END IF;
  END PROCESS Edge_Indicator;
  -- Purpose: Register i_TX_Byte when Data Valid is pulsed.
  -- Keeps local storage of byte in case higher level module changes the data
  Byte_Reg : PROCESS (i_Clk, i_Rst_L)
  BEGIN
    IF i_Rst_L = '0' THEN
      r_TX_Byte <= X"00";
      r_TX_DV   <= '0';
    ELSIF rising_edge(i_clk) THEN
      r_TX_DV <= i_TX_DV;
      IF i_TX_DV = '1' THEN
        r_TX_Byte <= i_TX_Byte;
      END IF;
    END IF;
  END PROCESS Byte_Reg;
  -- Purpose: Generate MOSI data
  MOSI_Data : PROCESS (i_Clk, i_Rst_L)
  BEGIN
    IF i_Rst_L = '0' THEN
      o_SPI_MOSI     <= '0';
      r_TX_Bit_Count <= "111";
    ELSIF rising_edge(i_Clk) THEN
      -- If ready is high, reset bit counts to default
      IF o_TX_Ready = '1' THEN
        r_TX_Bit_Count <= "111";

        -- Catch the case where we start transaction and CPHA = 0
      ELSIF (r_TX_DV = '1' AND w_CPHA = '0') THEN
        o_SPI_MOSI     <= r_TX_Byte(7);
        r_TX_Bit_Count <= "110";
      ELSIF (r_Leading_Edge = '1' AND w_CPHA = '1') OR (r_Trailing_Edge = '1' AND w_CPHA = '0') THEN
        r_TX_Bit_Count <= r_TX_Bit_Count - 1;
        o_SPI_MOSI     <= r_TX_Byte(to_integer(r_TX_Bit_Count));
      END IF;
    END IF;
  END PROCESS MOSI_Data;
  -- Purpose: Read in MISO data.
  MISO_Data : PROCESS (i_Clk, i_Rst_L)
  BEGIN
    IF i_Rst_L = '0' THEN
      o_RX_Byte      <= X"00";
      o_RX_DV        <= '0';
      r_RX_Bit_Count <= "111";
    ELSIF rising_edge(i_Clk) THEN
      -- Default Assignments
      o_RX_DV <= '0';

      IF o_TX_Ready = '1' THEN
        r_RX_Bit_Count <= "111";
      ELSIF (r_Leading_Edge = '1' AND w_CPHA = '0') OR (r_Trailing_Edge = '1' AND w_CPHA = '1') THEN
        o_RX_Byte(to_integer(r_RX_Bit_Count)) <= i_SPI_MISO;
        r_RX_Bit_Count                        <= r_RX_Bit_Count - 1;
        IF r_RX_Bit_Count = "000" THEN
          o_RX_DV <= '1';
        END IF;
      END IF;
    END IF;
  END PROCESS MISO_Data;
  -- Purpose: Add clock delay to signals for alignment.
  SPI_Clock : PROCESS (i_Clk, i_Rst_L)
  BEGIN
    IF i_Rst_L = '0' THEN
      o_SPI_Clk <= w_CPOL;
    ELSIF rising_edge(i_Clk) THEN
      o_SPI_Clk <= r_SPI_Clk;
    END IF;
  END PROCESS SPI_Clock;

END ARCHITECTURE RTL;
