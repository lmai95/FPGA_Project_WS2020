#Macros to test the VGA_Signal
add wave  \
sim:/vga/CLK_50MHz \
sim:/vga/h_sync \
sim:/vga/v_sync \
sim:/vga/internal_pos \
sim:/vga/out_px \

run 2ms
