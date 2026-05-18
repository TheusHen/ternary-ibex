#!/bin/bash
# MHX™ Ternary Extension - Run All Formal Verification
# Copyright 2025 MHX™ Neural

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create results directory
mkdir -p "${RESULTS_DIR}"

echo "========================================"
echo "MHX™ Ternary Formal Verification Suite"
echo "========================================"
echo ""

# Check for SymbiYosys
if ! command -v sby &> /dev/null; then
    echo -e "${YELLOW}Warning: SymbiYosys (sby) not found${NC}"
    echo "Install with: pip install sby"
    echo "Or use OSS CAD Suite: https://github.com/YosysHQ/oss-cad-suite-build"
    echo ""
    echo "Running in dry-run mode (checking file structure only)..."
    DRY_RUN=1
else
    DRY_RUN=0
fi

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

run_verification() {
    local name=$1
    local dir=$2
    local task=$3

    echo -n "Running ${name} [${task}]... "

    if [ "$DRY_RUN" -eq 1 ]; then
        if [ -f "${dir}/${name}.sby" ] && [ -f "${dir}/${name}_formal.sv" ]; then
            echo -e "${YELLOW}SKIPPED (dry-run)${NC}"
            (( SKIP_COUNT += 1 ))
        else
            echo -e "${RED}FAIL (missing files)${NC}"
            (( FAIL_COUNT += 1 ))
        fi
        return
    fi

    cd "${dir}"
    if sby -f "${name}.sby" "${task}" > "${RESULTS_DIR}/${name}_${task}.log" 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        (( PASS_COUNT += 1 ))
    else
        echo -e "${RED}FAIL${NC}"
        echo "  See ${RESULTS_DIR}/${name}_${task}.log for details"
        (( FAIL_COUNT += 1 ))
    fi
    cd "${SCRIPT_DIR}"
}

# Verify file structure first
echo "Checking file structure..."
for module in ternary_alu neural_unit ternary_regfile; do
    if [ -f "${SCRIPT_DIR}/${module}/${module}.sby" ]; then
        echo "  ✓ ${module}/${module}.sby"
    else
        echo "  ✗ ${module}/${module}.sby (missing)"
    fi
    if [ -f "${SCRIPT_DIR}/${module}/${module}_formal.sv" ]; then
        echo "  ✓ ${module}/${module}_formal.sv"
    else
        echo "  ✗ ${module}/${module}_formal.sv (missing)"
    fi
done
echo ""

# Run verification for each module
echo "Running formal verification..."
echo ""

# Ternary ALU
echo "=== Ternary ALU ==="
run_verification "ternary_alu" "${SCRIPT_DIR}/ternary_alu" "prove"
run_verification "ternary_alu" "${SCRIPT_DIR}/ternary_alu" "cover"

# Neural Unit
echo ""
echo "=== Neural Unit ==="
run_verification "neural_unit" "${SCRIPT_DIR}/neural_unit" "prove"
run_verification "neural_unit" "${SCRIPT_DIR}/neural_unit" "cover"

# Ternary Register File
echo ""
echo "=== Ternary Register File ==="
run_verification "ternary_regfile" "${SCRIPT_DIR}/ternary_regfile" "prove"
run_verification "ternary_regfile" "${SCRIPT_DIR}/ternary_regfile" "cover"

# Summary
echo ""
echo "========================================"
echo "Formal Verification Summary"
echo "========================================"
echo -e "Passed:  ${GREEN}${PASS_COUNT}${NC}"
echo -e "Failed:  ${RED}${FAIL_COUNT}${NC}"
echo -e "Skipped: ${YELLOW}${SKIP_COUNT}${NC}"
echo ""

if [ "$FAIL_COUNT" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    echo -e "${GREEN}All formal verification tasks passed!${NC}"
    exit 0
elif [ "$DRY_RUN" -eq 1 ]; then
    echo -e "${RED}Dry-run did not execute proofs. Install SymbiYosys before reporting success.${NC}"
    exit 2
else
    echo -e "${RED}Some verification tasks failed.${NC}"
    exit 1
fi
