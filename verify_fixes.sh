#!/bin/bash
# Quick verification script for MHX Ternary Core fixes
# Usage: ./verify_fixes.sh

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           MHX Ternary Core - Verification Script              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for passed/failed tests
PASSED=0
FAILED=0

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASSED${NC}: $2"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAILED${NC}: $2"
        ((FAILED++))
    fi
}

echo "1️⃣  Checking file endings (POSIX compliance)..."
if [ -z "$(tail -c 1 dv/uvm/mhx_ternary_coverage.sv)" ]; then
    print_result 0 "mhx_ternary_coverage.sv ends with newline"
else
    print_result 1 "mhx_ternary_coverage.sv missing newline"
fi
echo ""

echo "2️⃣  Checking if floorplan exists..."
if [ -f "docs/images/mhx_floorplan.png" ]; then
    SIZE=$(stat -c%s "docs/images/mhx_floorplan.png" 2>/dev/null || stat -f%z "docs/images/mhx_floorplan.png" 2>/dev/null)
    if [ "$SIZE" -gt 100000 ]; then
        print_result 0 "Floorplan exists and has reasonable size (${SIZE} bytes)"
    else
        print_result 1 "Floorplan exists but is too small (${SIZE} bytes)"
    fi
else
    print_result 1 "Floorplan not found"
fi
echo ""

echo "3️⃣  Checking lint waiver file..."
if grep -q "MHX Ternary Extension waivers" lint/verilator_waiver.vlt; then
    print_result 0 "Lint waivers properly configured"
else
    print_result 1 "Lint waivers missing MHX section"
fi
echo ""

echo "4️⃣  Checking workflow file..."
if [ -f ".github/workflows/floorplan-generation.yml" ]; then
    print_result 0 "Floorplan generation workflow exists"
else
    print_result 1 "Floorplan generation workflow missing"
fi
echo ""

echo "5️⃣  Checking for lint_off directives in RTL..."
LINT_OFF_COUNT=0
for file in rtl/ibex_ternary_alu.sv rtl/ibex_neural_unit.sv rtl/ibex_core.sv; do
    if grep -q "verilator lint_off" "$file"; then
        ((LINT_OFF_COUNT++))
    fi
done

if [ $LINT_OFF_COUNT -eq 3 ]; then
    print_result 0 "All RTL files have proper lint directives"
else
    print_result 1 "Some RTL files missing lint directives ($LINT_OFF_COUNT/3)"
fi
echo ""

echo "6️⃣  Running Verilator lint check (this may take a moment)..."
echo -n "   "
if fusesoc --cores-root . run --target=lint --tool=verilator lowrisc:ibex:ibex_top_tracing \
    --RV32E=0 --RV32M=ibex_pkg::RV32MFast --RV32B=ibex_pkg::RV32BNone \
    --RegFile=ibex_pkg::RegFileFF --BranchTargetALU=0 --WritebackStage=0 \
    --ICache=0 --ICacheECC=0 --ICacheScramble=0 --BranchPredictor=0 \
    --DbgTriggerEn=0 --SecureIbex=0 --PMPEnable=0 --PMPGranularity=0 \
    --PMPNumRegions=4 --MHPMCounterNum=0 --MHPMCounterWidth=40 > /tmp/lint_output.log 2>&1; then
    print_result 0 "Verilator lint completed successfully"
else
    echo ""
    echo -e "${YELLOW}   Last 20 lines of lint output:${NC}"
    tail -20 /tmp/lint_output.log | sed 's/^/   /'
    print_result 1 "Verilator lint failed"
fi
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                         SUMMARY                                ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo -e "║  ${GREEN}Passed:${NC} $PASSED                                                  ║"
echo -e "║  ${RED}Failed:${NC} $FAILED                                                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All checks passed! Ready to commit and push.${NC}"
    echo ""
    echo "Suggested next steps:"
    echo "  1. git add -A"
    echo "  2. git commit -m 'Fix all lint errors and add floorplan workflow'"
    echo "  3. git push"
    exit 0
else
    echo -e "${RED}⚠️  Some checks failed. Please review the errors above.${NC}"
    exit 1
fi
