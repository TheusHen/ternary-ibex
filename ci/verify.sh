#!/usr/bin/env bash
# Unified verification entrypoint (local + CI)
# Runs: tool version checks, RTL lint, core tests, mypy, benchmark data generation, pytest.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

fail() {
  echo "[verify] ERROR: $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

echo "[verify] Checking tool versions..."

# Minimum Python version (keep conservative for CI runners)
python3 - <<'PY'
import sys
min_ver = (3, 10)
if sys.version_info < min_ver:
    raise SystemExit(f"Python >= {min_ver[0]}.{min_ver[1]} required, found {sys.version.split()[0]}")
print(f"[verify] Python OK: {sys.version.split()[0]}")
PY

need_cmd python3
need_cmd verilator

# Uses tool_requirements.py as the single source of truth
python3 util/check_tool_requirements.py verilator

echo "[verify] RTL lint..."
./lint_ternary.sh

echo "[verify] Core regression tests..."
# Ensure the JSON indicates pass as well as return code.
python3 - <<'PY'
import json, subprocess, sys
p = subprocess.run(["./run_ternary_tests.sh", "--json"], check=True, stdout=subprocess.PIPE, text=True)
try:
    data = json.loads(p.stdout)
except json.JSONDecodeError as e:
    print(p.stdout)
    raise SystemExit(f"run_ternary_tests.sh did not output valid JSON: {e}")
status = str(data.get("test_status", "")).upper()
if status != "PASSED":
    raise SystemExit(f"Test status not PASSED: {status}")
print(f"[verify] test_status={status}")
PY

echo "[verify] Python typecheck (mypy)..."
need_cmd mypy
mypy util/generate_benchmark_data.py util/mlperftiny_benchmark.py util/trace_analysis.py --ignore-missing-imports

echo "[verify] Benchmark data generation (all formats)..."
python3 util/generate_benchmark_data.py --output "${REPO_ROOT}/build/benchmark_data_verify" --format all >/dev/null

echo "[verify] Pytest regression suite..."
need_cmd pytest
pytest -q tests

echo "[verify] ✅ All checks passed."
