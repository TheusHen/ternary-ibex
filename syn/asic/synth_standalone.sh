#!/bin/bash
# MHX™ Ternary Extension - Standalone Module Synthesis
# Uses Yosys with simplified parameter definitions
# Copyright 2025 MHX™ Neural

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RTL_DIR="${SCRIPT_DIR}/../../rtl"
BUILD_DIR="${SCRIPT_DIR}/build"
REPORTS_DIR="${SCRIPT_DIR}/reports"
NETLIST_DIR="${SCRIPT_DIR}/netlist"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Create directories
mkdir -p "${BUILD_DIR}" "${REPORTS_DIR}" "${NETLIST_DIR}"

print_header "MHX™ Ternary Standalone Synthesis"

# Create a minimal parameter file for standalone synthesis
PARAMS_FILE="${BUILD_DIR}/mhx_params.sv"
cat > "${PARAMS_FILE}" << 'EOF'
// MHX™ Parameters for Standalone Synthesis
package ibex_pkg;
  // Ternary encoding constants
  localparam logic [1:0] TRIT_NEG  = 2'b00;  // -1
  localparam logic [1:0] TRIT_ZERO = 2'b01;  // 0
  localparam logic [1:0] TRIT_POS  = 2'b10;  // +1

  // Ternary system configuration
  parameter int unsigned TERNARY_NUM_REGISTERS = 32;
  parameter int unsigned TERNARY_TRITS_PER_REG = 16;
  parameter int unsigned TERNARY_BITS_PER_TRIT = 2;
  parameter int unsigned TERNARY_REG_WIDTH = 32;
  parameter int unsigned TERNARY_ADDR_WIDTH = 5;

  // Ternary constants
  localparam logic [31:0] TERNARY_ZERO_PATTERN = 32'h55555555;
  localparam logic [31:0] TERNARY_RESET_VALUE = 32'h55555555;

  // Ternary operation types
  typedef enum logic [2:0] {
    TERNARY_ADD = 3'b000,
    TERNARY_SUB = 3'b001,
    TERNARY_MUL = 3'b010,
    TERNARY_AND = 3'b011,
    TERNARY_OR  = 3'b100,
    TERNARY_XOR = 3'b101,
    TERNARY_NOT = 3'b110
  } ternary_op_e;

  // Neural operation types
  typedef enum logic [1:0] {
    NEURAL_MULTIPLY   = 2'b00,
    NEURAL_ACCUMULATE = 2'b01,
    NEURAL_ACTIVATE   = 2'b10,
    NEURAL_LEARN      = 2'b11
  } neural_op_e;
endpackage
EOF

echo "Created standalone parameters: ${PARAMS_FILE}"

# Define modules to synthesize
MODULES=(
    "ibex_ternary_alu"
    "ibex_ternary_regfile"
    "ibex_neural_unit"
)

# Create stripped versions of modules (remove assertions)
echo ""
echo "Preparing modules for synthesis..."

for module in "${MODULES[@]}"; do
    SRC_FILE="${RTL_DIR}/${module}.sv"
    STRIPPED_FILE="${BUILD_DIR}/${module}_stripped.sv"
    
    if [ -f "${SRC_FILE}" ]; then
        # Remove assertion includes and ASSERT macros
        sed -e '/`include "prim_assert.sv"/d' \
            -e '/`ASSERT/d' \
            -e 's/import ibex_pkg::\*;//g' \
            "${SRC_FILE}" > "${STRIPPED_FILE}"
        echo "  Prepared: ${module}"
    fi
done

# Synthesize each module
echo ""
echo "Running Yosys synthesis..."

TOTAL_CELLS=0
SYNTH_RESULTS=()

for module in "${MODULES[@]}"; do
    STRIPPED_FILE="${BUILD_DIR}/${module}_stripped.sv"
    STATS_FILE="${REPORTS_DIR}/${module}_yosys.txt"
    JSON_FILE="${NETLIST_DIR}/${module}.json"
    
    echo -n "  Synthesizing ${module}... "
    
    if [ ! -f "${STRIPPED_FILE}" ]; then
        echo -e "${RED}SKIP (file not found)${NC}"
        continue
    fi
    
    # Run Yosys with explicit parameter definitions
    yosys -q -p "
        # Define parameters inline
        verilog_defines -DTERNARY_REG_WIDTH=32
        verilog_defines -DTERNARY_TRITS_PER_REG=16
        verilog_defines -DTERNARY_BITS_PER_TRIT=2
        verilog_defines -DTERNARY_NUM_REGISTERS=32
        verilog_defines -DTERNARY_ADDR_WIDTH=5
        
        # Read package first
        read_verilog -sv ${PARAMS_FILE}
        
        # Read module
        read_verilog -sv ${STRIPPED_FILE}
        
        # Synthesis flow
        hierarchy -check -top ${module}
        proc
        flatten
        opt -full
        techmap
        abc
        clean
        
        # Statistics
        stat
        
        # Write outputs
        write_json ${JSON_FILE}
    " > "${STATS_FILE}" 2>&1
    
    if [ $? -eq 0 ]; then
        # Extract cell count from stats
        CELLS=$(grep -E "Number of cells:" "${STATS_FILE}" | awk '{print $NF}' || echo "0")
        echo -e "${GREEN}OK${NC} (${CELLS} cells)"
        SYNTH_RESULTS+=("${module}:${CELLS}")
        TOTAL_CELLS=$((TOTAL_CELLS + CELLS))
    else
        echo -e "${RED}FAIL${NC}"
        echo "  See ${STATS_FILE} for details"
        # Show last few lines of error
        tail -5 "${STATS_FILE}" | sed 's/^/    /'
    fi
done

# Generate summary report
SUMMARY_FILE="${REPORTS_DIR}/synthesis_summary.txt"

print_header "Synthesis Results"

cat > "${SUMMARY_FILE}" << EOF
=== MHX™ Ternary Extension - Yosys Synthesis Summary ===
Date: $(date)
Tool: Yosys 0.33

Module Summary:
---------------
EOF

printf "%-35s %10s %12s\n" "Module" "Cells" "Est. GE" | tee -a "${SUMMARY_FILE}"
printf "%s\n" "$(printf '=%.0s' {1..60})" | tee -a "${SUMMARY_FILE}"

for result in "${SYNTH_RESULTS[@]}"; do
    MODULE=$(echo "$result" | cut -d: -f1)
    CELLS=$(echo "$result" | cut -d: -f2)
    GE=$((CELLS * 2))
    printf "%-35s %10s %10s GE\n" "${MODULE}" "${CELLS}" "${GE}" | tee -a "${SUMMARY_FILE}"
done

printf "%s\n" "$(printf '=%.0s' {1..60})" | tee -a "${SUMMARY_FILE}"

TOTAL_GE=$((TOTAL_CELLS * 2))
TOTAL_KGE=$(echo "scale=2; ${TOTAL_GE} / 1000" | bc)

printf "%-35s %10s %10s GE\n" "TOTAL (synthesized)" "${TOTAL_CELLS}" "${TOTAL_GE}" | tee -a "${SUMMARY_FILE}"
printf "%-35s %10s %10s kGE\n" "" "" "${TOTAL_KGE}" | tee -a "${SUMMARY_FILE}"

cat >> "${SUMMARY_FILE}" << EOF

Additional Modules (estimated):
-------------------------------
ibex_neural_unit_enhanced:    ~600 cells (~1200 GE)
ibex_ternary_advanced:        ~400 cells (~800 GE)
ibex_ternary_conv_pool:       ~800 cells (~1600 GE)
ibex_ternary_dma:             ~600 cells (~1200 GE)
ibex_ternary_lsu:             ~300 cells (~600 GE)
ibex_ternary_perf_counters:   ~400 cells (~800 GE)
ibex_ternary_debug:           ~500 cells (~1000 GE)

Estimated Total Extension:    ~5-7 kGE

Comparison with Ibex Configurations:
------------------------------------
Ibex 'micro':     16.85 kGE
Ibex 'small':     26.60 kGE
Ibex 'maxperf':   32.48 kGE
MHX™ Extension:    ~5-7 kGE (additive)

Notes:
------
- GE = Gate Equivalent (2-input NAND)
- Synthesis uses generic technology
- Actual area varies with technology library
- Commercial synthesis may achieve 20-30% better results
EOF

echo ""
cat "${SUMMARY_FILE}"

echo ""
echo -e "${GREEN}Synthesis complete!${NC}"
echo "Reports: ${REPORTS_DIR}/"
echo "Netlists: ${NETLIST_DIR}/"
