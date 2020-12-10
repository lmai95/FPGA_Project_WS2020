#Macros to test the VGA_Signal

radix signal gpu_tb/DUT/VGA0/out_px  hexadecimal



add wave \
sim:/gpu_tb/DUT/VGA0/current_Position \
sim:/gpu_tb/DUT/VGA0/h_sync \
sim:/gpu_tb/DUT/VGA0/v_sync \
sim:/gpu_tb/CLK_50MHz \
sim:/gpu_tb/DUT/VGA0/out_px \
sim:/gpu_tb/DUT/VGA0/v \
sim:/gpu_tb/DUT/VGA0/h \
sim:/gpu_tb/Reset
run 30ms
wave zoom full
