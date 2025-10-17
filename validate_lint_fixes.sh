#!/bin/bash
# Validation script for lint fixes
# Verifies that all linting issues have been resolved

set +e

echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║     MHX Ternary Core - Lint Fixes Validation Script              ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counter
PASSED=0
FAILED=0

print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASSED${NC}: $2"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAILED${NC}: $2"
        ((FAILED++))
    fi
}

echo -e "${BLUE}Test 1: Checking for trailing spaces${NC}"
TRAILING_SPACES=0
for file in rtl/ibex_pkg.sv rtl/ibex_ternary_*.sv rtl/ibex_neural_unit.sv rtl/ibex_core.sv; do
    if [ -f "$file" ]; then
        COUNT=$(grep '[[:space:]]$' "$file" 2>/dev/null | wc -l || echo 0)
        if [ "$COUNT" -gt 0 ]; then
            echo "  Found $COUNT trailing spaces in $file"
            TRAILING_SPACES=$((TRAILING_SPACES + COUNT))
        fi
    fi
done

if [ $TRAILING_SPACES -eq 0 ]; then
    print_result 0 "No trailing spaces found in RTL files"
else
    print_result 1 "Found $TRAILING_SPACES trailing spaces in RTL files"
fi
echo ""

echo -e "${BLUE}Test 2: Checking line lengths (max 100 chars)${NC}"
LONG_LINES=0
for file in rtl/ibex_pkg.sv rtl/ibex_ternary_*.sv rtl/ibex_neural_unit.sv rtl/ibex_core.sv; do
    if [ -f "$file" ]; then
        COUNT=$(awk 'length > 100' "$file" | wc -l)
        if [ "$COUNT" -gt 0 ]; then
            echo "  Found $COUNT long lines in $file"
            LONG_LINES=$((LONG_LINES + COUNT))
        fi
    fi
done

if [ $LONG_LINES -eq 0 ]; then
    print_result 0 "All lines are 100 characters or less"
else
    print_result 1 "Found $LONG_LINES lines exceeding 100 characters"
fi
echo ""

echo -e "${BLUE}Test 3: Checking workflow permissions${NC}"
if grep -q "permissions:" .github/workflows/floorplan-generation.yml; then
    if grep -q "pull-requests: write" .github/workflows/floorplan-generation.yml; then
        print_result 0 "Floorplan workflow has proper permissions"
    else
        print_result 1 "Floorplan workflow missing pull-requests permission"
    fi
else
    print_result 1 "Floorplan workflow missing permissions section"
fi
echo ""

echo -e "${BLUE}Test 4: Checking Verilator include paths${NC}"
if grep -q "vendor/lowrisc_ip/dv/sv/dv_utils" .github/workflows/ternary-ci.yml; then
    if grep -q "+define+SYNTHESIS" .github/workflows/ternary-ci.yml; then
        print_result 0 "Verilator commands have proper include paths and defines"
    else
        print_result 1 "Missing SYNTHESIS define in Verilator commands"
    fi
else
    print_result 1 "Missing dv_utils include path in Verilator commands"
fi
echo ""

echo -e "${BLUE}Test 5: Checking file structure${NC}"
REQUIRED_FILES=(
    "rtl/ibex_pkg.sv"
    "rtl/ibex_ternary_alu.sv"
    "rtl/ibex_ternary_regfile.sv"
    "rtl/ibex_neural_unit.sv"
    "rtl/ibex_core.sv"
    ".github/workflows/ternary-ci.yml"
    ".github/workflows/floorplan-generation.yml"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "  Missing: $file"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -eq 0 ]; then
    print_result 0 "All required files present"
else
    print_result 1 "$MISSING_FILES required files missing"
fi
echo ""

echo -e "${BLUE}Test 6: Syntax validation (basic)${NC}"
SYNTAX_ERRORS=0
for file in rtl/ibex_ternary_*.sv rtl/ibex_neural_unit.sv; do
    if [ -f "$file" ]; then
        # Check for common syntax issues
        if grep -q "endmodule" "$file"; then
            : # Good
        else
            echo "  Missing endmodule in $file"
            SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
        fi
    fi
done

if [ $SYNTAX_ERRORS -eq 0 ]; then
    print_result 0 "Basic syntax validation passed"
else
    print_result 1 "Found $SYNTAX_ERRORS potential syntax issues"
fi
echo ""

# Summary
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                         VALIDATION SUMMARY                        ║"
echo "╠═══════════════════════════════════════════════════════════════════╣"
echo -e "║  ${GREEN}Passed:${NC} $PASSED tests                                                  ║"
echo -e "║  ${RED}Failed:${NC} $FAILED tests                                                  ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All validation checks passed!${NC}"
    echo ""
    echo "The following issues have been fixed:"
    echo "  ✅ Trailing spaces removed from all RTL files"
    echo "  ✅ Line lengths comply with 100-character limit"
    echo "  ✅ GitHub workflow permissions configured"
    echo "  ✅ Verilator include paths updated"
    echo ""
    echo -e "${YELLOW}Ready to commit and push:${NC}"
    echo "  git add -A"
    echo "  git commit -m 'Fix all lint errors: trailing spaces, line lengths, workflow permissions'"
    echo "  git push"
    echo ""
    exit 0
else
    echo -e "${RED}⚠️  Some validation checks failed!${NC}"
    echo "Please review the errors above and fix them before committing."
    echo ""
    exit 1
fi
