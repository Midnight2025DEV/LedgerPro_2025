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

# 1. Run Python tests first (these should all pass)
echo "🐍 Running Python API tests..."
cd backend
python -m pytest tests/test_api_endpoints.py -v --tb=short > "../$RESULTS_DIR/python_api_tests.log" 2>&1
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

# Test Transaction model changes
echo "  Testing Transaction..."
swift test --filter TransactionTests > "$RESULTS_DIR/swift_transaction.log" 2>&1
if grep -q "error:" "$RESULTS_DIR/swift_transaction.log"; then
    echo "  ❌ TransactionTests - compilation errors"
elif grep -q "failed" "$RESULTS_DIR/swift_transaction.log"; then
    echo "  ⚠️  TransactionTests - some tests failed"
else
    echo "  ✅ TransactionTests - passed"
fi

# Test CategoryRule fixes
echo "  Testing CategoryRule..."
swift test --filter CategoryRuleTests > "$RESULTS_DIR/swift_categoryrule.log" 2>&1
if grep -q "error:" "$RESULTS_DIR/swift_categoryrule.log"; then
    echo "  ❌ CategoryRuleTests - compilation errors"
elif grep -q "failed" "$RESULTS_DIR/swift_categoryrule.log"; then
    echo "  ⚠️  CategoryRuleTests - some tests failed"
else
    echo "  ✅ CategoryRuleTests - passed"
fi

# Test async/await fixes
echo "  Testing Import Categorization..."
swift test --filter ImportCategorizationServiceTests > "$RESULTS_DIR/swift_import.log" 2>&1
if grep -q "error:" "$RESULTS_DIR/swift_import.log"; then
    echo "  ❌ ImportCategorizationServiceTests - compilation errors"
elif grep -q "failed" "$RESULTS_DIR/swift_import.log"; then
    echo "  ⚠️  ImportCategorizationServiceTests - some tests failed"
else
    echo "  ✅ ImportCategorizationServiceTests - passed"
fi

echo ""
echo "📊 Summary Report"
echo "================"

# Count errors and failures
TOTAL_ERRORS=$(grep -c "error:" "$RESULTS_DIR"/*.log 2>/dev/null || echo 0)
TOTAL_FAILURES=$(grep -c "failed" "$RESULTS_DIR"/*.log 2>/dev/null || echo 0)

echo "Total compilation errors: $TOTAL_ERRORS"
echo "Total test failures: $TOTAL_FAILURES"

if [ $TOTAL_ERRORS -eq 0 ] && [ $TOTAL_FAILURES -eq 0 ]; then
    echo ""
    echo "🎉 All tests passed successfully!"
else
    echo ""
    echo "⚠️  Some issues remain. Check logs for details:"
    echo "  cat $RESULTS_DIR/*.log | grep -A2 -B2 'error:'"
fi

echo ""
echo "To view specific results:"
echo "  Python: cat $RESULTS_DIR/python_api_tests.log"
echo "  Swift: cat $RESULTS_DIR/swift_*.log"

chmod +x run_fixed_tests.sh
