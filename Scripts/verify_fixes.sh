#!/bin/bash

echo "🔧 Applying fixes and verifying results..."
echo "=========================================="

# Apply fixes
echo "📝 Removing hasForex parameters..."
find /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/Tests -name "*.swift" -type f | while read file; do
    if grep -q "hasForex:" "$file"; then
        sed -i '' \
            -e 's/, hasForex: true//g' \
            -e 's/, hasForex: false//g' \
            -e 's/hasForex: true, //g' \
            -e 's/hasForex: false, //g' "$file"
    fi
done

echo "📝 Fixing API integration test assertions..."
sed -i '' 's/XCTAssertNil(domesticTransaction?.hasForex)/XCTAssertFalse(domesticTransaction?.hasForex ?? false)/g' \
    /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/Tests/LedgerProTests/API/APIIntegrationTests.swift 2>/dev/null

echo ""
echo "🧪 Running non-API tests only..."
echo "================================"

# Test each non-API test suite
for test_class in "ForexCalculationTests" "RuleTemplatesTests" "CategorizationRateTests" "CategoryRuleMatchingTests" "EndToEndCategorizationTest"; do
    echo -n "Testing $test_class... "
    if swift test --filter "$test_class" 2>&1 | grep -q "0 failures"; then
        echo "✅ PASSED"
    else
        failures=$(swift test --filter "$test_class" 2>&1 | grep -c "failed")
        echo "❌ FAILED ($failures failures)"
    fi
done

echo ""
echo "📊 Summary"
echo "========="
echo "Total test failures:"
swift test 2>&1 | grep "Test Case.*failed" | wc -l

echo ""
echo "Failed tests by category:"
swift test 2>&1 | grep "Test Case.*failed" | cut -d"'" -f2 | cut -d"." -f1 | sort | uniq -c

echo ""
echo "💡 Note: API tests will fail without backend running"
