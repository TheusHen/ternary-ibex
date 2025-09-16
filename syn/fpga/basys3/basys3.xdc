# Basys3 Constraints for MHX Neural T1 Simple System

# Clock
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports { clk_100mhz_i }]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk_100mhz_i}]

# Reset button (U18 is a center button on Basys3)
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { rst_btn_ni }]

# LEDs
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { led_o[0] }]
set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 } [get_ports { led_o[1] }]
set_property -dict { PACKAGE_PIN U19   IOSTANDARD LVCMOS33 } [get_ports { led_o[2] }]
set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 } [get_ports { led_o[3] }]

# Buttons (other directional buttons)
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { btn_i[0] }]  # up
set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports { btn_i[1] }]  # left  
set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33 } [get_ports { btn_i[2] }]  # right
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { btn_i[3] }]  # down

# Switches
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { sw_i[0] }]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { sw_i[1] }]
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { sw_i[2] }]
set_property -dict { PACKAGE_PIN W17   IOSTANDARD LVCMOS33 } [get_ports { sw_i[3] }]

# UART (USB-UART bridge)
set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports { uart_rx_i }]
set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 } [get_ports { uart_tx_o }]

# Configuration options
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# Timing constraints for 50MHz system clock
create_generated_clock -name clk_50mhz -source [get_ports clk_100mhz_i] -divide_by 2 [get_pins u_clk_wiz/clk_out1]

# Timing exceptions for reset
set_false_path -from [get_ports rst_btn_ni]
set_false_path -to [get_pins */reset_counter_reg[*]/PRE]

# Input/output delays
set_input_delay -clock [get_clocks clk_50mhz] -min 2.0 [get_ports {btn_i[*] sw_i[*] uart_rx_i}]
set_input_delay -clock [get_clocks clk_50mhz] -max 8.0 [get_ports {btn_i[*] sw_i[*] uart_rx_i}]

set_output_delay -clock [get_clocks clk_50mhz] -min 2.0 [get_ports {led_o[*] uart_tx_o}]
set_output_delay -clock [get_clocks clk_50mhz] -max 8.0 [get_ports {led_o[*] uart_tx_o}]