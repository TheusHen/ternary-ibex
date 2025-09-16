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

echo "1. Building ternary testbench..."
if ! fusesoc --cores-root . run --target=sim --tool=verilator --build lowrisc:ibex:mhx_ternary_test 2>&1 | tee build/manual_test/build.log; then
    echo "❌ Build failed - check build/manual_test/build.log"
    exit 1
fi

echo "✅ Build successful"

echo "2. Running ternary testbench..."
if [ -d "build/lowrisc_ibex_mhx_ternary_test_0.1/sim-verilator" ]; then
    cd build/lowrisc_ibex_mhx_ternary_test_0.1/sim-verilator
    if ! ./Vmhx_ternary_test 2>&1 | tee ../../manual_test/test.log; then
        echo "❌ Test execution failed"
        cd ../../../
        exit 1
    fi
    cd ../../../
else
    echo "❌ Testbench binary not found"
    exit 1
fi

echo "✅ Tests completed"

echo "3. Building validation programs..."
if ! make -C examples/sw/ternary_math_validation 2>&1 | tee -a build/manual_test/build.log; then
    echo "⚠️  Math validation build failed (expected if toolchain not available)"
else
    echo "✅ Math validation built"
fi

if ! make -C examples/sw/ternary_performance_bench 2>&1 | tee -a build/manual_test/build.log; then
    echo "⚠️  Performance benchmark build failed (expected if toolchain not available)"
else
    echo "✅ Performance benchmark built"
fi

echo "4. Generating test report..."
if ! python3 util/generate_ternary_report.py --test-results build/ --output build/manual_test/test_report.md; then
    echo "⚠️  Report generation failed"
else
    echo "✅ Test report generated: build/manual_test/test_report.md"
fi

echo "========================================"
echo "Manual test run completed!"
echo "Check build/manual_test/ for results"
echo "========================================"