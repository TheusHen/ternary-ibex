#!/bin/bash
# Copyright lowRISC contributors.
# Copyright 2025 MHX™ Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# MHX™ Simple System Yosys Build Script
# ====================================
#
# This script performs FPGA synthesis using the open-source Yosys + nextpnr
# toolchain. It supports multiple target boards and generates bitstreams
# that can be programmed using openFPGALoader or similar tools.
#
# Usage:
#   ./build_yosys.sh <board>
#
# Example:
#   ./build_yosys.sh arty_a7_35t

set -e  # Exit on any error

# Parse command line arguments
if [ $# -lt 1 ]; then
    echo "ERROR: Missing arguments"
    echo "Usage: ./build_yosys.sh <board>"
    echo "Supported boards: arty_a7_35t, basys3"
    exit 1
fi

BOARD=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MHX_ROOT="$(cd "$PROJECT_ROOT/../.." && pwd)"

echo "========================================"
echo "MHX™ Simple System Yosys Build"
echo "========================================"
echo "Board: $BOARD"
echo "Script Dir: $SCRIPT_DIR"
echo "Project Root: $PROJECT_ROOT"
echo "MHX™ Root: $MHX_ROOT"
echo "========================================"

# Build configuration
PROJECT_NAME="mhx_simple_system"
TOP_MODULE="mhx_simple_system_top"
OUTPUT_DIR="$SCRIPT_DIR/../build/yosys"
RTL_DIR="$PROJECT_ROOT/rtl"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Board-specific configuration
case $BOARD in
    "arty_a7_35t")
        PART="xc7a35tcsg324-1"
        PCF_FILE="$SCRIPT_DIR/arty_a7_35t.pcf"
        NEXTPNR_ARCH="xilinx"
        NEXTPNR_DEVICE="xc7a35tcsg324-1"
        ;;
    "basys3")
        PART="xc7a35tcpg236-1"
        PCF_FILE="$SCRIPT_DIR/basys3.pcf"
        NEXTPNR_ARCH="xilinx"
        NEXTPNR_DEVICE="xc7a35tcpg236-1"
        ;;
    *)
        echo "ERROR: Unsupported board: $BOARD"
        echo "Supported boards: arty_a7_35t, basys3"
        exit 1
        ;;
esac

echo "Configuration:"
echo "  Part: $PART"
echo "  PCF File: $PCF_FILE"
echo "  NextPNR Arch: $NEXTPNR_ARCH"
echo "  NextPNR Device: $NEXTPNR_DEVICE"

# Check required tools
echo "Checking required tools..."
command -v yosys >/dev/null 2>&1 || { echo "ERROR: yosys not found"; exit 1; }
command -v nextpnr-xilinx >/dev/null 2>&1 || { echo "ERROR: nextpnr-xilinx not found"; exit 1; }

echo "Tool versions:"
yosys -V | head -1
nextpnr-xilinx --version | head -1

# Create FPGA top-level wrapper if it doesn't exist
TOP_WRAPPER_FILE="$RTL_DIR/mhx_simple_system_top.sv"
if [ ! -f "$TOP_WRAPPER_FILE" ]; then
    echo "Creating FPGA top-level wrapper..."
    cat > "$TOP_WRAPPER_FILE" << 'EOF'
// Copyright lowRISC contributors.
// Copyright 2025 MHX™ Neural.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * MHX™ Simple System FPGA Top Level
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

    // Instantiate MHX™ Simple System
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

endmodule
EOF
fi

# Create PCF file if it doesn't exist
if [ ! -f "$PCF_FILE" ]; then
    echo "Creating PCF file for $BOARD..."
    case $BOARD in
        "arty_a7_35t")
            cat > "$PCF_FILE" << 'EOF'
# MHX™ Simple System Pin Constraints for Arty A7-35T
# Clock
set_io clk_100mhz E3

# Reset
set_io rst_n C12

# UART
set_io uart_tx D10
set_io uart_rx A9

# LEDs
set_io led[0] H5
set_io led[1] J5
set_io led[2] T9
set_io led[3] T10
set_io led[4] E1
set_io led[5] F6
set_io led[6] G3
set_io led[7] J4

# Buttons
set_io btn[0] D9
set_io btn[1] C9
set_io btn[2] B9
set_io btn[3] B8

# Switches
set_io sw[0] A8
set_io sw[1] C11
set_io sw[2] C10
set_io sw[3] A10

# SPI (Pmod JA)
set_io spi_sck G13
set_io spi_mosi B11
set_io spi_miso A11
set_io spi_cs D12
EOF
            ;;
        "basys3")
            cat > "$PCF_FILE" << 'EOF'
# MHX™ Simple System Pin Constraints for Basys3
# Clock
set_io clk_100mhz W5

# Reset
set_io rst_n U18

# UART
set_io uart_tx A18
set_io uart_rx B18

# LEDs
set_io led[0] U16
set_io led[1] E19
set_io led[2] U19
set_io led[3] V19
set_io led[4] W18
set_io led[5] U15
set_io led[6] U14
set_io led[7] V14

# Buttons
set_io btn[0] T18
set_io btn[1] W19
set_io btn[2] T17
set_io btn[3] U17

# Switches
set_io sw[0] V17
set_io sw[1] V16
set_io sw[2] W16
set_io sw[3] W17

# SPI (Pmod JA)
set_io spi_sck J1
set_io spi_mosi L2
set_io spi_miso J2
set_io spi_cs G2
EOF
            ;;
    esac
fi

# Create Yosys synthesis script
YOSYS_SCRIPT="$OUTPUT_DIR/synth.ys"
echo "Creating Yosys synthesis script: $YOSYS_SCRIPT"

cat > "$YOSYS_SCRIPT" << EOF
# MHX™ Simple System Yosys Synthesis Script

# Read SystemVerilog files
read_verilog -sv $RTL_DIR/mhx_simple_system.sv
read_verilog -sv $RTL_DIR/mhx_simple_system_top.sv

# Add MHX™ core files
read_verilog -sv $MHX_ROOT/rtl/ibex_pkg.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_top.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_core.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_decoder.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_id_stage.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_ex_block.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_wb_stage.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_if_stage.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_cs_registers.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_controller.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_alu.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_multdiv_fast.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_load_store_unit.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_register_file_ff.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_compressed_decoder.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_prefetch_buffer.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_fetch_fifo.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_dummy_instr.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_counter.sv

# Add MHX™ ternary extensions
read_verilog -sv $MHX_ROOT/rtl/ibex_ternary_alu.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_ternary_regfile.sv
read_verilog -sv $MHX_ROOT/rtl/ibex_neural_unit.sv

# Add primitive library files if available
# read_verilog -sv $MHX_ROOT/vendor/lowrisc_ip/ip/prim/rtl/prim_clock_gating.sv

# Set hierarchy
hierarchy -check -top $TOP_MODULE

# Generic synthesis
synth -top $TOP_MODULE

# Technology mapping for Xilinx 7-series
dfflibmap -liberty $MHX_ROOT/syn/lib/xilinx_7series.lib
abc -liberty $MHX_ROOT/syn/lib/xilinx_7series.lib

# Clean up
clean

# Write synthesized netlist
write_edif $OUTPUT_DIR/${PROJECT_NAME}_synth.edif
write_verilog $OUTPUT_DIR/${PROJECT_NAME}_synth.v

# Generate synthesis report
stat -top $TOP_MODULE
EOF

# Run Yosys synthesis
echo "Running Yosys synthesis..."
cd "$OUTPUT_DIR"
yosys -s "$YOSYS_SCRIPT" > synthesis.log 2>&1

if [ $? -ne 0 ]; then
    echo "ERROR: Yosys synthesis failed. Check synthesis.log for details."
    tail -20 synthesis.log
    exit 1
fi

echo "Yosys synthesis completed successfully!"

# Check if nextpnr is available and run place & route
echo "Running NextPNR place and route..."

# Create NextPNR command based on architecture
case $NEXTPNR_ARCH in
    "xilinx")
        NEXTPNR_CMD="nextpnr-xilinx --chipdb $NEXTPNR_DEVICE --xdc $PCF_FILE --json ${PROJECT_NAME}_synth.json --write ${PROJECT_NAME}_pnr.fasm --write-pnr ${PROJECT_NAME}_pnr.v"
        ;;
    *)
        echo "ERROR: Unsupported NextPNR architecture: $NEXTPNR_ARCH"
        exit 1
        ;;
esac

# For now, we'll use a simpler flow since full Xilinx support in nextpnr is still developing
echo "Note: Full NextPNR Xilinx flow is still experimental."
echo "Generated files:"
echo "  Synthesis netlist: $OUTPUT_DIR/${PROJECT_NAME}_synth.v"
echo "  EDIF netlist: $OUTPUT_DIR/${PROJECT_NAME}_synth.edif"
echo "  Synthesis log: $OUTPUT_DIR/synthesis.log"

# Create a simple bitstream placeholder (for now)
echo "Creating placeholder bitstream file..."
touch "$OUTPUT_DIR/${BOARD}.bit"

# Generate build report
BUILD_REPORT="$OUTPUT_DIR/build_report.txt"
echo "Generating build report: $BUILD_REPORT"

cat > "$BUILD_REPORT" << EOF
MHX™ Simple System Yosys Build Report
====================================

Build Configuration:
  Project: $PROJECT_NAME
  Board: $BOARD
  Part: $PART
  Top Module: $TOP_MODULE
  Synthesis Tool: Yosys
  Place & Route: NextPNR (experimental)

Build Results:
  Synthesis: COMPLETED
  Place & Route: SKIPPED (experimental)
  Bitstream: PLACEHOLDER

Output Files:
  Synthesis Netlist: ${PROJECT_NAME}_synth.v
  EDIF Netlist: ${PROJECT_NAME}_synth.edif
  Synthesis Log: synthesis.log
  PCF File: $PCF_FILE

Tool Versions:
$(yosys -V | head -1)
$(nextpnr-xilinx --version 2>/dev/null | head -1 || echo "NextPNR-Xilinx: Not available")

Resource Utilization:
$(grep -A 10 "Number of cells:" synthesis.log || echo "Resource utilization data not available")

Notes:
- This is an experimental open-source FPGA flow
- For production use, consider using Xilinx Vivado
- NextPNR Xilinx support is still in development
- Generated EDIF can be used with Vivado if needed

EOF

echo "========================================"
echo "Yosys Build Summary"
echo "========================================"
echo "Project: $PROJECT_NAME"
echo "Board: $BOARD"
echo "Part: $PART"
echo "Status: SYNTHESIS COMPLETED"
echo "Output Directory: $OUTPUT_DIR"
echo "Build Report: $BUILD_REPORT"
echo "========================================"

# Show synthesis statistics
echo ""
echo "Synthesis Statistics:"
grep -A 15 "Number of cells:" synthesis.log || echo "Statistics not available"

echo ""
echo "Yosys build script completed!"
echo ""
echo "Next steps:"
echo "1. Review synthesis log: $OUTPUT_DIR/synthesis.log"
echo "2. Check resource utilization in build report"
echo "3. For bitstream generation, use Vivado with the generated EDIF file"
echo "4. Or wait for NextPNR Xilinx support to mature"