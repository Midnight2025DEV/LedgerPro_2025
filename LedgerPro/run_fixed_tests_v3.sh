#!/bin/bash

echo "🧪 Running Tests After Fixes..."
echo "================================"

cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro

# Create results directory
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR="test_results_fixed_$TIMESTAMP"
mkdir -p "$RESULTS_DIR"

echo "📁 Results will be saved to: $RESULTS_DIR"
echo ""

# 1. Run Python tests first (use python3)
echo "🐍 Running Python API tests..."
cd backend
python3 -m pytest tests/test_api_endpoints.py -v --tb=short > "../$RESULTS_DIR/python_api_tests.log" 2>&1
PYTHON_EXIT=$?
cd ..

if [ $PYTHON_EXIT -eq 0 ]; then
    echo "✅ Python tests PASSED"
else
    echo "❌ Python tests FAILED (exit code: $PYTHON_EXIT)"
fi

echo ""

# 2. Run specific Swift tests that we fixed
echo "🦉 Running Swift tests..."

# Only run the tests that should now pass
TESTS_TO_RUN=(
    "TransactionTests"
    "CategoryRuleTests" 
    "CategoryServiceTests"
    "RuleStorageServiceTests"
    "CategorizationRateTests"
    "RangeErrorDebugTest"
    "RangeErrorPinpointTest"
)

TOTAL_PASSED=0
TOTAL_FAILED=0

for test in "${TESTS_TO_RUN[@]}"; do
    echo "  Testing $test..."
    swift test --filter "$test" > "$RESULTS_DIR/swift_$test.log" 2>&1
    
    if grep -q "Test Suite.*passed" "$RESULTS_DIR/swift_$test.log"; then
        echo "  ✅ $test - passed"
        TOTAL_PASSED=$((TOTAL_PASSED + 1))
    elif grep -q "error:" "$RESULTS_DIR/swift_$test.log"; then
        ERROR_COUNT=$(grep -c "error:" "$RESULTS_DIR/swift_$test.log" || echo 0)
        echo "  ❌ $test - $ERROR_COUNT compilation errors"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    elif grep -q "failed" "$RESULTS_DIR/swift_$test.log"; then
        FAIL_COUNT=$(grep -c "Test Case.*failed" "$RESULTS_DIR/swift_$test.log" || echo 0)
        echo "  ⚠️  $test - $FAIL_COUNT test failures"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    else
        echo "  ❓ $test - unknown result"
    fi
done

echo ""
echo "📊 Summary Report"
echo "================"

# Count compilation errors
TOTAL_ERRORS=0
for log in "$RESULTS_DIR"/*.log; do
    if [ -f "$log" ]; then
        ERRORS=$(grep -c "error:" "$log" 2>/dev/null || echo 0)
        if [ "$ERRORS" -gt 0 ]; then
            TOTAL_ERRORS=$((TOTAL_ERRORS + ERRORS))
        fi
    fi
done

echo "Total test suites: ${#TESTS_TO_RUN[@]}"
echo "Passed: $TOTAL_PASSED"
echo "Failed: $TOTAL_FAILED"
echo "Total compilation errors: $TOTAL_ERRORS"

# Show specific failing tests
if [ $TOTAL_FAILED -gt 0 ]; then
    echo ""
    echo "❌ Failed tests:"
    for test in "${TESTS_TO_RUN[@]}"; do
        if grep -q "error:" "$RESULTS_DIR/swift_$test.log" 2>/dev/null || grep -q "failed" "$RESULTS_DIR/swift_$test.log" 2>/dev/null; then
            echo "  - $test"
            # Show first error
            grep -m 1 "error:" "$RESULTS_DIR/swift_$test.log" 2>/dev/null | sed 's/^/    /'
        fi
    done
fi

echo ""
echo "To view specific results:"
echo "  Python: cat $RESULTS_DIR/python_api_tests.log"
echo "  Swift: cat $RESULTS_DIR/swift_*.log | less"
echo ""
echo "For detailed failure analysis:"
echo "  grep -A5 -B5 'error:' $RESULTS_DIR/*.log"
