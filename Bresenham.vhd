FUNCTION print_any_line (
    X       : INTEGER;                       --current pixel position x-direction
    x_start : INTEGER;                       --target start pixel position x-direction
    x_stop  : INTEGER;                       --target stop pixel position x-direction
    Y       : INTEGER;                       --current pixel position y-direction
    y_start : INTEGER;                       --target  start pixel position y-direction
    y_stop  : INTEGER;                       --target  stop pixel position y-direction
    rgb     : STD_LOGIC_VECTOR(11 DOWNTO 0); --the current value of the variabel written to to check if the is already something displayed
    col     : STD_LOGIC_VECTOR(11 DOWNTO 0)) --the color of the bit map printed 

    VARIABLE fp_dx : INTGER;
    VARIABLE fp_dy : INTGER;
    VARIABLE fp_x : INTGER;
    VARIABLE fp_y : INTGER;
    VARIABLE fp_f : INTGER;
    
BEGIN
    IF (X >= x_start) AND (X <= X_stop) AND (Y >= y_start) AND (y <= y_stop) THEN --check if in area where the line is drawn
        -- Bresenham-Algorithmus 
        fp_x := x_start << 4; --bitshift Integervalue to allow for fractions
        fp_y := y_start << 4; --bitshift Integervalue to allow for fractions
        fp_dx := (x_stop << 4) - (x_start << 4); --bitshift Integervalue to allow for fractions
        fp_dy := (y_stop << 4) - (y_start << 4); --bitshift Integervalue to allow for fractions
        IF dx > dy THEN --check if x is the fast direction
            fp_f := fp_dx >> 1; --shift back 1 bit (is equal to halving)
            FOR I IN x_start TO x_stop LOOP
                fp_x := fp_x + 1 << 4; --Increment fast direction
                fp_f := fp_f - fp_dy; --recalculate the error value with the slow direction
                IF fp_f < 0 THEN --if error smaler than 0 
                    fp_y := fp_y + 1; --Increment slow direction
                    fp_f := fp_f + fp_dx; --recalculate the error value with the fast direction
                END IF;
                IF (fp_y >> 4) = y AND (fp_x >> 4) = x THEN --check if callculated pixel is current pixel 
                    RETURN col; --return the RGB value
                END IF;
            END LOOP;
            RETURN x"000";
        ELSE
            fp_f := fp_dy >> 1; --shift back 1 bit (is equal to halving)
            FOR I IN y_start TO y_stop LOOP
                fp_y := fp_y + 1 << 4; --Increment fast direction
                fp_f := fp_f - fp_dx; --recalculate the error value with the slow direction
                IF fp_f < 0 THEN --if error smaler than 0 
                    fp_x := fp_x + 1; --Increment slow direction
                    fp_f := fp_f + fp_dy; --recalculate the error value with the fast direction
                END IF;
                IF (fp_y >> 4) == y AND (fp_x >> 4) == x THEN --check if callculated pixel is current pixel 
                    RETURN col; --return the RGB value
                END IF;
            END LOOP;
        END IF;
        RETURN x"000";
    ELSE
        RETURN x"000";
    END IF;
END print_line;
