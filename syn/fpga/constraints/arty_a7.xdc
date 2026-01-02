## MHX Ternary Demo - Arty A7-35T Constraints
## Copyright 2025 MHX Neural

## Clock
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk_100mhz_i]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk_100mhz_i]

## Reset Button (active-low, directly from button without debounce for initial reset)
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports rst_n_i]

## LEDs
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports {led_o[0]}]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports {led_o[1]}]
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33} [get_ports {led_o[2]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {led_o[3]}]

## RGB LEDs
# LED0 (RGB)
set_property -dict {PACKAGE_PIN G6 IOSTANDARD LVCMOS33} [get_ports {led_rgb_o[0]}]
set_property -dict {PACKAGE_PIN F6 IOSTANDARD LVCMOS33} [get_ports {led_rgb_o[1]}]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports {led_rgb_o[2]}]
# LED1 (RGB)
set_property -dict {PACKAGE_PIN G3 IOSTANDARD LVCMOS33} [get_ports {led_rgb_o[3]}]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports {led_rgb_o[4]}]
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports {led_rgb_o[5]}]
# LED2 (RGB)
set_property -dict {PACKAGE_PIN J3 IOSTANDARD LVCMOS33} [get_ports {led_rgb_o[6]}]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports {led_rgb_o[7]}]
set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33} [get_ports {led_rgb_o[8]}]
# LED3 (RGB)
set_property -dict {PACKAGE_PIN K1 IOSTANDARD LVCMOS33} [get_ports {led_rgb_o[9]}]
set_property -dict {PACKAGE_PIN H6 IOSTANDARD LVCMOS33} [get_ports {led_rgb_o[10]}]
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {led_rgb_o[11]}]

## Buttons
set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports {btn_i[0]}]
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports {btn_i[1]}]
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS33} [get_ports {btn_i[2]}]
set_property -dict {PACKAGE_PIN B8 IOSTANDARD LVCMOS33} [get_ports {btn_i[3]}]

## Switches
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports {sw_i[0]}]
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports {sw_i[1]}]
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports {sw_i[2]}]
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {sw_i[3]}]

## UART (directly on USB-UART)
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports uart_tx_o]
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports uart_rx_i]

## Seven-Segment Display (accent module, accent accent accent accent accent if present)
## Note: accent is not present on base Arty A7, but can be added via Pmod
# Accent accent accent accent accent accent accent - uncomment if using Pmod SSD
#set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports {seg_o[0]}]
#set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports {seg_o[1]}]
#set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports {seg_o[2]}]
#set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVCMOS33} [get_ports {seg_o[3]}]
#set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports {seg_o[4]}]
#set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports {seg_o[5]}]
#set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports {seg_o[6]}]
#set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {seg_o[7]}]
#set_property -dict {PACKAGE_PIN E15 IOSTANDARD LVCMOS33} [get_ports {an_o[0]}]
#set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS33} [get_ports {an_o[1]}]
#set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS33} [get_ports {an_o[2]}]
#set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports {an_o[3]}]

## Timing constraints
set_false_path -from [get_ports rst_n_i]
set_false_path -from [get_ports {btn_i[*]}]
set_false_path -from [get_ports {sw_i[*]}]
set_false_path -to [get_ports {led_o[*]}]
set_false_path -to [get_ports {led_rgb_o[*]}]

## Configuration
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
