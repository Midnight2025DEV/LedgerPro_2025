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

for test in "${TESTS_TO_RUN[@]}"; do
    echo "  Testing $test..."
    swift test --filter "$test" > "$RESULTS_DIR/swift_$test.log" 2>&1
    
    if grep -q "error:" "$RESULTS_DIR/swift_$test.log"; then
        ERROR_COUNT=$(grep -c "error:" "$RESULTS_DIR/swift_$test.log")
        echo "  ❌ $test - $ERROR_COUNT compilation errors"
    elif grep -q "failed" "$RESULTS_DIR/swift_$test.log"; then
        FAIL_COUNT=$(grep -c "failed" "$RESULTS_DIR/swift_$test.log")
        echo "  ⚠️  $test - $FAIL_COUNT test failures"
    elif grep -q "passed" "$RESULTS_DIR/swift_$test.log"; then
        echo "  ✅ $test - passed"
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
        TOTAL_ERRORS=$((TOTAL_ERRORS + ERRORS))
    fi
done

echo "Total compilation errors: $TOTAL_ERRORS"

# Show which tests have API issues
echo ""
echo "Known API test issues (need manual fixing):"
echo "  - APIIntegrationTests: Optional unwrapping needed"
echo "  - APIServiceEnhancedTests: Try/catch handling"

echo ""
echo "To view specific results:"
echo "  Python: cat $RESULTS_DIR/python_api_tests.log"
echo "  Swift: cat $RESULTS_DIR/swift_*.log | less"

# Show any remaining errors
if [ $TOTAL_ERRORS -gt 0 ]; then
    echo ""
    echo "Remaining errors to fix:"
    grep -h "error:" "$RESULTS_DIR"/*.log | head -10
fi

chmod +x run_fixed_tests_v2.sh
