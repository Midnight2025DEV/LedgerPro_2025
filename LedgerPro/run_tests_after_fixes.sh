#!/bin/bash

echo "🔧 Running selective tests after fixes..."

cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro

# Create test results directory with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEST_DIR="test_results_after_fixes_$TIMESTAMP"
mkdir -p "$TEST_DIR"

echo "📝 Test results will be saved to: $TEST_DIR"

# Run Python tests
echo "🐍 Running Python tests..."
cd backend
python -m pytest tests/test_api_endpoints.py -v > "../$TEST_DIR/python_tests.log" 2>&1
cd ..

# Run selective Swift tests
echo "🦉 Running Swift tests..."

# Test 1: CategoryRuleTests
echo "Testing CategoryRuleTests..."
swift test --filter CategoryRuleTests > "$TEST_DIR/swift_CategoryRuleTests.log" 2>&1

# Test 2: CategoryServiceTests  
echo "Testing CategoryServiceTests..."
swift test --filter CategoryServiceTests > "$TEST_DIR/swift_CategoryServiceTests.log" 2>&1

# Test 3: ImportCategorizationServiceTests
echo "Testing ImportCategorizationServiceTests..."
swift test --filter ImportCategorizationServiceTests > "$TEST_DIR/swift_ImportCategorizationServiceTests.log" 2>&1

# Test 4: TransactionTests
echo "Testing TransactionTests..."
swift test --filter TransactionTests > "$TEST_DIR/swift_TransactionTests.log" 2>&1

echo ""
echo "**=== TEST SUMMARY ===**"
echo "Results saved in: $TEST_DIR"
echo ""
echo "To view specific results:"
echo "  Swift tests: cat $TEST_DIR/swift_*.log"
echo "  Python tests: cat $TEST_DIR/python_tests.log"

# Quick summary
echo ""
echo "Quick Status Check:"
if grep -q "error:" "$TEST_DIR"/*.log; then
    echo "❌ Some tests have compilation errors"
    echo "Run this to see errors: grep -A2 -B2 'error:' $TEST_DIR/*.log"
else
    echo "✅ No compilation errors found"
fi

if grep -q "failed" "$TEST_DIR"/*.log; then
    echo "⚠️  Some tests failed"
else
    echo "✅ All tests that compiled passed"
fi

chmod +x run_tests_after_fixes.sh
