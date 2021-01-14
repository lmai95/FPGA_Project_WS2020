LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE bitmaps IS
    -- VGA Timing Werte aus TinyVGA.com
    CONSTANT HD : INTEGER := 639; -- Visible Area
    CONSTANT HFP : INTEGER := 16; -- Front Porch
    CONSTANT HSP : INTEGER := 96; -- Sync Pulse
    CONSTANT HBP : INTEGER := 48; -- Back Porch

    CONSTANT VD : INTEGER := 479; -- Visible Area 
    CONSTANT VFP : INTEGER := 10; -- Front Porch
    CONSTANT VSP : INTEGER := 2; -- Sync Pulse
    CONSTANT VBP : INTEGER := 33; -- Back Porch

    type rotation is
        (zero, ninety, one_eighty, two_seventy);

    TYPE bitmap_zeichen IS ARRAY(0 TO 13) OF STD_LOGIC_VECTOR(0 TO 9);
    
    CONSTANT arrow : bitmap_zeichen := (
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
        "0000000000"
    );

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
        "0000000000"
    );

END PACKAGE bitmaps;