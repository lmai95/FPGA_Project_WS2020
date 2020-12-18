#Macros to test the VGA_Signal

radix signal gpu_tb/DUT/VGA/green  hexadecimal
radix signal gpu_tb/DUT/VGA/red  hexadecimal
radix signal gpu_tb/DUT/VGA/blue  hexadecimal

add wave \
sim:/gpu_tb/DUT/GPU_VRAM_address \
sim:/gpu_tb/DUT/VGA_VRAM_address \
sim:/gpu_tb/DUT/plotter/current_state \
sim:/gpu_tb/DUT/frame_buffer/GPU_WriteEnable \
sim:/gpu_tb/DUT/frame_buffer/GPU_data_in \
sim:/gpu_tb/DUT/VGA/VRAM_address \
sim:/gpu_tb/DUT/VGA/h_sync \
sim:/gpu_tb/DUT/VGA/v_sync \
sim:/gpu_tb/CLK_50MHz \
sim:/gpu_tb/DUT/VGA/red \
sim:/gpu_tb/DUT/VGA/green \
sim:/gpu_tb/DUT/VGA/blue \
sim:/gpu_tb/DUT/VGA/v \
sim:/gpu_tb/DUT/VGA/h \
sim:/gpu_tb/Reset
run 1ms
wave zoom full
