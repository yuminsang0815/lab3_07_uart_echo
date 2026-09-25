# Combo II-DLD S75 / MAIN CLOCK F = 50 MHz / USB UART 9600 8N1
set_property PACKAGE_PIN B6 [get_ports clk_50mhz]
set_property PACKAGE_PIN K4 [get_ports rst_p]
set_property PACKAGE_PIN C6 [get_ports uart_rxd]
set_property PACKAGE_PIN F6 [get_ports uart_txd]

# 수신 데이터 표시용 LED[7:0]
set_property PACKAGE_PIN N5 [get_ports {led[0]}]
set_property PACKAGE_PIN M1 [get_ports {led[1]}]
set_property PACKAGE_PIN M3 [get_ports {led[2]}]
set_property PACKAGE_PIN M7 [get_ports {led[3]}]
set_property PACKAGE_PIN N7 [get_ports {led[4]}]
set_property PACKAGE_PIN M2 [get_ports {led[5]}]
set_property PACKAGE_PIN M4 [get_ports {led[6]}]
set_property PACKAGE_PIN L4 [get_ports {led[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports *]

# 50 MHz 클록 제약 (주기 20.000 ns)
create_clock -name clk_50mhz -period 20.000 [get_ports clk_50mhz]

# 비동기 입력 타이밍 예외 처리
set_false_path from [get_ports {rst_p uart_rxd}]