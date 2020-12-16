# FPGA_Project_WS2020
FPGA_Project_HS_Aalen_WS2020  


-----Sensor Kontroll Modul---------------
Eingänge:
x-achse (signed integer range) :in m/s²
y-achse (signed integer range) :in m/s²
z-achse (signed integer range) :in m/s²

Ausgänge:


---------UART ---------------------------
Eingänge:
RX_EN
RX_DATA[N...0]
RX_ERROR
TX_BUSY

Ausgänge:
CLK
Reset
TX_EN
TX_DATA[N...0]
RX_BUSY
