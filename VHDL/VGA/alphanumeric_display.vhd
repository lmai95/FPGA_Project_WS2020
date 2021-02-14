LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.bitmaps.ALL;
ENTITY alphanumeric_display IS
    GENERIC
    (
        x_color : STD_LOGIC_VECTOR(11 DOWNTO 0) := x"F00";
        y_color : STD_LOGIC_VECTOR(11 DOWNTO 0) := x"0F0";
        z_color : STD_LOGIC_VECTOR(11 DOWNTO 0) := x"0FF"
    );
    PORT (
        CLK      : IN STD_LOGIC;
        rst      : IN STD_LOGIC;
        hpos     : IN INTEGER;
        vpos     : IN INTEGER;
        x_int    : IN INTEGER RANGE -32768 TO 32767;
        y_int    : IN INTEGER RANGE -32768 TO 32767;
        z_int    : IN INTEGER RANGE -32768 TO 32767;
        RGB_Wert : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    );
END alphanumeric_display;

ARCHITECTURE behave OF alphanumeric_display IS

    CONSTANT vpos_draw_x : INTEGER := 30;
    CONSTANT vpos_draw_y : INTEGER := 60;
    CONSTANT vpos_draw_z : INTEGER := 90;

    TYPE hpos_array IS ARRAY(0 TO 10) OF INTEGER;
    --													      d1  d2  pkt d3  d4
    CONSTANT h_draw : hpos_array := (30, 45, 55, 65, 78, 88, 99, 112, 125, 138, 145);

    TYPE bitmap_array IS ARRAY(0 TO hpos_array'high) OF zeichen;
    SIGNAL x_bitmaps : bitmap_array := (x, dpl_pkt, empty, four, four, pkt, y, five, m, slash, s_2);
    SIGNAL y_bitmaps : bitmap_array := (y, dpl_pkt, empty, four, four, pkt, y, five, m, slash, s_2);
    SIGNAL z_bitmaps : bitmap_array := (z, dpl_pkt, empty, four, four, pkt, y, five, m, slash, s_2);

    SIGNAL drawable : BOOLEAN := false;
    SIGNAL border   : BOOLEAN := false;
    SIGNAL y_axis   : BOOLEAN := false;
    SIGNAL y_arrow  : BOOLEAN := false;
    SIGNAL x_axis   : BOOLEAN := false;
    SIGNAL x_arrow  : BOOLEAN := false;
    SIGNAL x_bcd    : STD_LOGIC_VECTOR(0 TO 16);
    SIGNAL y_bcd    : STD_LOGIC_VECTOR(0 TO 16);
    SIGNAL z_bcd    : STD_LOGIC_VECTOR(0 TO 16);

    COMPONENT Integer2BCD IS
        PORT (
            x_in  : IN INTEGER RANGE -32768 TO 32767;
            x_out : OUT STD_LOGIC_VECTOR(0 TO 16);
            y_in  : IN INTEGER RANGE -32768 TO 32767;
            y_out : OUT STD_LOGIC_VECTOR(0 TO 16);
            z_in  : IN INTEGER RANGE -32768 TO 32767;
            z_out : OUT STD_LOGIC_VECTOR(0 TO 16)
        );
    END COMPONENT;
BEGIN
    drawable <= (hpos < 639 AND vpos < 479);
    bcd_converter : Integer2BCD
    PORT MAP(
        x_in  => x_int,
        x_out => x_bcd,
        y_in  => y_int,
        y_out => y_bcd,
        z_in  => z_int,
        z_out => z_bcd
    );

    X_bcd_to_bitmaps : PROCESS (clk, rst, x_BCD)
        VARIABLE nibble_low  : INTEGER RANGE -3 TO 13;
        VARIABLE nibble_high : INTEGER RANGE 0 TO 16;
    BEGIN

        IF rst = '0' THEN
        ELSIF rising_edge(clk) THEN
            IF x_BCD(0) = '1' THEN
                x_bitmaps(2) <= minus;
            ELSE
                x_bitmaps(2) <= empty;
            END IF;
            nibble_low  := - 3;
            nibble_high := 0;

            FOR i IN 3 TO 7 LOOP
                IF i = 3 OR i = 4 OR i = 6 OR i = 7 THEN
                    nibble_high := nibble_high + 4;
                    nibble_low  := nibble_low + 4;
                    CASE x_BCD(nibble_low TO nibble_high) IS
                        WHEN "0000" => x_bitmaps(i) <= zero;
                        WHEN "0001" => x_bitmaps(i) <= one;
                        WHEN "0010" => x_bitmaps(i) <= two;
                        WHEN "0011" => x_bitmaps(i) <= three;
                        WHEN "0100" => x_bitmaps(i) <= four;
                        WHEN "0101" => x_bitmaps(i) <= five;
                        WHEN "0110" => x_bitmaps(i) <= six;
                        WHEN "0111" => x_bitmaps(i) <= seven;
                        WHEN "1000" => x_bitmaps(i) <= eight;
                        WHEN "1001" => x_bitmaps(i) <= nine;
                        WHEN OTHERS => x_bitmaps(i) <= empty;
                    END CASE;

                END IF;
            END LOOP;
        END IF;
    END PROCESS;
    Y_bcd_to_bitmaps : PROCESS (clk, rst, y_BCD)
        VARIABLE nibble_low  : INTEGER RANGE -3 TO 13;
        VARIABLE nibble_high : INTEGER RANGE 0 TO 16;
    BEGIN
        IF rst = '0' THEN

        ELSIF rising_edge(clk) THEN
            IF y_BCD(0) = '1' THEN
                y_bitmaps(2) <= minus;
            ELSE
                y_bitmaps(2) <= empty;
            END IF;
            nibble_low  := - 3;
            nibble_high := 0;

            FOR i IN 3 TO 7 LOOP
                IF i = 3 OR i = 4 OR i = 6 OR i = 7 THEN
                    nibble_high := nibble_high + 4;
                    nibble_low  := nibble_low + 4;
                    CASE y_BCD(nibble_low TO nibble_high) IS
                        WHEN "0000" => y_bitmaps(i) <= zero;
                        WHEN "0001" => y_bitmaps(i) <= one;
                        WHEN "0010" => y_bitmaps(i) <= two;
                        WHEN "0011" => y_bitmaps(i) <= three;
                        WHEN "0100" => y_bitmaps(i) <= four;
                        WHEN "0101" => y_bitmaps(i) <= five;
                        WHEN "0110" => y_bitmaps(i) <= six;
                        WHEN "0111" => y_bitmaps(i) <= seven;
                        WHEN "1000" => y_bitmaps(i) <= eight;
                        WHEN "1001" => y_bitmaps(i) <= nine;
                        WHEN OTHERS => y_bitmaps(i) <= empty;
                    END CASE;

                END IF;
            END LOOP;
        END IF;
    END PROCESS;

    Z_bcd_to_bitmaps : PROCESS (clk, rst, z_BCD)
        VARIABLE nibble_low  : INTEGER RANGE -3 TO 13;
        VARIABLE nibble_high : INTEGER RANGE 0 TO 16;
    BEGIN
        IF rst = '0' THEN

        ELSIF rising_edge(clk) THEN
            IF z_BCD(0) = '1' THEN
                z_bitmaps(2) <= minus;
            ELSE
                z_bitmaps(2) <= empty;
            END IF;
            nibble_low  := - 3;
            nibble_high := 0;

            FOR i IN 3 TO 7 LOOP
                IF i = 3 OR i = 4 OR i = 6 OR i = 7 THEN
                    nibble_high := nibble_high + 4;
                    nibble_low  := nibble_low + 4;
                    CASE z_BCD(nibble_low TO nibble_high) IS
                        WHEN "0000" => z_bitmaps(i) <= zero;
                        WHEN "0001" => z_bitmaps(i) <= one;
                        WHEN "0010" => z_bitmaps(i) <= two;
                        WHEN "0011" => z_bitmaps(i) <= three;
                        WHEN "0100" => z_bitmaps(i) <= four;
                        WHEN "0101" => z_bitmaps(i) <= five;
                        WHEN "0110" => z_bitmaps(i) <= six;
                        WHEN "0111" => z_bitmaps(i) <= seven;
                        WHEN "1000" => z_bitmaps(i) <= eight;
                        WHEN "1001" => z_bitmaps(i) <= nine;
                        WHEN OTHERS => z_bitmaps(i) <= empty;
                    END CASE;

                END IF;
            END LOOP;
        END IF;
    END PROCESS;

    Darstellung : PROCESS (clk, rst, hpos, vpos)
        VARIABLE RGB_sig : STD_LOGIC_VECTOR(11 DOWNTO 0);
    BEGIN
        IF rst = '0' THEN
            RGB_sig := x"000";
        ELSIF rising_edge(clk) THEN
            RGB_sig := x"000";
            IF drawable THEN
                FOR I IN 0 TO hpos_array'high LOOP
                    RGB_sig := print_bitmap(hpos, 6 + h_draw(i), vpos, vpos_draw_x, zero, x_bitmaps(i), RGB_sig, x_color, x"000");
                    RGB_sig := print_bitmap(hpos, 6 + h_draw(i), vpos, vpos_draw_y, zero, y_bitmaps(i), RGB_sig, y_color, x"000");
                    RGB_sig := print_bitmap(hpos, 6 + h_draw(i), vpos, vpos_draw_z, zero, z_bitmaps(i), RGB_sig, z_color, x"000");
                END LOOP;
               
            ELSE
                RGB_sig := x"000";
            END IF;
        END IF;
        RGB_Wert <= RGB_sig;
    END PROCESS;
END behave;
