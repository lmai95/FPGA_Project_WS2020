LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.bitmaps.ALL;

ENTITY VGA_WerteDarstellung IS
  PORT
  (
    clk       : IN STD_LOGIC;
    rst       : IN STD_LOGIC;
    screen_on : IN STD_LOGIC;
    X         : IN INTEGER;
    Y         : IN INTEGER;
    rgb       : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
  );
END ENTITY VGA_WerteDarstellung;
ARCHITECTURE behave OF VGA_WerteDarstellung IS
  FUNCTION print_bitmap(
    X        : INTEGER;                       --current pixel position x-direction
    x_pos    : INTEGER;                       --target pixel position x-direction
    Y        : INTEGER;                       --current pixel position y-direction
    y_pos    : INTEGER;                       --target pixel position y-direction
    rot      : rotation;                      --rotaion of the bitmap
    bmp      : bitmap_zeichen;                --bitmap to be printed
    rgb      : STD_LOGIC_VECTOR(11 DOWNTO 0); --the current value of the variabel written to to check if the is already something displayed
    col      : STD_LOGIC_VECTOR(11 DOWNTO 0); --the color of the bit map printed 
    back_col : STD_LOGIC_VECTOR(11 DOWNTO 0)) --the color of the backround where the Bitmap is '0'

    RETURN STD_LOGIC_VECTOR IS
  BEGIN
    IF rgb = x"000" THEN
      CASE rot IS
        WHEN zero =>
          IF (X >= x_pos AND Y >= Y_pos AND X < (x_pos + 10) AND Y < (y_pos + 14)) THEN --check if in rage of the bitmap position 
            IF (bmp(y - y_pos)(x - x_pos) = '1') THEN --check if bitmap reads 0 or 1 , 
              RETURN col;
            ELSE
              RETURN back_col;
            END IF;
          ELSE
            RETURN x"000";
          END IF;
        WHEN ninety =>
          IF (X >= x_pos AND Y >= Y_pos AND X < (x_pos + 14) AND Y < (y_pos + 10)) THEN --check if in rage of the bitmap position 
            IF (bmp(12 - (x - x_pos))(9 - (y - y_pos)) = '1') THEN --check if bitmap reads 0 or 1 , 
              RETURN col;
            ELSE
              RETURN back_col;
            END IF;
          ELSE
            RETURN x"000";
          END IF;
        WHEN one_eighty =>
          IF (X >= x_pos AND Y >= Y_pos AND X < (x_pos + 10) AND Y < (y_pos + 14)) THEN --check if in rage of the bitmap position 
            IF (bmp(12 - (y - y_pos))(9 - (x - x_pos)) = '1') THEN --check if bitmap reads 0 or 1 , 
              RETURN col;
            ELSE
              RETURN back_col;
            END IF;
          ELSE
            RETURN x"000";
          END IF;
        WHEN two_seventy =>
          IF (X >= x_pos AND Y >= Y_pos AND X < (x_pos + 14) AND Y < (y_pos + 10)) THEN --check if in rage of the bitmap position 
            IF (bmp(x - x_pos)(y - y_pos) = '1') THEN --check if bitmap reads 0 or 1 , 
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
    col     : STD_LOGIC_VECTOR(11 DOWNTO 0))	--the color of the bit map printed 
	 RETURN STD_LOGIC_VECTOR IS
	  
    VARIABLE fp_dx : INTEGER;
    VARIABLE fp_dy : INTEGER;
    VARIABLE fp_x : INTEGER;
    VARIABLE fp_y : INTEGER;
    VARIABLE fp_f : INTEGER;
  BEGIN
    IF (X >= x_start) AND (X <= X_stop) AND (Y >= y_start) AND (y <= y_stop) THEN --check if in area where the line is drawn
      -- Bresenham-Algorithmus 
      fp_x := x_start sla 4; --bitshift Integervalue to allow for fractions
      fp_y := y_start sla 4; --bitshift Integervalue to allow for fractions
      fp_dx := (x_stop sla 4) - (x_start sla 4); --bitshift Integervalue to allow for fractions
      fp_dy := (y_stop sla 4) - (y_start sla 4); --bitshift Integervalue to allow for fractions
      IF dx > dy THEN --check if x is the fast direction
        fp_f := fp_dx sra 1; --shift back 1 bit (is equal to halving)
        FOR I IN x_start TO x_stop LOOP
          fp_x := fp_x + 1 sla 4; --Increment fast direction
          fp_f := fp_f - fp_dy; --recalculate the error value with the slow direction
          IF fp_f < 0 THEN --if error smaler than 0 
            fp_y := fp_y + 1; --Increment slow direction
            fp_f := fp_f + fp_dx; --recalculate the error value with the fast direction
          END IF;
          IF (fp_y sra 4) = y AND (fp_x sra 4) = x THEN --check if callculated pixel is current pixel 
            RETURN col; --return the RGB value
          END IF;
        END LOOP;
        RETURN x"000";
      ELSE
        fp_f := fp_dy sra 1; --shift back 1 bit (is equal to halving)
        FOR I IN y_start TO y_stop LOOP
          fp_y := fp_y + 1 sla 4; --Increment fast direction
          fp_f := fp_f - fp_dx; --recalculate the error value with the slow direction
          IF fp_f < 0 THEN --if error smaler than 0 
            fp_x := fp_x + 1; --Increment slow direction
            fp_f := fp_f + fp_dy; --recalculate the error value with the fast direction
          END IF;
          IF (fp_y sra 4) = y AND (fp_x sra 4) = x THEN --check if callculated pixel is current pixel 
            RETURN col; --return the RGB value
          END IF;
        END LOOP;
      END IF;
      RETURN x"000";
    ELSE
      RETURN x"000";
    END IF;
  END print_any_line;

  CONSTANT X_draw_hight : INTEGER := 30;
  CONSTANT Y_draw_hight : INTEGER := 60;
  CONSTANT Z_draw_hight : INTEGER := 90;
  TYPE bitmap_string IS ARRAY(0 TO 5) OF bitmap_zeichen;
  SIGNAL x_string : bitmap_string := (bitmap_x, bitmap_dpl_pkt, bitmap_empty, bitmap_4, bitmap_pkt, bitmap_8);
  SIGNAL y_string : bitmap_string := (bitmap_y, bitmap_dpl_pkt, bitmap_empty, bitmap_5, bitmap_pkt, bitmap_6);
  SIGNAL z_string : bitmap_string := (bitmap_z, bitmap_dpl_pkt, bitmap_empty, bitmap_8, bitmap_pkt, bitmap_9);

  SIGNAL drawable : BOOLEAN := false;
  SIGNAL border : BOOLEAN := false;
  SIGNAL y_axis : BOOLEAN := false;
  SIGNAL y_arrow : BOOLEAN := false;
  SIGNAL x_axis : BOOLEAN := false;
  SIGNAL x_arrow : BOOLEAN := false;

BEGIN
  Darstellung : PROCESS (clk, rst, X, Y, screen_on)
    VARIABLE RGB_sig : STD_LOGIC_VECTOR(11 DOWNTO 0);
  BEGIN
    IF rst = '0' THEN
      RGB_sig := x"000";
    ELSIF rising_edge(clk) THEN
      RGB_sig := x"000";
      IF drawable THEN
        IF border THEN
          RGB_sig := x"111";
        ELSIF y_axis OR x_axis THEN
          RGB_sig := x"FFF";
        ELSE
          RGB_sig := print_bitmap(X, 6, Y, 110, zero, arrow, RGB_sig, x"FFF", x"000");
          RGB_sig := print_bitmap(X, 624, Y, 455, ninety, arrow, RGB_sig, x"FFF", x"000");
        END IF;
      ELSE
        RGB_sig := x"000";
      END IF;
    END IF;
    rgb <= RGB_sig;
  END PROCESS;
  drawable <= (X < 639 AND Y < 479);

END ARCHITECTURE behave;
