# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# MHX Simple System Constraints for Digilent Basys3
# ==================================================
#
# This constraint file defines pin assignments, timing constraints,
# and I/O standards for the MHX Simple System running on the
# Digilent Basys3 development board.
#
# Board Features:
# - Xilinx Artix-7 XC7A35T FPGA
# - 100 MHz external oscillator
# - 16 LEDs, 5 buttons, 16 switches
# - USB-UART bridge
# - 4-digit 7-segment display
# - VGA connector

# ============================================================================
# Clock Constraints
# ============================================================================

# 100 MHz system clock
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk_100mhz]
set_input_jitter sys_clk_pin 0.1

# Clock pin assignment
set_property PACKAGE_PIN W5 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]

# ============================================================================
# Reset Constraints
# ============================================================================

# Center button as reset (active high on Basys3)
set_property PACKAGE_PIN U18 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# Reset timing constraints
set_false_path -from [get_ports rst_n]
set_input_delay 0.000 [get_ports rst_n]

# ============================================================================
# UART Constraints
# ============================================================================

# UART TX (FPGA output to PC)
set_property PACKAGE_PIN A18 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property SLEW FAST [get_ports uart_tx]
set_property DRIVE 8 [get_ports uart_tx]

# UART RX (FPGA input from PC)
set_property PACKAGE_PIN B18 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

# UART timing constraints
set_output_delay -clock sys_clk_pin -max 2.000 [get_ports uart_tx]
set_output_delay -clock sys_clk_pin -min -1.000 [get_ports uart_tx]
set_input_delay -clock sys_clk_pin -max 2.000 [get_ports uart_rx]
set_input_delay -clock sys_clk_pin -min -1.000 [get_ports uart_rx]

# ============================================================================
# LED Constraints (GPIO Outputs)
# ============================================================================

# LEDs LD0-LD7 (using first 8 of 16 available LEDs)
set_property PACKAGE_PIN U16 [get_ports {led[0]}]  # LD0
set_property PACKAGE_PIN E19 [get_ports {led[1]}]  # LD1
set_property PACKAGE_PIN U19 [get_ports {led[2]}]  # LD2
set_property PACKAGE_PIN V19 [get_ports {led[3]}]  # LD3
set_property PACKAGE_PIN W18 [get_ports {led[4]}]  # LD4
set_property PACKAGE_PIN U15 [get_ports {led[5]}]  # LD5
set_property PACKAGE_PIN U14 [get_ports {led[6]}]  # LD6
set_property PACKAGE_PIN V14 [get_ports {led[7]}]  # LD7

# LED I/O standards
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
set_property SLEW SLOW [get_ports {led[*]}]
set_property DRIVE 8 [get_ports {led[*]}]

# LED timing constraints
set_output_delay -clock sys_clk_pin -max 5.000 [get_ports {led[*]}]
set_output_delay -clock sys_clk_pin -min -2.000 [get_ports {led[*]}]

# ============================================================================
# Button Constraints (GPIO Inputs)
# ============================================================================

# Push buttons (active high)
set_property PACKAGE_PIN T18 [get_ports {btn[0]}]  # BTNU (Up)
set_property PACKAGE_PIN W19 [get_ports {btn[1]}]  # BTNL (Left)
set_property PACKAGE_PIN T17 [get_ports {btn[2]}]  # BTNR (Right)
set_property PACKAGE_PIN U17 [get_ports {btn[3]}]  # BTND (Down)

set_property IOSTANDARD LVCMOS33 [get_ports {btn[*]}]

# Button timing constraints
set_input_delay -clock sys_clk_pin -max 5.000 [get_ports {btn[*]}]
set_input_delay -clock sys_clk_pin -min -2.000 [get_ports {btn[*]}]
set_false_path -from [get_ports {btn[*]}]

# ============================================================================
# Switch Constraints (GPIO Inputs)
# ============================================================================

# Slide switches SW0-SW3 (using first 4 of 16 available switches)
set_property PACKAGE_PIN V17 [get_ports {sw[0]}]   # SW0
set_property PACKAGE_PIN V16 [get_ports {sw[1]}]   # SW1
set_property PACKAGE_PIN W16 [get_ports {sw[2]}]   # SW2
set_property PACKAGE_PIN W17 [get_ports {sw[3]}]   # SW3

set_property IOSTANDARD LVCMOS33 [get_ports {sw[*]}]

# Switch timing constraints
set_input_delay -clock sys_clk_pin -max 5.000 [get_ports {sw[*]}]
set_input_delay -clock sys_clk_pin -min -2.000 [get_ports {sw[*]}]
set_false_path -from [get_ports {sw[*]}]

# ============================================================================
# SPI Constraints (Pmod Header JA)
# ============================================================================

# SPI signals on Pmod JA (pins 1-4)
set_property PACKAGE_PIN J1 [get_ports spi_sck]      # JA1
set_property PACKAGE_PIN L2 [get_ports spi_mosi]     # JA2
set_property PACKAGE_PIN J2 [get_ports spi_miso]     # JA3
set_property PACKAGE_PIN G2 [get_ports spi_cs]       # JA4

set_property IOSTANDARD LVCMOS33 [get_ports spi_sck]
set_property IOSTANDARD LVCMOS33 [get_ports spi_mosi]
set_property IOSTANDARD LVCMOS33 [get_ports spi_miso]
set_property IOSTANDARD LVCMOS33 [get_ports spi_cs]

# SPI drive strength and slew rate
set_property SLEW FAST [get_ports spi_sck]
set_property SLEW FAST [get_ports spi_mosi]
set_property SLEW FAST [get_ports spi_cs]
set_property DRIVE 8 [get_ports spi_sck]
set_property DRIVE 8 [get_ports spi_mosi]
set_property DRIVE 8 [get_ports spi_cs]

# SPI timing constraints
set_output_delay -clock sys_clk_pin -max 5.000 [get_ports {spi_sck spi_mosi spi_cs}]
set_output_delay -clock sys_clk_pin -min -2.000 [get_ports {spi_sck spi_mosi spi_cs}]
set_input_delay -clock sys_clk_pin -max 5.000 [get_ports spi_miso]
set_input_delay -clock sys_clk_pin -min -2.000 [get_ports spi_miso]

# ============================================================================
# Configuration and Bitstream Settings
# ============================================================================

# Configuration mode
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]

# Bitstream compression
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# Configuration voltage
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

# ============================================================================
# Unused Pin Constraints
# ============================================================================

# Unused LEDs (LD8-LD15)
# set_property PACKAGE_PIN V13 [get_ports {unused_led[8]}]   # LD8
# set_property PACKAGE_PIN V3 [get_ports {unused_led[9]}]    # LD9
# set_property PACKAGE_PIN W3 [get_ports {unused_led[10]}]   # LD10
# set_property PACKAGE_PIN U3 [get_ports {unused_led[11]}]   # LD11
# set_property PACKAGE_PIN P3 [get_ports {unused_led[12]}]   # LD12
# set_property PACKAGE_PIN N3 [get_ports {unused_led[13]}]   # LD13
# set_property PACKAGE_PIN P1 [get_ports {unused_led[14]}]   # LD14
# set_property PACKAGE_PIN L1 [get_ports {unused_led[15]}]   # LD15

# 7-segment display (not used in this design)
# Cathodes
# set_property PACKAGE_PIN T10 [get_ports {seg[0]}]  # CA
# set_property PACKAGE_PIN R10 [get_ports {seg[1]}]  # CB
# set_property PACKAGE_PIN K16 [get_ports {seg[2]}]  # CC
# set_property PACKAGE_PIN K13 [get_ports {seg[3]}]  # CD
# set_property PACKAGE_PIN P15 [get_ports {seg[4]}]  # CE
# set_property PACKAGE_PIN T11 [get_ports {seg[5]}]  # CF
# set_property PACKAGE_PIN L18 [get_ports {seg[6]}]  # CG
# set_property PACKAGE_PIN H15 [get_ports dp]        # DP

# Anodes
# set_property PACKAGE_PIN J17 [get_ports {an[0]}]   # AN0
# set_property PACKAGE_PIN J18 [get_ports {an[1]}]   # AN1
# set_property PACKAGE_PIN T9 [get_ports {an[2]}]    # AN2
# set_property PACKAGE_PIN J14 [get_ports {an[3]}]   # AN3

# VGA (not used in this design)
# set_property PACKAGE_PIN G19 [get_ports {vga_r[0]}]
# set_property PACKAGE_PIN H19 [get_ports {vga_r[1]}]
# set_property PACKAGE_PIN J19 [get_ports {vga_r[2]}]
# set_property PACKAGE_PIN N19 [get_ports {vga_r[3]}]
# set_property PACKAGE_PIN N18 [get_ports {vga_b[0]}]
# set_property PACKAGE_PIN L18 [get_ports {vga_b[1]}]
# set_property PACKAGE_PIN K18 [get_ports {vga_b[2]}]
# set_property PACKAGE_PIN J18 [get_ports {vga_b[3]}]
# set_property PACKAGE_PIN J17 [get_ports {vga_g[0]}]
# set_property PACKAGE_PIN H17 [get_ports {vga_g[1]}]
# set_property PACKAGE_PIN G17 [get_ports {vga_g[2]}]
# set_property PACKAGE_PIN D17 [get_ports {vga_g[3]}]
# set_property PACKAGE_PIN P19 [get_ports vga_hs]
# set_property PACKAGE_PIN R19 [get_ports vga_vs]

# ============================================================================
# Power and Thermal Constraints
# ============================================================================

# Power optimization
set_property POWER_OPT.PAR_STATIC_POWER_REDUCTION TRUE [current_design]

# Thermal shutdown temperature
set_operating_conditions -junction_temp_max 85

# ============================================================================
# Implementation Strategy Settings
# ============================================================================

# Placement strategy
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

# Routing strategy
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

# Physical optimization
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]

# ============================================================================
# Timing Exceptions and Constraints
# ============================================================================

# Maximum delay constraints for combinatorial paths
set_max_delay 8.0 -from [get_ports {btn[*] sw[*]}] -to [get_ports {led[*]}]

# ============================================================================
# Board-Specific Notes
# ============================================================================

# Basys3 Board Notes:
# - External 100 MHz oscillator provides system clock
# - USB-UART bridge for serial communication
# - 16 LEDs, 16 switches, 5 buttons available
# - 4-digit 7-segment display available but not used
# - VGA connector available but not used
# - Pmod connectors provide 3.3V I/O
# - No external memory interface in this design

# Performance targets:
# - System clock: 100 MHz (10 ns period)
# - UART baud rate: 115200 bps
# - SPI clock: up to 10 MHz
# - GPIO update rate: up to 1 MHz

# Resource utilization estimates:
# - LUTs: ~2000 (6% of available)
# - Flip-flops: ~1500 (3% of available)
# - Block RAM: 2-4 blocks (6-12% of available)
# - DSP slices: 0-2 (0-2% of available)