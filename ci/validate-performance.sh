#!/bin/bash

# MHX Ternary Ibex Performance Validation Script
# Validates that ternary operations meet performance requirements

set -euo pipefail

# Configuration
WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS_DIR="${WORKSPACE_ROOT}/build/performance_results"
BASELINE_FILE="${WORKSPACE_ROOT}/ci/performance_baseline.json"
THRESHOLD_REGRESSION=5  # Maximum allowed regression percentage

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Create results directory
mkdir -p "${RESULTS_DIR}"

# Check if baseline exists
if [[ ! -f "${BASELINE_FILE}" ]]; then
  log_warn "No performance baseline found. Creating initial baseline..."
  cat > "${BASELINE_FILE}" << 'EOF'
{
  "neural_inference_speedup": 1.37,
  "matrix_operation_speedup": 1.59,
  "memory_usage_reduction": 93.8,
  "power_reduction_estimate": 70.0,
  "efficiency_score": 129.6
}
EOF
  log_info "Created baseline file: ${BASELINE_FILE}"
fi

# Run ternary performance tests
log_info "Running ternary performance validation..."

cd "${WORKSPACE_ROOT}"

# Check if test runner exists
if [[ ! -f "./run_ternary_tests.sh" ]]; then
  log_error "Ternary test runner not found: ./run_ternary_tests.sh"
  exit 1
fi

# Run the tests and capture performance metrics
log_info "Executing ternary tests..."
if ! ./run_ternary_tests.sh --json > "${RESULTS_DIR}/current_results.json" 2>&1; then
  log_error "Ternary tests failed"
  exit 1
fi

# Parse current results
if [[ ! -f "${RESULTS_DIR}/current_results.json" ]]; then
  log_error "Test results file not found"
  exit 1
fi

# Robust JSON parsing for performance metrics via Python to avoid bc/sed pitfalls
extract_metric() {
  local file="$1"
  local metric="$2"
  python3 - "$file" "$metric" <<'PY'
import json,sys
path, key = sys.argv[1], sys.argv[2]
try:
  with open(path) as f:
    data = json.load(f)
except Exception:
  print(0)
  sys.exit(0)
# Support variant keys from older/newer producers
aliases = {
  'memory_usage_reduction_percent': ['memory_usage_reduction_percent','memory_usage_reduction'],
  'power_efficiency_improvement_percent': ['power_efficiency_improvement_percent','power_reduction_estimate'],
  'overall_score': ['overall_score','efficiency_score'],
  'neural_inference_speedup': ['neural_inference_speedup'],
  'matrix_operation_speedup': ['matrix_operation_speedup'],
}
for k in aliases.get(key,[key]):
  if k in data:
    try:
      print(float(data[k]))
      break
    except Exception:
      print(0)
      break
else:
  print(0)
PY
}

# Load baseline metrics
baseline_neural=$(extract_metric "${BASELINE_FILE}" "neural_inference_speedup")
baseline_matrix=$(extract_metric "${BASELINE_FILE}" "matrix_operation_speedup")
baseline_memory=$(extract_metric "${BASELINE_FILE}" "memory_usage_reduction")
baseline_power=$(extract_metric "${BASELINE_FILE}" "power_reduction_estimate")
baseline_efficiency=$(extract_metric "${BASELINE_FILE}" "efficiency_score")

# Load current metrics
current_neural=$(extract_metric "${RESULTS_DIR}/current_results.json" "neural_inference_speedup")
current_matrix=$(extract_metric "${RESULTS_DIR}/current_results.json" "matrix_operation_speedup")
current_memory=$(extract_metric "${RESULTS_DIR}/current_results.json" "memory_usage_reduction")
current_power=$(extract_metric "${RESULTS_DIR}/current_results.json" "power_reduction_estimate")
current_efficiency=$(extract_metric "${RESULTS_DIR}/current_results.json" "efficiency_score")

# Validation function
validate_metric() {
  local name="$1"
  local baseline="$2"
  local current="$3"
  local threshold="$4"
  
  python3 - "$name" "$baseline" "$current" "$threshold" <<'PY'
import sys
name, b, c, thr = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])
if b == 0:
    print("SKIP")
    sys.exit(0)
reg = ((b - c) / b) * 100.0  # Positive = regression (current worse), Negative = improvement
if reg > thr:
  print(f"FAIL {reg:.2f}")
  sys.exit(1)
else:
  print(f"OK {reg:.2f}")
  sys.exit(0)
PY
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    log_error "${name}: Regression exceeds threshold (${threshold}%). Baseline=${baseline}, Current=${current}"
    return 1
  else
    log_info "${name}: Within threshold. Baseline=${baseline}, Current=${current}"
    return 0
  fi
}

# Validate all metrics
validation_passed=true

log_info "Validating performance metrics against baseline..."

if ! validate_metric "Neural Inference Speedup" "$baseline_neural" "$current_neural" "$THRESHOLD_REGRESSION"; then
  validation_passed=false
fi

if ! validate_metric "Matrix Operation Speedup" "$baseline_matrix" "$current_matrix" "$THRESHOLD_REGRESSION"; then
  validation_passed=false
fi

if ! validate_metric "Memory Usage Reduction" "$baseline_memory" "$current_memory" "$THRESHOLD_REGRESSION"; then
  validation_passed=false
fi

if ! validate_metric "Power Reduction Estimate" "$baseline_power" "$current_power" "$THRESHOLD_REGRESSION"; then
  validation_passed=false
fi

if ! validate_metric "Efficiency Score" "$baseline_efficiency" "$current_efficiency" "$THRESHOLD_REGRESSION"; then
  validation_passed=false
fi

# Generate summary report
cat > "${RESULTS_DIR}/performance_report.txt" << EOF
MHX Ternary Ibex Performance Validation Report
Generated: $(date)

Metrics Comparison:
==================
Neural Inference Speedup:    ${baseline_neural} -> ${current_neural}
Matrix Operation Speedup:    ${baseline_matrix} -> ${current_matrix}
Memory Usage Reduction:      ${baseline_memory}% -> ${current_memory}%
Power Reduction Estimate:    ${baseline_power}% -> ${current_power}%
Efficiency Score:            ${baseline_efficiency} -> ${current_efficiency}

Validation Result: $(if $validation_passed; then echo "PASS"; else echo "FAIL"; fi)
Regression Threshold: ${THRESHOLD_REGRESSION}%
EOF

log_info "Performance report generated: ${RESULTS_DIR}/performance_report.txt"

if $validation_passed; then
  log_info "✅ All performance metrics validated successfully"
  exit 0
else
  log_error "❌ Performance validation failed"
  exit 1
fi