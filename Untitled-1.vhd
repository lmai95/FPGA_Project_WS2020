IF Y <= Z_draw_hight + 13 AND X <= h_draw(h_draw'HIGH) + 9 THEN --alphanumeric output
          rgb <= x"000";
          FOR i IN 0 TO h_draw'HIGH LOOP
            IF (X >= h_draw(i) AND X <= h_draw(i) + 9) AND (Y >= X_draw_hight AND Y <= X_draw_hight + 13) THEN
              IF (x_string(i)(Y - X_draw_hight)(X - h_draw(i)) = '1') THEN
                rgb <= x"F00";
              ELSE
                rgb <= x"000";
              END IF;
            ELSIF (X >= h_draw(i) AND X <= h_draw(i) + 9) AND (Y >= Y_draw_hight AND Y <= Y_draw_hight + 13) THEN
              IF (y_string(i)(Y - Y_draw_hight)(X - h_draw(i)) = '1') THEN
                rgb <= x"0F0";
              ELSE
                rgb <= x"000";
              END IF;
            ELSIF (X >= h_draw(i) AND X <= h_draw(i) + 9) AND (Y >= Z_draw_hight AND Y <= Z_draw_hight + 13) THEN
              IF (z_string(i)(Y - Z_draw_hight)(X - h_draw(i)) = '1') THEN
                rgb <= x"00F";
              ELSE
                rgb <= x"000";
              END IF;
            END IF;
          END LOOP;

        ELSIF ((X > 30 AND X < 32) AND (Y > 150 AND Y < 450)) OR --graph
          ((X > 30 AND X < 570) AND (Y = 450))
          THEN
          rgb <= x"FFF";

        ELSIF ((X > 30 AND X < 570) AND (Y = 250))
          THEN
          rgb <= x"0F0";
        ELSIF ((X > 30 AND X < 570) AND (Y = 300))
          THEN
          rgb <= x"00F";
        ELSIF ((X > 30 AND X < 570) AND (Y = 430))
          THEN
          rgb <= x"F00";
        ELSE
          rgb <= x"000";
        END IF;
      ELSE
        rgb <= x"000";
      END IF;
    END IF;


    FUNCTION print_bitmap(X : INTEGER, x_pos : INTEGER, Y : INTEGER, y_pos : INTEGER, bmp : bitmap, rgb : STD_LOGIC_VECTOR(11 DOWNTO 0)) RETURN STD_LOGIC_VECTOR(11 DOWNTO 0) IS
BEGIN
  IF X >= x_pos AND Y >= Y_pos AND X < (x_pos + bmp'HIGH(1)) AND Y < (y_pos + bmp'HIGH(0)) THEN --check if in rage of the bitmap position 
    IF (bmp(x - x_pos, y - y_pos) = 1) THEN
      RETURN rgb;
    END IF;
  ELSE
    RETURN x"000";
  END IF;
END print_bitmap;