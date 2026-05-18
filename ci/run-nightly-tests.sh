#!/usr/bin/env bash
# Copyright lowRISC contributors.
# Copyright 2025 MHX™ Neural.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

################################################################################
# Nightly Regression Test Suite for MHX™ Ternary Extensions
#
# This script runs extensive regression tests overnight including:
# - Full UVM test suite with all configurations
# - Fault injection tests
# - Formal verification
# - Performance benchmarks
# - Coverage analysis
#
# Designed to run unattended with email notifications on failure.
#
# Usage:
#   ./ci/run-nightly-tests.sh [--email EMAIL]
################################################################################

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RESULTS_DIR="${REPO_ROOT}/nightly_results_$(date +%Y%m%d_%H%M%S)"
EMAIL_TO="${EMAIL_TO:-}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "${RESULTS_DIR}/nightly.log"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "${RESULTS_DIR}/nightly.log"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "${RESULTS_DIR}/nightly.log"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --email)
            EMAIL_TO="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--email EMAIL]"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create results directory
mkdir -p "$RESULTS_DIR"

START_TIME=$(date +%s)

log_info "============================================================"
log_info "MHX™ Ternary Ibex Nightly Regression Suite"
log_info "============================================================"
log_info "Start time: $(date)"
log_info "Results directory: $RESULTS_DIR"
log_info "============================================================"

# Track test results
declare -A test_results
total_tests=0
passed_tests=0
failed_tests=0

# Helper function to run a test
run_test() {
    local test_name=$1
    shift
    local -a test_cmd=("$@")

    log_info "Running: $test_name"
    ((total_tests++))

    if "${test_cmd[@]}" > "${RESULTS_DIR}/${test_name}.log" 2>&1; then
        log_success "$test_name: PASSED"
        test_results["$test_name"]="PASSED"
        ((passed_tests++))
        return 0
    else
        log_error "$test_name: FAILED"
        test_results["$test_name"]="FAILED"
        ((failed_tests++))
        return 1
    fi
}

# Test 1: Lint checks
run_test "lint_checks" make -C "${REPO_ROOT}" lint

# Test 2: Basic simulation tests
run_test "basic_sim" make -C "${REPO_ROOT}/dv" run TEST=mhx_ternary_test

# Test 3: UVM regression suite
run_test "uvm_regression" make -C "${REPO_ROOT}/dv/uvm" regression

# Test 4: Fault injection tests
run_test "fault_injection" make -C "${REPO_ROOT}/dv" run TEST=mhx_ternary_fault_injection_tb

# Test 5: Directed coverage tests
run_test "directed_coverage" make -C "${REPO_ROOT}/dv/uvm" run TEST=mhx_coverage_closure_test

# Test 6: Formal verification
run_test "formal_verification" "${SCRIPT_DIR}/run-formal-verification.sh"

# Test 7: Performance benchmarks
run_test "performance_bench" "${SCRIPT_DIR}/validate-performance.sh"

# Test 8: Coverage analysis
run_test "coverage_analysis" make -C "${REPO_ROOT}/dv/uvm" coverage_report

# Test 9: Long-running stress tests (8 hours)
log_info "Running extended stress tests (this will take several hours)..."
run_test "stress_test_8hr" timeout 8h make -C "${REPO_ROOT}/dv/uvm" stress_test

# Generate summary report
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DURATION_HOURS=$((DURATION / 3600))
DURATION_MINS=$(( (DURATION % 3600) / 60 ))

cat > "${RESULTS_DIR}/summary.txt" <<EOF
========================================
MHX™ Ternary Ibex Nightly Regression
========================================
Date: $(date)
Duration: ${DURATION_HOURS}h ${DURATION_MINS}m

Test Results:
-------------
Total tests: $total_tests
Passed: $passed_tests
Failed: $failed_tests

Individual Test Results:
------------------------
EOF

for test_name in "${!test_results[@]}"; do
    echo "$test_name: ${test_results[$test_name]}" >> "${RESULTS_DIR}/summary.txt"
done

cat >> "${RESULTS_DIR}/summary.txt" <<EOF

Logs Location: $RESULTS_DIR

========================================
EOF

cat "${RESULTS_DIR}/summary.txt"

# Send email notification if configured
if [ -n "$EMAIL_TO" ]; then
    if [ $failed_tests -eq 0 ]; then
        SUBJECT="✓ MHX™ Nightly Tests PASSED"
    else
        SUBJECT="✗ MHX™ Nightly Tests FAILED ($failed_tests failures)"
    fi
    
    if command -v mail &> /dev/null; then
        mail -s "$SUBJECT" "$EMAIL_TO" < "${RESULTS_DIR}/summary.txt"
        log_info "Email notification sent to $EMAIL_TO"
    else
        log_error "mail command not found, skipping email notification"
    fi
fi

log_info "============================================================"
if [ $failed_tests -eq 0 ]; then
    log_success "✓ All nightly tests PASSED"
    exit 0
else
    log_error "✗ $failed_tests test(s) FAILED"
    exit 1
fi
