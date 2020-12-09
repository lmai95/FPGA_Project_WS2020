transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/Lukas/Documents/MEGA/Studium/8_Semester/FPGA_Project_WS2020/VGA_typ.vhd}
vcom -93 -work work {C:/Users/Lukas/Documents/MEGA/Studium/8_Semester/FPGA_Project_WS2020/VGA.vhd}

vcom -93 -work work {C:/Users/Lukas/Documents/MEGA/Studium/8_Semester/FPGA_Project_WS2020/VGA_Tester.vhd}
vcom -93 -work work {C:/Users/Lukas/Documents/MEGA/Studium/8_Semester/FPGA_Project_WS2020/VGA_TB.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cycloneiii -L rtl_work -L work -voptargs="+acc"  VGA

do C:/Users/Lukas/Documents/MEGA/Studium/8_Semester/FPGA_Project_WS2020/Marcos.do
