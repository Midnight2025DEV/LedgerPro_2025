#!/bin/bash

echo "🔧 Verifying test results..."
echo "============================"

# Run the full test suite and capture results
echo "Running all tests..."
swift test 2>&1 | tee test_output.txt | grep -E "(Test Suite|passed|failed|executed)"

echo ""
echo "📊 Test Summary"
echo "==============="

# Count failures
FAILURES=$(grep "Test Case.*failed" test_output.txt | wc -l | tr -d ' ')
PASSES=$(grep "Test Case.*passed" test_output.txt | wc -l | tr -d ' ')

echo "✅ Passed: $PASSES tests"
echo "❌ Failed: $FAILURES tests"

if [ "$FAILURES" -eq "0" ]; then
    echo ""
    echo "🎉 All tests are passing!"
else
    echo ""
    echo "Failed tests:"
    grep "Test Case.*failed" test_output.txt | cut -d"'" -f2 | cut -d"." -f2 | sort | uniq -c
fi

# Clean up
rm -f test_output.txt

echo ""
echo "💡 To run specific tests:"
echo "   swift test --filter TestClassName"
echo "   swift test --filter TestClassName.testMethodName"
