# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# MHX Simple System Constraints for Digilent Arty A7-35T
# =======================================================
#
# This constraint file defines pin assignments, timing constraints,
# and I/O standards for the MHX Simple System running on the
# Digilent Arty A7-35T development board.
#
# Board Features:
# - Xilinx Artix-7 XC7A35T FPGA
# - 100 MHz external oscillator
# - 4 LEDs, 4 buttons, 4 switches
# - USB-UART bridge (FTDI FT2232HQ)
# - Pmod connectors

# ============================================================================
# Clock Constraints
# ============================================================================

# 100 MHz system clock
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk_100mhz]
set_input_jitter sys_clk_pin 0.1

# Clock pin assignment
set_property PACKAGE_PIN E3 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]

# Derived clocks (if any clock generation is used)
# create_generated_clock -name clk_sys -source [get_ports clk_100mhz] -divide_by 1 [get_pins u_clock_gen/clk_out]

# ============================================================================
# Reset Constraints
# ============================================================================

# Reset button (active low)
set_property PACKAGE_PIN C12 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# Reset timing constraints
set_false_path -from [get_ports rst_n]
set_input_delay 0.000 [get_ports rst_n]

# ============================================================================
# UART Constraints
# ============================================================================

# UART TX (FPGA output to PC)
set_property PACKAGE_PIN D10 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property SLEW FAST [get_ports uart_tx]
set_property DRIVE 8 [get_ports uart_tx]

# UART RX (FPGA input from PC)
set_property PACKAGE_PIN A9 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

# UART timing constraints (115200 baud = 8.68us period)
set_output_delay -clock sys_clk_pin -max 2.000 [get_ports uart_tx]
set_output_delay -clock sys_clk_pin -min -1.000 [get_ports uart_tx]
set_input_delay -clock sys_clk_pin -max 2.000 [get_ports uart_rx]
set_input_delay -clock sys_clk_pin -min -1.000 [get_ports uart_rx]

# ============================================================================
# LED Constraints (GPIO Outputs)
# ============================================================================

# LED pins (active high, green LEDs LD4-LD7)
set_property PACKAGE_PIN H5 [get_ports {led[0]}]
set_property PACKAGE_PIN J5 [get_ports {led[1]}]
set_property PACKAGE_PIN T9 [get_ports {led[2]}]
set_property PACKAGE_PIN T10 [get_ports {led[3]}]

# RGB LEDs (LD0-LD3) - using only green channel for simplicity
set_property PACKAGE_PIN E1 [get_ports {led[4]}]
set_property PACKAGE_PIN F6 [get_ports {led[5]}]
set_property PACKAGE_PIN G3 [get_ports {led[6]}]
set_property PACKAGE_PIN J4 [get_ports {led[7]}]

# LED I/O standards and drive strength
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
set_property SLEW SLOW [get_ports {led[*]}]
set_property DRIVE 8 [get_ports {led[*]}]

# LED timing constraints (not critical, but good practice)
set_output_delay -clock sys_clk_pin -max 5.000 [get_ports {led[*]}]
set_output_delay -clock sys_clk_pin -min -2.000 [get_ports {led[*]}]

# ============================================================================
# Button Constraints (GPIO Inputs)
# ============================================================================

# Push buttons BTN0-BTN3 (active high when pressed)
set_property PACKAGE_PIN D9 [get_ports {btn[0]}]
set_property PACKAGE_PIN C9 [get_ports {btn[1]}]
set_property PACKAGE_PIN B9 [get_ports {btn[2]}]
set_property PACKAGE_PIN B8 [get_ports {btn[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {btn[*]}]

# Button timing constraints (asynchronous inputs)
set_input_delay -clock sys_clk_pin -max 5.000 [get_ports {btn[*]}]
set_input_delay -clock sys_clk_pin -min -2.000 [get_ports {btn[*]}]

# Button debounce - mark as asynchronous
set_false_path -from [get_ports {btn[*]}]

# ============================================================================
# Switch Constraints (GPIO Inputs)
# ============================================================================

# Slide switches SW0-SW3
set_property PACKAGE_PIN A8 [get_ports {sw[0]}]
set_property PACKAGE_PIN C11 [get_ports {sw[1]}]
set_property PACKAGE_PIN C10 [get_ports {sw[2]}]
set_property PACKAGE_PIN A10 [get_ports {sw[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {sw[*]}]

# Switch timing constraints (quasi-static inputs)
set_input_delay -clock sys_clk_pin -max 5.000 [get_ports {sw[*]}]
set_input_delay -clock sys_clk_pin -min -2.000 [get_ports {sw[*]}]
set_false_path -from [get_ports {sw[*]}]

# ============================================================================
# SPI Constraints (Pmod Connector JA)
# ============================================================================

# SPI signals on Pmod JA (top row)
set_property PACKAGE_PIN G13 [get_ports spi_sck]     # JA1
set_property PACKAGE_PIN B11 [get_ports spi_mosi]    # JA2
set_property PACKAGE_PIN A11 [get_ports spi_miso]    # JA3
set_property PACKAGE_PIN D12 [get_ports spi_cs]      # JA4

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

# SPI timing constraints (10 MHz max)
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
# Power and Thermal Constraints
# ============================================================================

# Power optimization
set_property POWER_OPT.PAR_STATIC_POWER_REDUCTION TRUE [current_design]

# Thermal shutdown temperature
set_operating_conditions -junction_temp_max 85

# ============================================================================
# Design Rule Check (DRC) Waivers
# ============================================================================

# Waive clock buffer warnings for external clocks
set_property SEVERITY {Warning} [get_drc_checks REQP-52]

# Waive timing warnings for asynchronous resets
set_property SEVERITY {Warning} [get_drc_checks TIMING-18]

# ============================================================================
# Implementation Strategy Settings
# ============================================================================

# Placement strategy for better timing closure
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

# Routing strategy
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

# Physical optimization
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]

# ============================================================================
# Timing Exceptions and Constraints
# ============================================================================

# Cross-clock domain constraints (if any)
# set_false_path -from [get_clocks clk_a] -to [get_clocks clk_b]

# Multi-cycle paths (if any)
# set_multicycle_path -setup 2 -from [get_pins ...] -to [get_pins ...]

# Maximum delay constraints for combinatorial paths
set_max_delay 8.0 -from [get_ports {btn[*] sw[*]}] -to [get_ports {led[*]}]

# ============================================================================
# Debug and Analysis
# ============================================================================

# Mark critical nets for analysis
# set_property MARK_DEBUG true [get_nets {u_mhx_simple_system/clk_sys}]
# set_property MARK_DEBUG true [get_nets {u_mhx_simple_system/rst_sys_n}]

# ============================================================================
# Board-Specific Notes
# ============================================================================

# Arty A7-35T Board Notes:
# - External 100 MHz oscillator provides system clock
# - USB-UART bridge connected to UART pins (no additional drivers needed)
# - LEDs are current-limited on-board
# - Buttons and switches have pull-up/pull-down resistors
# - Pmod connectors provide 3.3V I/O
# - DDR3 memory interface available but not used in this design
# - Ethernet PHY available but not used in this design

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