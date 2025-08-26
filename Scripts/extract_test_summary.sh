#!/bin/bash
# Extract test summary from the results file

FILE="/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/test_results_20250721_140445.txt"

echo "📊 Extracting Test Summary..."
echo "============================"

# Get the last 100 lines
echo "Last portion of test output:"
tail -100 "$FILE" | grep -E "(Test Suite|Executed|passed.*failed|All tests passed)" || echo "No summary found in last 100 lines"

echo ""
echo "📈 Test Statistics:"
echo "=================="

# Count occurrences
TOTAL_TESTS=$(grep -c "Test Case" "$FILE" 2>/dev/null || echo "0")
PASSED=$(grep -c "passed" "$FILE" 2>/dev/null || echo "0")
FAILED=$(grep -c "failed" "$FILE" 2>/dev/null || echo "0")

echo "Total Test Cases found: $TOTAL_TESTS"
echo "Passed mentions: $PASSED"
echo "Failed mentions: $FAILED"

echo ""
echo "Failed tests (if any):"
grep "failed" "$FILE" 2>/dev/null | head -20 || echo "No failures found"
