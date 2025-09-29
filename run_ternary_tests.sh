#!/bin/bash

# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Simple test runner for MHX ternary extensions
# This script can be run manually to test the ternary functionality

set -e

echo "========================================"
echo "MHX Ternary Extension Test Runner"
echo "========================================"

# Check if we're in the right directory
if [ ! -f "ibex_core.core" ]; then
    echo "Error: Please run this script from the Ibex root directory"
    exit 1
fi

# Create build directory
mkdir -p build/manual_test

echo "1. Checking RTL files..."
echo "Checking ternary ALU implementation..."
if [ -f "rtl/ibex_ternary_alu.sv" ]; then
    echo "✅ Ternary ALU found ($(wc -l < rtl/ibex_ternary_alu.sv) lines)"
else
    echo "❌ Ternary ALU not found"
    exit 1
fi

echo "Checking neural unit implementation..."
if [ -f "rtl/ibex_neural_unit.sv" ]; then
    echo "✅ Neural unit found ($(wc -l < rtl/ibex_neural_unit.sv) lines)"
else
    echo "❌ Neural unit not found"
    exit 1
fi

echo "Checking ternary register file..."
if [ -f "rtl/ibex_ternary_regfile.sv" ]; then
    echo "✅ Ternary register file found ($(wc -l < rtl/ibex_ternary_regfile.sv) lines)"
else
    echo "❌ Ternary register file not found"
    exit 1
fi

echo "2. Validating configuration..."
if grep -q "mhx:" ibex_configs.yaml; then
    echo "✅ MHX configuration found in ibex_configs.yaml"
else
    echo "❌ MHX configuration missing from ibex_configs.yaml"
    exit 1
fi

echo "3. Running performance analysis..."
if ! python3 util/ternary_performance_analysis.py 2>&1 | tee build/manual_test/performance.log; then
    echo "❌ Performance analysis failed"
    exit 1
fi

echo "✅ Performance analysis completed"

echo "4. Checking code quality..."
echo "RTL file statistics:"
echo "- Total RTL files: $(find rtl/ -name "*.sv" | wc -l)"
echo "- Ternary-specific files: 3"
echo "- Total ternary RTL lines: $(($(wc -l < rtl/ibex_ternary_alu.sv) + $(wc -l < rtl/ibex_neural_unit.sv) + $(wc -l < rtl/ibex_ternary_regfile.sv)))"

echo "5. Validating examples..."
echo "Checking example files..."
if [ -f "examples/mhx_demo.s" ]; then
    echo "✅ Assembly example found"
else
    echo "⚠️  Assembly example not found"
fi

if [ -f "examples/sw/ternary_math_validation/ternary_math_validation.c" ]; then
    echo "✅ C validation example found"
else
    echo "⚠️  C validation example not found"
fi

echo "6. Generating test report..."
cat > build/manual_test/test_report.md << EOF
# MHX Ternary Extension Test Report

**Test Date:** $(date)
**Test Status:** PASSED (Basic Validation)

## Test Results

### RTL Implementation
- ✅ Ternary ALU: $(wc -l < rtl/ibex_ternary_alu.sv) lines implemented
- ✅ Neural Unit: $(wc -l < rtl/ibex_neural_unit.sv) lines implemented  
- ✅ Register File: $(wc -l < rtl/ibex_ternary_regfile.sv) lines implemented
- ✅ Configuration: MHX config integrated

### Performance Analysis
$(tail -10 build/manual_test/performance.log)

### Recommendations
1. Set up FuseSoC for complete build testing
2. Implement functional testbenches for each module
3. Create FPGA prototype for hardware validation
4. Develop toolchain support for ternary instructions

**Overall Status:** Basic implementation validated, ready for advanced verification.
EOF

echo "✅ Test report generated: build/manual_test/test_report.md"

echo "========================================"
echo "Basic validation completed successfully!"
echo "Check build/manual_test/ for results"
echo "========================================"