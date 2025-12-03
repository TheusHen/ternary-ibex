#!/usr/bin/env bash
# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

################################################################################
# FPGA Synthesis Script for MHX Ternary Ibex Core
#
# Supports:
# - Xilinx Vivado (default)
# - Intel Quartus
#
# Usage:
#   ./syn/synthesize_fpga.sh [--tool vivado|quartus] [--board BOARD]
#
# Status: Basic implementation with placeholders for full flow
# Priority: HIGH
# Estimated effort: 2-3 weeks for complete flow
################################################################################

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RTL_ROOT="${RTL_ROOT:-${REPO_ROOT}/rtl}"
SYN_RESULTS="${SYN_RESULTS:-${REPO_ROOT}/syn/results}"

# Default configuration
FPGA_TOOL="${FPGA_TOOL:-vivado}"
FPGA_BOARD="${FPGA_BOARD:-xc7a100t}"  # Xilinx Artix-7
TARGET_FREQ="${TARGET_FREQ:-50}"  # Target frequency in MHz

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --tool)
            FPGA_TOOL="$2"
            shift 2
            ;;
        --board)
            FPGA_BOARD="$2"
            shift 2
            ;;
        --freq)
            TARGET_FREQ="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --tool TOOL       FPGA tool (vivado or quartus, default: vivado)"
            echo "  --board BOARD     Target FPGA board (default: xc7a100t)"
            echo "  --freq FREQ       Target frequency in MHz (default: 50)"
            echo "  --help            Show this help"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create results directory
mkdir -p "$SYN_RESULTS"

log_info "=========================================="
log_info "MHX Ternary Ibex FPGA Synthesis"
log_info "=========================================="
log_info "Tool: ${FPGA_TOOL}"
log_info "Board: ${FPGA_BOARD}"
log_info "Target Frequency: ${TARGET_FREQ} MHz"
log_info "Results: ${SYN_RESULTS}"
log_info "=========================================="

# Generate file list
generate_file_list() {
    cat > "${SYN_RESULTS}/files.txt" <<EOF
# RTL files for MHX Ternary Ibex synthesis
${RTL_ROOT}/ibex_pkg.sv
${RTL_ROOT}/ibex_ternary_alu.sv
${RTL_ROOT}/ibex_ternary_regfile.sv
${RTL_ROOT}/ibex_neural_unit.sv
${RTL_ROOT}/ibex_alu.sv
${RTL_ROOT}/ibex_decoder.sv
${RTL_ROOT}/ibex_register_file_ff.sv
${RTL_ROOT}/ibex_controller.sv
${RTL_ROOT}/ibex_id_stage.sv
${RTL_ROOT}/ibex_ex_block.sv
${RTL_ROOT}/ibex_wb_stage.sv
${RTL_ROOT}/ibex_core.sv
${RTL_ROOT}/ibex_top.sv
EOF
    log_info "Generated file list: ${SYN_RESULTS}/files.txt"
}

# Vivado synthesis
synthesize_vivado() {
    log_info "Generating Vivado TCL script..."
    
    cat > "${SYN_RESULTS}/vivado_synth.tcl" <<EOF
# Vivado synthesis script for MHX Ternary Ibex
# Auto-generated

# Create project
create_project mhx_ternary_ibex ${SYN_RESULTS}/vivado_project -part ${FPGA_BOARD} -force

# Set project properties
set_property target_language SystemVerilog [current_project]
set_property default_lib work [current_project]

# Add source files
read_verilog -sv [glob ${RTL_ROOT}/*.sv]

# Set top module
set_property top ibex_top [current_fileset]

# Synthesis settings
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE PerformanceOptimized [get_runs synth_1]

# Create clock constraint
create_clock -period [expr {1000.0 / ${TARGET_FREQ}}] -name clk_i [get_ports clk_i]

# Run synthesis
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Generate reports
open_run synth_1
report_utilization -file ${SYN_RESULTS}/utilization.rpt
report_timing_summary -file ${SYN_RESULTS}/timing.rpt
report_power -file ${SYN_RESULTS}/power.rpt

# Check timing
set slack [get_property SLACK [get_timing_paths]]
if {\$slack < 0} {
    puts "ERROR: Timing not met, slack = \$slack"
    exit 1
} else {
    puts "SUCCESS: Timing met, slack = \$slack"
}

exit 0
EOF

    log_info "Running Vivado synthesis..."
    if command -v vivado &> /dev/null; then
        vivado -mode batch -source "${SYN_RESULTS}/vivado_synth.tcl" \
            > "${SYN_RESULTS}/vivado.log" 2>&1
        log_success "Vivado synthesis completed"
        
        # Display summary
        if [ -f "${SYN_RESULTS}/utilization.rpt" ]; then
            log_info "Resource Utilization:"
            grep -A 10 "Slice Logic Distribution" "${SYN_RESULTS}/utilization.rpt" || true
        fi
        
        if [ -f "${SYN_RESULTS}/timing.rpt" ]; then
            log_info "Timing Summary:"
            grep "WNS" "${SYN_RESULTS}/timing.rpt" || true
        fi
    else
        log_warning "Vivado not found in PATH - generating scripts only"
        log_info "To run synthesis manually:"
        log_info "  vivado -mode batch -source ${SYN_RESULTS}/vivado_synth.tcl"
    fi
}

# Quartus synthesis
synthesize_quartus() {
    log_info "Generating Quartus QSF file..."
    
    cat > "${SYN_RESULTS}/mhx_ternary_ibex.qsf" <<EOF
# Quartus settings file for MHX Ternary Ibex
# Auto-generated

set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE ${FPGA_BOARD}
set_global_assignment -name TOP_LEVEL_ENTITY ibex_top
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY ${SYN_RESULTS}

# Add source files
set_global_assignment -name SYSTEMVERILOG_FILE ${RTL_ROOT}/ibex_pkg.sv
set_global_assignment -name SYSTEMVERILOG_FILE ${RTL_ROOT}/ibex_ternary_alu.sv
set_global_assignment -name SYSTEMVERILOG_FILE ${RTL_ROOT}/ibex_ternary_regfile.sv
set_global_assignment -name SYSTEMVERILOG_FILE ${RTL_ROOT}/ibex_neural_unit.sv
set_global_assignment -name SYSTEMVERILOG_FILE ${RTL_ROOT}/ibex_core.sv
set_global_assignment -name SYSTEMVERILOG_FILE ${RTL_ROOT}/ibex_top.sv

# Timing constraints
create_clock -name clk_i -period [expr {1000.0 / ${TARGET_FREQ}}]

# Optimization settings
set_global_assignment -name OPTIMIZATION_MODE "HIGH PERFORMANCE EFFORT"
set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC ON
set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION ON
EOF

    log_info "Running Quartus synthesis..."
    if command -v quartus_sh &> /dev/null; then
        quartus_sh --flow compile mhx_ternary_ibex \
            > "${SYN_RESULTS}/quartus.log" 2>&1
        log_success "Quartus synthesis completed"
        
        # Display summary
        if [ -f "${SYN_RESULTS}/mhx_ternary_ibex.fit.summary" ]; then
            log_info "Fit Summary:"
            cat "${SYN_RESULTS}/mhx_ternary_ibex.fit.summary"
        fi
    else
        log_warning "Quartus not found in PATH - generating scripts only"
        log_info "To run synthesis manually:"
        log_info "  quartus_sh --flow compile mhx_ternary_ibex"
    fi
}

# Main execution
generate_file_list

case "$FPGA_TOOL" in
    vivado)
        synthesize_vivado
        ;;
    quartus)
        synthesize_quartus
        ;;
    *)
        log_error "Unsupported FPGA tool: $FPGA_TOOL"
        log_error "Supported tools: vivado, quartus"
        exit 1
        ;;
esac

log_info "=========================================="
log_info "Synthesis Summary"
log_info "=========================================="
log_info "Tool: ${FPGA_TOOL}"
log_info "Board: ${FPGA_BOARD}"
log_info "Results directory: ${SYN_RESULTS}"
log_info "=========================================="

if command -v ${FPGA_TOOL} &> /dev/null; then
    log_success "✓ FPGA synthesis completed successfully"
else
    log_warning "⚠ Scripts generated but tool not available"
    log_warning "  Install ${FPGA_TOOL} to run synthesis"
fi

exit 0
