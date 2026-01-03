#!/bin/bash
# MHX™ Ternary Extension Linting Script
# Copyright 2025 MHX™ Neural
# SPDX-License-Identifier: Apache-2.0

set -e

echo "========================================"
echo "MHX™ Ternary Extension Verilator Linting"
echo "========================================"

# Define include paths for prim_assert and ibex_pkg
INCLUDE_PATHS=(
    "-I./rtl"
    "-I./vendor/lowrisc_ip/ip/prim/rtl"
    "-I./vendor/lowrisc_ip/dv/sv/dv_utils"
)

# Define ternary RTL files in dependency order
TERNARY_FILES=(
    "rtl/ibex_ternary_alu.sv"
    "rtl/ibex_ternary_regfile.sv"
    "rtl/ibex_ternary_advanced.sv"
    "rtl/ibex_neural_unit.sv"
    "rtl/ibex_neural_unit_enhanced.sv"
    "rtl/ibex_ternary_perf_counters.sv"
    "rtl/ibex_ternary_dma.sv"
    "rtl/ibex_ternary_lsu.sv"
    "rtl/ibex_ternary_conv_pool.sv"
    "rtl/ibex_ternary_debug.sv"
)

# Check if Verilator is installed
if ! command -v verilator &> /dev/null; then
    echo "⚠️  Verilator not found. Installing..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y verilator
    else
        echo "❌ Cannot install Verilator. Please install manually:"
        echo "   sudo apt-get install verilator"
        exit 1
    fi
fi

echo ""
echo "Verilator version:"
verilator --version
echo ""

# Run lint on each ternary module with ibex_pkg
ERRORS=0
PASSED=0

for file in "${TERNARY_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -n "Linting $file... "
        # Run verilator with ibex_pkg first, then the module
        # Temporarily disable exit-on-error for grep check
        set +e
        LINT_OUTPUT=$(verilator --lint-only \
            -Wall \
            -Wno-DECLFILENAME \
            -Wno-UNUSED \
            -Wno-UNOPTFLAT \
            -Wno-WIDTH \
            "${INCLUDE_PATHS[@]}" \
            rtl/ibex_pkg.sv \
            "$file" 2>&1)
        echo "$LINT_OUTPUT" | grep -q "%Error"
        HAS_ERROR=$?
        if [ $HAS_ERROR -eq 0 ]; then
            echo "❌ FAIL"
            echo "$LINT_OUTPUT" | head -30
            ERRORS=$((ERRORS + 1))
        else
            echo "✅ PASS"
            PASSED=$((PASSED + 1))
        fi
        set -e
    else
        echo "❌ File not found: $file"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "========================================"
echo "Lint Summary"
echo "========================================"
echo "✅ Passed: $PASSED"
echo "❌ Failed: $ERRORS"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo "🎉 All ternary modules passed lint checks!"
    exit 0
else
    echo "⚠️  Some modules have errors. Review above for details."
    exit 1
fi
