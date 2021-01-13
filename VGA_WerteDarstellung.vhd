library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_WerteDarstellung is
	port(
			clk	: in std_logic;
			rst	: in std_logic;
			screen_on : in std_logic;
			hpos : in integer;
			vpos : in integer;
			rgb	: out std_logic_vector(11 downto 0)
		);
end entity VGA_WerteDarstellung;

architecture behave of VGA_WerteDarstellung is

	type bitmap_zeichen is array(0 to 13) of std_logic_vector(0 to 9);
	constant bitmap_0 : bitmap_zeichen := 	("0111111100",
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
	constant bitmap_1 : bitmap_zeichen := 	("0111000000",
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
	constant bitmap_2 : bitmap_zeichen := 	("0111111100",
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
	constant bitmap_3 : bitmap_zeichen := 	("1111111110",
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
	constant bitmap_4 : bitmap_zeichen := 	("0000011100",
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
	constant bitmap_5 : bitmap_zeichen := 	("1111111110",
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
	constant bitmap_6 : bitmap_zeichen := 	("0111111100",
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
	constant bitmap_7 : bitmap_zeichen := 	("1111111110",
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
	constant bitmap_8 : bitmap_zeichen := 	("0111111100",
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
	constant bitmap_9 : bitmap_zeichen := 	("0111111100",
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
	constant bitmap_x : bitmap_zeichen :=	("1100000110",
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
	constant bitmap_y : bitmap_zeichen := 	("1000000001",
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
	constant bitmap_z : bitmap_zeichen := 	("1111111110",
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
	constant bitmap_dpl_pkt : bitmap_zeichen := ("0000000000",
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
	constant bitmap_pkt : bitmap_zeichen 	 :=("0000000000",
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
	constant bitmap_minus : bitmap_zeichen :=("0000000000",
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
	constant bitmap_empty : bitmap_zeichen := ("0000000000",
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
	
	constant vpos_draw_x : integer := 30;		
	constant vpos_draw_y : integer := 60;
	constant vpos_draw_z : integer := 90;
	
	type hpos_array is array(0 to 5) of integer;
	constant h_draw : hpos_array := (30, 45, 55, 65, 75, 85);
	
	type bitmap_array is array(0 to 5) of bitmap_zeichen;
	signal x_bitmaps : bitmap_array := (bitmap_x, bitmap_dpl_pkt, bitmap_empty, bitmap_4, bitmap_pkt, bitmap_y);
	signal y_bitmaps : bitmap_array := (bitmap_y, bitmap_dpl_pkt, bitmap_empty, bitmap_5, bitmap_pkt, bitmap_6);
	signal z_bitmaps : bitmap_array := (bitmap_z, bitmap_dpl_pkt, bitmap_empty, bitmap_8, bitmap_pkt, bitmap_9);
	
begin

	x_bitmaps(5) <= bitmap_4;
	y_bitmaps(3) <= bitmap_1;
	z_bitmaps(5) <= bitmap_7;
	
	Darstellung : process(clk, rst, hpos, vpos, screen_on)
		begin
			if rst = '0' then
				rgb <= x"000";
			elsif rising_edge(clk) then
				if screen_on = '1' then
					if vpos <= vpos_draw_z + 13 and hpos <= h_draw(h_draw'high) + 9 then
						rgb <= x"000";
						for i in 0 to h_draw'high loop
							if (hpos >= h_draw(i) and hpos <= h_draw(i) + 9) and (vpos >= vpos_draw_x and vpos <= vpos_draw_x + 13) then
								if (x_bitmaps(i)(vpos-vpos_draw_x)(hpos - h_draw(i)) = '1')
									then
									rgb <= x"F00";
								else
									rgb <= x"000";
								end if;
							elsif (hpos >= h_draw(i) and hpos <= h_draw(i) + 9) and (vpos >= vpos_draw_y and vpos <= vpos_draw_y + 13) then
								if (y_bitmaps(i)(vpos-vpos_draw_y)(hpos - h_draw(i)) = '1')
									then
									rgb <= x"0F0";
								else
									rgb <= x"000";
								end if;
							elsif (hpos >= h_draw(i) and hpos <= h_draw(i) + 9) and (vpos >= vpos_draw_z and vpos <= vpos_draw_z + 13) then
								if (z_bitmaps(i)(vpos-vpos_draw_z)(hpos - h_draw(i)) = '1')
									then
									rgb <= x"00F";
								else
									rgb <= x"000";
								end if;
							end if;
						end loop;
				
					elsif ((hpos > 30 and hpos < 32) and (vpos > 150 and vpos < 450)) or
							((hpos > 30 and hpos < 570) and (vpos = 450))
						then
							rgb <= x"222";
							
					elsif((hpos > 30 and hpos < 570) and (vpos = 250))
						then
							rgb <= x"090";
					elsif((hpos > 30 and hpos < 570) and (vpos = 300))
						then
							rgb <= x"00B";
					elsif((hpos > 30 and hpos < 570) and (vpos = 430))
						then
							rgb <= x"900";
					else
						rgb <= x"000";
					end if;
				else
					rgb <= x"000";
				end if;
			end if;
		end process;
		
end architecture behave;