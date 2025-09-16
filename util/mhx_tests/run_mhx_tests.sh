#!/bin/bash

# Copyright lowRISC contributors.
# Copyright 2025 MHX Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# MHX Neural T1 Test Runner Script
# Simple shell script to run MHX tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "========================================"
echo "MHX Neural T1 Implementation Test Runner"
echo "========================================"
echo "Repository: $REPO_ROOT"
echo ""

# Check if we're in the right directory
if [ ! -f "$REPO_ROOT/ibex_core.core" ]; then
    echo "Error: Please run this script from the Ibex root directory or check paths"
    exit 1
fi

# Parse command line arguments
TEST_SUITE="${1:-all}"
VERBOSE="${2:-false}"

case "$TEST_SUITE" in
    "lint"|"build"|"sim"|"fpga"|"all")
        echo "Running test suite: $TEST_SUITE"
        ;;
    *)
        echo "Usage: $0 [lint|build|sim|fpga|all] [verbose]"
        echo ""
        echo "Test Suites:"
        echo "  lint  - Run code quality checks"
        echo "  build - Run build tests"
        echo "  sim   - Run simulation tests"
        echo "  fpga  - Run FPGA validation"
        echo "  all   - Run all tests (default)"
        exit 1
        ;;
esac

# Run Python test runner
if command -v python3 >/dev/null 2>&1; then
    echo "Using Python test runner..."
    python3 "$SCRIPT_DIR/mhx_test_runner.py" --repo-root "$REPO_ROOT" --test-suite "$TEST_SUITE"
else
    echo "Python3 not available, running basic shell tests..."
    
    # Basic shell-based testing
    cd "$REPO_ROOT"
    
    case "$TEST_SUITE" in
        "lint"|"all")
            echo "=== Basic Lint Check ==="
            if command -v fusesoc >/dev/null 2>&1; then
                echo "Checking FuseSoC core registration..."
                fusesoc --cores-root . core list | grep -E "(mhx|MHX)" || echo "MHX cores not found"
                echo "✓ FuseSoC check completed"
            else
                echo "⚠️ FuseSoC not available"
            fi
            ;;
    esac
    
    case "$TEST_SUITE" in
        "fpga"|"all")
            echo "=== Basic FPGA File Check ==="
            required_files=(
                "syn/fpga/common/mhx_fpga_top.sv"
                "syn/fpga/arty_a7/build_arty_a7.tcl"
                "syn/fpga/basys3/build_basys3.tcl"
                "syn/fpga/build_fpga.sh"
            )
            
            missing_files=0
            for file in "${required_files[@]}"; do
                if [ -f "$file" ]; then
                    echo "✓ Found: $file"
                else
                    echo "❌ Missing: $file"
                    missing_files=$((missing_files + 1))
                fi
            done
            
            if [ $missing_files -eq 0 ]; then
                echo "✅ All FPGA files present"
            else
                echo "❌ $missing_files FPGA files missing"
                exit 1
            fi
            ;;
    esac
    
    echo "✅ Basic tests completed"
fi

echo ""
echo "========================================"
echo "MHX Neural T1 Tests Completed"
echo "========================================"