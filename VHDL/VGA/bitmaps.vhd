LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE bitmaps IS
    TYPE rotation IS (zero, ninety, one_eighty, two_seventy);
    TYPE bitmap_zeichen IS ARRAY(0 TO 13) OF STD_LOGIC_VECTOR(0 TO 9);
    TYPE zeichenvorat_array IS ARRAY(0 TO 22) OF bitmap_zeichen;
    TYPE zeichen IS (zero, one, two, three, four, five, six, seven, eight, nine, a, t, x, y, z, dpl_pkt, pkt, minus, m, slash, s_2, empty, arrow);
    -- VGA Timing Werte aus TinyVGA.com
    CONSTANT HD  : INTEGER := 639; -- Visible Area
    CONSTANT HFP : INTEGER := 16;  -- Front Porch
    CONSTANT HSP : INTEGER := 96;  -- Sync Pulse
    CONSTANT HBP : INTEGER := 48;  -- Back Porch

    CONSTANT VD  : INTEGER := 479; -- Visible Area 
    CONSTANT VFP : INTEGER := 10;  -- Front Porch
    CONSTANT VSP : INTEGER := 2;   -- Sync Pulse
    CONSTANT VBP : INTEGER := 33;  -- Back Porch

    FUNCTION print_bitmap(
        X        : IN INTEGER;                       --current pixel position x-direction
        x_pos    : IN INTEGER;                       --target pixel position x-direction
        Y        : IN INTEGER;                       --current pixel position y-direction
        y_pos    : IN INTEGER;                       --target pixel position y-direction
        rot      : IN rotation;                      --rotaion of the bitmap
        i_bmp    : IN zeichen;                       --bitmap to be printed
        rgb      : IN STD_LOGIC_VECTOR(11 DOWNTO 0); --the current value of the variabel written to to check if the is already something displayed
        col      : IN STD_LOGIC_VECTOR(11 DOWNTO 0); --the color of the bit map printed 
        back_col : IN STD_LOGIC_VECTOR(11 DOWNTO 0)) --the color of the backround where the Bitmap is '0'
        RETURN STD_LOGIC_VECTOR;

    FUNCTION print_any_line (
        X       : IN INTEGER;                       --current pixel position x-direction
        x_start : IN INTEGER;                       --target start pixel position x-direction
        x_stop  : IN INTEGER;                       --target stop pixel position x-direction
        Y       : IN INTEGER;                       --current pixel position y-direction
        y_start : IN INTEGER;                       --target  start pixel position y-direction
        y_stop  : IN INTEGER;                       --target  stop pixel position y-direction
        rgb     : IN STD_LOGIC_VECTOR(11 DOWNTO 0); --the current value of the variabel written to to check if the is already something displayed
        col     : IN STD_LOGIC_VECTOR(11 DOWNTO 0)) --the color of the bit map printed 
        RETURN STD_LOGIC_VECTOR;

    CONSTANT bitmap_t : bitmap_zeichen := (
        "0000000000",
        "0000000000",
        "0000000000",
        "0001000000",
        "0001000000",
        "0011100000",
        "0001000000",
        "0001000000",
        "0001000000",
        "0001000000",
        "0001000000",
        "0001110000",
        "0000000000",
        "0000000000");
    CONSTANT bitmap_a : bitmap_zeichen := (
        "0000000000",
        "0000001000",
        "0000001100",
        "0011111110",
        "0000001100",
        "0000001000",
        "0000000000",
        "0000111010",
        "0001000110",
        "0010000010",
        "0010000010",
        "0010000010",
        "0001000110",
        "0000111010");
    CONSTANT bitmap_arrow : bitmap_zeichen := (
        "0000110000",
        "0000110000",
        "0001111000",
        "0001111000",
        "0011111100",
        "0011111100",
        "0111111110",
        "0111111110",
        "1111111111",
        "1111111111",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000");
    CONSTANT bitmap_0 : bitmap_zeichen := (
        "0111111100",
        "1111111110",
        "1100000110",
        "1100000110",
        "1100000110",
        "1100010110",
        "1100110110",
        "1101100110",
        "1101000110",
        "1100000110",
        "1100000110",
        "1100000110",
        "1111111110",
        "0111111100");

    CONSTANT bitmap_1 : bitmap_zeichen := (
        "0111000000",
        "1111000000",
        "0011000000",
        "0011000000",
        "0011000000",
        "0011000000",
        "0011000000",
        "0011000000",
        "0011000000",
        "0011000000",
        "0011000000",
        "0011000000",
        "1111110000",
        "1111110000");

    CONSTANT bitmap_2 : bitmap_zeichen := (
        "0111111100",
        "1111111110",
        "1100000110",
        "0000000110",
        "0000000110",
        "0000001110",
        "0000011100",
        "0000111000",
        "0001110000",
        "0011100000",
        "0111000000",
        "1110000000",
        "1111111110",
        "1111111110");

    CONSTANT bitmap_3 : bitmap_zeichen := (
        "1111111110",
        "1111111110",
        "0000001110",
        "0000011100",
        "0000111000",
        "0001110000",
        "0011111100",
        "0011111110",
        "0000000110",
        "0000000110",
        "0000000110",
        "1100000110",
        "1111111110",
        "0111111100");

    CONSTANT bitmap_4 : bitmap_zeichen := (
        "0000011100",
        "0000111100",
        "0001101100",
        "0001101100",
        "0011001100",
        "0011001100",
        "0110001100",
        "0110001100",
        "1100001100",
        "1111111111",
        "1111111111",
        "0000001100",
        "0000001100",
        "0000001100");

    CONSTANT bitmap_5 : bitmap_zeichen := (
        "1111111110",
        "1111111110",
        "1100000000",
        "1100000000",
        "1100000000",
        "1100000000",
        "1111111100",
        "0111111110",
        "0000000110",
        "0000000110",
        "0000000110",
        "1100000110",
        "1111111110",
        "0111111100");

    CONSTANT bitmap_6 : bitmap_zeichen := (
        "0111111100",
        "1111111110",
        "1100000110",
        "1100000000",
        "1100000000",
        "1100000000",
        "1111111100",
        "1111111110",
        "1100000110",
        "1100000110",
        "1100000110",
        "1100000110",
        "1111111110",
        "0111111100");

    CONSTANT bitmap_7 : bitmap_zeichen := (
        "1111111110",
        "1111111110",
        "0000000110",
        "0000001100",
        "0000001100",
        "0000011000",
        "0000011000",
        "0000110000",
        "0000110000",
        "0001100000",
        "0001100000",
        "0011000000",
        "0011000000",
        "0011000000");

    CONSTANT bitmap_8 : bitmap_zeichen := (
        "0111111100",
        "1111111110",
        "1100000110",
        "1100000110",
        "1100000110",
        "1100000110",
        "0111111100",
        "0111111100",
        "1100000110",
        "1100000110",
        "1100000110",
        "1100000110",
        "1111111110",
        "0111111100");

    CONSTANT bitmap_9 : bitmap_zeichen := (
        "0111111100",
        "1111111110",
        "1100000110",
        "1100000110",
        "1100000110",
        "1100000110",
        "0111111110",
        "0111111110",
        "0000000110",
        "0000000110",
        "0000000110",
        "1100000110",
        "1111111110",
        "0111111100");

    CONSTANT bitmap_x : bitmap_zeichen := (
        "1100000110",
        "1100000110",
        "0110001100",
        "0110001100",
        "0011011000",
        "0011011000",
        "0001110000",
        "0001110000",
        "0011011000",
        "0011011000",
        "0110001100",
        "0110001100",
        "1100000110",
        "1100000110");

    CONSTANT bitmap_y : bitmap_zeichen := (
        "1000000001",
        "1100000011",
        "1100000011",
        "0110000110",
        "0110000110",
        "0011001100",
        "0011001100",
        "0001111000",
        "0001111000",
        "0000110000",
        "0000110000",
        "0000110000",
        "0000110000",
        "0000110000");

    CONSTANT bitmap_z : bitmap_zeichen := (
        "1111111110",
        "1111111110",
        "0000001110",
        "0000011100",
        "0000011000",
        "0000110000",
        "0000110000",
        "0001100000",
        "0001100000",
        "0011000000",
        "0111000000",
        "1110000000",
        "1111111110",
        "1111111110");

    CONSTANT bitmap_dpl_pkt : bitmap_zeichen := (
        "0000000000",
        "0000000000",
        "0000000000",
        "0000110000",
        "0000110000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000110000",
        "0000110000",
        "0000000000",
        "0000000000",
        "0000000000");

    CONSTANT bitmap_pkt : bitmap_zeichen := (
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000110000",
        "0000110000");

    CONSTANT bitmap_minus : bitmap_zeichen := (
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0001111000",
        "0001111000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000");

    CONSTANT bitmap_m : bitmap_zeichen := (
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0011001100",
        "1111111111",
        "1100110011",
        "1100110011",
        "1100110011",
        "1100110011",
        "1100110011",
        "1100110011",
        "1100110011");
    CONSTANT bitmap_slash : bitmap_zeichen := (
        "0000100000",
        "0000100000",
        "0001000000",
        "0001000000",
        "0001000000",
        "0010000000",
        "0010000000",
        "0010000000",
        "0100000000",
        "0100000000",
        "0100000000",
        "1000000000",
        "1000000000",
        "1000000000");
    CONSTANT bitmap_s2 : bitmap_zeichen := (
        "0000001110",
        "0000010001",
        "0000000010",
        "0000000100",
        "0000011111",
        "0000000000",
        "0111111100",
        "1111111100",
        "1100000000",
        "1111111000",
        "0111111100",
        "0000001100",
        "1111111100",
        "1111111000");

    CONSTANT bitmap_empty : bitmap_zeichen := (
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000",
        "0000000000");

    CONSTANT zeichenvorat : zeichenvorat_array := (
        bitmap_0,
        bitmap_1,
        bitmap_2,
        bitmap_3,
        bitmap_4,
        bitmap_5,
        bitmap_6,
        bitmap_7,
        bitmap_8,
        bitmap_9,
        bitmap_a,
        bitmap_t,
        bitmap_x,
        bitmap_y,
        bitmap_z,
        bitmap_dpl_pkt,
        bitmap_pkt,
        bitmap_minus,
        bitmap_m,
        bitmap_slash,
        bitmap_s2,
        bitmap_empty,
        bitmap_arrow
    );
END PACKAGE bitmaps;

PACKAGE BODY bitmaps IS
    FUNCTION print_bitmap(
        X        : INTEGER;                       --current pixel position x-direction
        x_pos    : INTEGER;                       --target pixel position x-direction
        Y        : INTEGER;                       --current pixel position y-direction
        y_pos    : INTEGER;                       --target pixel position y-direction
        rot      : rotation;                      --rotaion of the bitmap
        i_bmp    : zeichen;                       --index of the bitmap that is going to be printed
        rgb      : STD_LOGIC_VECTOR(11 DOWNTO 0); --the current value of the variabel written to to check if the is already something displayed
        col      : STD_LOGIC_VECTOR(11 DOWNTO 0); --the color of the bit map printed 
        back_col : STD_LOGIC_VECTOR(11 DOWNTO 0)) --the color of the backround where the Bitmap is '0'
        RETURN STD_LOGIC_VECTOR IS
    BEGIN
        IF rgb = x"000" THEN

            CASE rot IS
                WHEN zero =>
                    IF (X >= x_pos AND Y >= Y_pos AND X < (x_pos + 10) AND Y < (y_pos + 14)) THEN --check if in rage of the bitmap position 
                        IF (zeichenvorat(zeichen'pos(i_bmp))(y - y_pos)(x - x_pos) = '1') THEN        --check if bitmap reads 0 or 1 , 
                            RETURN col;
                        ELSE
                            RETURN back_col;
                        END IF;
                    ELSE
                        RETURN x"000";
                    END IF;
                WHEN ninety =>
                    IF (X >= x_pos AND Y >= Y_pos AND X < (x_pos + 14) AND Y < (y_pos + 10)) THEN       --check if in rage of the bitmap position 
                        IF (zeichenvorat(zeichen'pos(i_bmp))(12 - (x - x_pos))(9 - (y - y_pos)) = '1') THEN --check if bitmap reads 0 or 1 , 
                            RETURN col;
                        ELSE
                            RETURN back_col;
                        END IF;
                    ELSE
                        RETURN x"000";
                    END IF;
                WHEN one_eighty =>
                    IF (X >= x_pos AND Y >= Y_pos AND X < (x_pos + 10) AND Y < (y_pos + 14)) THEN       --check if in rage of the bitmap position 
                        IF (zeichenvorat(zeichen'pos(i_bmp))(12 - (y - y_pos))(9 - (x - x_pos)) = '1') THEN --check if bitmap reads 0 or 1 , 
                            RETURN col;
                        ELSE
                            RETURN back_col;
                        END IF;
                    ELSE
                        RETURN x"000";
                    END IF;
                WHEN two_seventy =>
                    IF (X >= x_pos AND Y >= Y_pos AND X < (x_pos + 14) AND Y < (y_pos + 10)) THEN --check if in rage of the bitmap position 
                        IF (zeichenvorat(zeichen'pos(i_bmp))(x - x_pos)(y - y_pos) = '1') THEN        --check if bitmap reads 0 or 1 , 
                            RETURN col;
                        ELSE
                            RETURN back_col;
                        END IF;
                    ELSE
                        RETURN x"000";
                    END IF;
            END CASE;
        ELSE
            RETURN rgb;
        END IF;
    END print_bitmap;

    FUNCTION print_any_line (
        X       : INTEGER;                       --current pixel position x-direction
        x_start : INTEGER;                       --target start pixel position x-direction
        x_stop  : INTEGER;                       --target stop pixel position x-direction
        Y       : INTEGER;                       --current pixel position y-direction
        y_start : INTEGER;                       --target  start pixel position y-direction
        y_stop  : INTEGER;                       --target  stop pixel position y-direction
        rgb     : STD_LOGIC_VECTOR(11 DOWNTO 0); --the current value of the variabel written to to check if the is already something displayed
        col     : STD_LOGIC_VECTOR(11 DOWNTO 0)) --the color of the bit map printed 
        RETURN STD_LOGIC_VECTOR IS

        VARIABLE fp_dx : INTEGER;
        VARIABLE fp_dy : INTEGER;
        VARIABLE fp_x  : INTEGER;
        VARIABLE fp_y  : INTEGER;
        VARIABLE fp_f  : INTEGER;
    BEGIN
        IF (X >= x_start) AND (X <= X_stop) AND (Y >= y_start) AND (y <= y_stop) THEN --check if in area where the line is drawn
            IF (X >= x_start) AND (X <= X_stop) AND (Y >= y_start) AND (y <= y_stop) THEN --check if in area where the line is drawn
                IF (x_stop = x_start) THEN
                    IF (X = x_stop AND Y <= y_stop AND y >= y_start) THEN
                        RETURN col;
                    ELSE
                        RETURN rgb;
                    END IF;
                ELSIF (y_stop = y_start) THEN
                    IF (y = y_stop AND x <= x_stop AND x >= x_start) THEN
                        RETURN col;
                    ELSE
                        RETURN rgb;
                    END IF;
                ELSE
                    -- Bresenham-Algorithmus 
                    fp_x  := x_start * 2;                  --bitshift Integervalue to allow for fractions
                    fp_y  := y_start * 2;                  --bitshift Integervalue to allow for fractions
                    fp_dx := (x_stop * 2) - (x_start * 2); --bitshift Integervalue to allow for fractions
                    fp_dy := (y_stop * 2) - (y_start * 2); --bitshift Integervalue to allow for fractions
                    IF fp_dx > fp_dy THEN                  --check if x is the fast direction
                        fp_f := fp_dx / 2;                     --shift back 1 bit (is equal to halving)
                        FOR I IN x_start TO x_stop LOOP
                            fp_x := fp_x + 1 * 2; --Increment fast direction
                            fp_f := fp_f - fp_dy; --recalculate the error value with the slow direction
                            IF fp_f < 0 THEN      --if error smaler than 0 
                                fp_y := fp_y + 1;     --Increment slow direction
                                fp_f := fp_f + fp_dx; --recalculate the error value with the fast direction
                            END IF;
                            IF (fp_y / 2) = y AND (fp_x / 2) = x THEN --check if callculated pixel is current pixel 
                                RETURN col;                               --return the RGB value
                            END IF;
                        END LOOP;
                        RETURN rgb;
                    ELSE
                        fp_f := fp_dy / 2; --shift back 1 bit (is equal to halving)
                        FOR I IN y_start TO y_stop LOOP
                            fp_y := fp_y + 1 * 2; --Increment fast direction
                            fp_f := fp_f - fp_dx; --recalculate the error value with the slow direction
                            IF fp_f < 0 THEN      --if error smaler than 0 
                                fp_x := fp_x + 1;     --Increment slow direction
                                fp_f := fp_f + fp_dy; --recalculate the error value with the fast direction
                            END IF;
                            IF (fp_y / 2) = y AND (fp_x / 2) = x THEN --check if callculated pixel is current pixel 
                                RETURN col;                               --return the RGB value
                            END IF;
                        END LOOP;
                    END IF;
                    RETURN rgb;
                END IF;
            END IF;
        END IF;
        RETURN rgb;
    END print_any_line;
END PACKAGE BODY bitmaps;
