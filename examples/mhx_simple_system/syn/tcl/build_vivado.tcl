# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# MHX Simple System Vivado Build Script
# =====================================
#
# This script performs the complete FPGA synthesis flow for the MHX Simple System
# using Xilinx Vivado. It supports multiple target boards and configurations.
#
# Usage:
#   vivado -mode batch -source build_vivado.tcl -tclargs <board> <part>
# 
# Example:
#   vivado -mode batch -source build_vivado.tcl -tclargs arty_a7_35t xc7a35tcsg324-1

# Parse command line arguments
if {$argc < 2} {
    puts "ERROR: Missing arguments"
    puts "Usage: vivado -mode batch -source build_vivado.tcl -tclargs <board> <part>"
    puts "Example: vivado -mode batch -source build_vivado.tcl -tclargs arty_a7_35t xc7a35tcsg324-1"
    exit 1
}

set BOARD [lindex $argv 0]
set PART [lindex $argv 1]

puts "========================================"
puts "MHX Simple System Vivado Build"
puts "========================================"
puts "Board: $BOARD"
puts "Part:  $PART"
puts "========================================"

# Project configuration
set PROJECT_NAME "mhx_simple_system"
set TOP_MODULE "mhx_simple_system_top"
set OUTPUT_DIR "../build/vivado"
set CONSTRAINT_DIR "../constraints"
set RTL_DIR "../../rtl"

# Create output directory
file mkdir $OUTPUT_DIR

# Set the reference directory for source files
set origin_dir [file dirname [info script]]
set mhx_root_dir [file normalize "$origin_dir/../../../.."]

puts "Origin directory: $origin_dir"
puts "MHX root directory: $mhx_root_dir"

# Create project
create_project $PROJECT_NAME $OUTPUT_DIR -part $PART -force

# Set project properties
set_property board_part [get_board_parts *${BOARD}*] [current_project]
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]

# Add source files using FuseSoC approach
puts "Adding source files..."

# Add MHX Simple System RTL
add_files -norecurse [glob ${RTL_DIR}/*.sv]
add_files -norecurse [glob ${mhx_root_dir}/rtl/*.sv]

# Add primitive library files
if {[file exists ${mhx_root_dir}/vendor/lowrisc_ip]} {
    set prim_files [glob -nocomplain ${mhx_root_dir}/vendor/lowrisc_ip/ip/prim/rtl/*.sv]
    if {[llength $prim_files] > 0} {
        add_files -norecurse $prim_files
    }
}

# Add FPGA top-level wrapper
set TOP_WRAPPER_FILE "${RTL_DIR}/mhx_simple_system_top.sv"
if {![file exists $TOP_WRAPPER_FILE]} {
    puts "Creating FPGA top-level wrapper..."
    set fp [open $TOP_WRAPPER_FILE w]
    puts $fp {// Copyright lowRISC contributors.
// Copyright 2025 MHX Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX Simple System FPGA Top Level
 * 
 * This module provides the top-level interface for FPGA implementation,
 * including clock generation, reset handling, and I/O mapping.
 */

module mhx_simple_system_top (
    // Clock and reset
    input  logic clk_100mhz,
    input  logic rst_n,
    
    // UART interface
    output logic uart_tx,
    input  logic uart_rx,
    
    // GPIO interface (LEDs and buttons)
    output logic [7:0] led,
    input  logic [3:0] btn,
    input  logic [3:0] sw,
    
    // Optional SPI interface
    output logic spi_sck,
    output logic spi_mosi,
    input  logic spi_miso,
    output logic spi_cs
);

    // Clock and reset signals
    logic clk_sys;
    logic rst_sys_n;
    
    // Clock generation (for now, just use input clock)
    assign clk_sys = clk_100mhz;
    
    // Reset synchronization
    logic [2:0] rst_sync;
    always_ff @(posedge clk_sys or negedge rst_n) begin
        if (!rst_n) begin
            rst_sync <= 3'b000;
        end else begin
            rst_sync <= {rst_sync[1:0], 1'b1};
        end
    end
    assign rst_sys_n = rst_sync[2];
    
    // GPIO mapping
    logic [7:0] gpio_out;
    logic [7:0] gpio_in;
    logic [7:0] gpio_oe;
    
    // Map buttons and switches to GPIO inputs
    assign gpio_in = {sw, btn};
    
    // Map GPIO outputs to LEDs
    assign led = gpio_out;
    
    // Instantiate MHX Simple System
    mhx_simple_system u_mhx_simple_system (
        .IO_CLK     (clk_sys),
        .IO_RST_N   (rst_sys_n),
        
        .uart_tx    (uart_tx),
        .uart_rx    (uart_rx),
        
        .gpio_out   (gpio_out),
        .gpio_in    (gpio_in),
        .gpio_oe    (gpio_oe),
        
        .spi_sck    (spi_sck),
        .spi_mosi   (spi_mosi),
        .spi_miso   (spi_miso),
        .spi_cs     (spi_cs)
    );

endmodule}
    close $fp
    add_files -norecurse $TOP_WRAPPER_FILE
}

# Set top module
set_property top $TOP_MODULE [current_fileset]

# Add constraint files
puts "Adding constraint files..."
set XDC_FILE "${CONSTRAINT_DIR}/${BOARD}.xdc"
if {[file exists $XDC_FILE]} {
    add_files -fileset constrs_1 -norecurse $XDC_FILE
} else {
    puts "WARNING: Constraint file $XDC_FILE not found. Creating template..."
    set fp [open $XDC_FILE w]
    puts $fp "# MHX Simple System Constraints for $BOARD"
    puts $fp "# Clock constraint"
    puts $fp "create_clock -period 10.000 -name sys_clk \[get_ports clk_100mhz\]"
    puts $fp ""
    puts $fp "# I/O constraints (customize for your board)"
    puts $fp "# set_property PACKAGE_PIN E3 \[get_ports clk_100mhz\]"
    puts $fp "# set_property IOSTANDARD LVCMOS33 \[get_ports clk_100mhz\]"
    close $fp
    add_files -fileset constrs_1 -norecurse $XDC_FILE
}

# Update compile order
update_compile_order -fileset sources_1

# Run synthesis
puts "Starting synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check synthesis results
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed"
    exit 1
}

# Report synthesis results
open_run synth_1 -name synth_1
report_timing_summary -file ${OUTPUT_DIR}/synth_timing_summary.rpt
report_utilization -file ${OUTPUT_DIR}/synth_utilization.rpt
report_power -file ${OUTPUT_DIR}/synth_power.rpt

# Run implementation
puts "Starting implementation..."
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Check implementation results
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed"
    exit 1
}

# Report implementation results
open_run impl_1
report_timing_summary -file ${OUTPUT_DIR}/impl_timing_summary.rpt
report_utilization -file ${OUTPUT_DIR}/impl_utilization.rpt
report_power -file ${OUTPUT_DIR}/impl_power.rpt
report_drc -file ${OUTPUT_DIR}/impl_drc.rpt

# Generate bitstream
puts "Generating bitstream..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Check bitstream generation
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Bitstream generation failed"
    exit 1
}

# Copy bitstream to output directory
set BITSTREAM_FILE "${OUTPUT_DIR}/${PROJECT_NAME}.runs/impl_1/${TOP_MODULE}.bit"
set OUTPUT_BITSTREAM "${OUTPUT_DIR}/${BOARD}.bit"

if {[file exists $BITSTREAM_FILE]} {
    file copy -force $BITSTREAM_FILE $OUTPUT_BITSTREAM
    puts "Bitstream generated: $OUTPUT_BITSTREAM"
} else {
    puts "ERROR: Bitstream file not found: $BITSTREAM_FILE"
    exit 1
}

# Generate programming files
write_cfgmem -format mcs -size 16 -interface SPIx4 \
    -loadbit "up 0x0 $OUTPUT_BITSTREAM" \
    -file "${OUTPUT_DIR}/${BOARD}.mcs"

# Print summary
puts "========================================"
puts "Build Summary"
puts "========================================"
puts "Project: $PROJECT_NAME"
puts "Board: $BOARD"
puts "Part: $PART"
puts "Bitstream: $OUTPUT_BITSTREAM"
puts "Build completed successfully!"
puts "========================================"

# Generate build report
set REPORT_FILE "${OUTPUT_DIR}/build_report.txt"
set fp [open $REPORT_FILE w]
puts $fp "MHX Simple System Build Report"
puts $fp "=============================="
puts $fp ""
puts $fp "Build Configuration:"
puts $fp "  Project: $PROJECT_NAME"
puts $fp "  Board: $BOARD"
puts $fp "  Part: $PART"
puts $fp "  Top Module: $TOP_MODULE"
puts $fp ""
puts $fp "Build Results:"
puts $fp "  Synthesis: [get_property PROGRESS [get_runs synth_1]]"
puts $fp "  Implementation: [get_property PROGRESS [get_runs impl_1]]"
puts $fp "  Bitstream: [file exists $OUTPUT_BITSTREAM]"
puts $fp ""
puts $fp "Output Files:"
puts $fp "  Bitstream: $OUTPUT_BITSTREAM"
puts $fp "  MCS File: ${OUTPUT_DIR}/${BOARD}.mcs"
puts $fp ""
puts $fp "Reports:"
puts $fp "  Synthesis Timing: ${OUTPUT_DIR}/synth_timing_summary.rpt"
puts $fp "  Synthesis Utilization: ${OUTPUT_DIR}/synth_utilization.rpt"
puts $fp "  Implementation Timing: ${OUTPUT_DIR}/impl_timing_summary.rpt"
puts $fp "  Implementation Utilization: ${OUTPUT_DIR}/impl_utilization.rpt"
close $fp

puts "Build report saved: $REPORT_FILE"

# Close project
close_project

puts "Vivado build script completed successfully!"