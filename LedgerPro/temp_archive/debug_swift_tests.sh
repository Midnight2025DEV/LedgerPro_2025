#!/bin/bash

# Debug Swift Tests Script
# This script runs tests individually to identify specific failures

echo "🧪 LedgerPro Test Debug Script"
echo "=============================="

cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro

echo ""
echo "📊 Running individual test filters from CI..."

echo ""
echo "🔍 Testing: CriticalWorkflowTests"
swift test --filter CriticalWorkflowTests 2>&1 | tee test_output_critical.log

echo ""
echo "🔍 Testing: ForexCalculationTests"  
swift test --filter ForexCalculationTests 2>&1 | tee test_output_forex.log

echo ""
echo "🔍 Testing: RuleSuggestionEngineTests"
swift test --filter RuleSuggestionEngineTests 2>&1 | tee test_output_rules.log

echo ""
echo "🔍 Running all tests (for comparison)"
swift test 2>&1 | tee test_output_all.log

echo ""
echo "📋 Test Results Summary:"
echo "========================"

if grep -q "PASS" test_output_critical.log; then
    echo "✅ CriticalWorkflowTests: PASSED"
else
    echo "❌ CriticalWorkflowTests: FAILED"
fi

if grep -q "PASS" test_output_forex.log; then
    echo "✅ ForexCalculationTests: PASSED"
else
    echo "❌ ForexCalculationTests: FAILED"
fi

if grep -q "PASS" test_output_rules.log; then
    echo "✅ RuleSuggestionEngineTests: PASSED"
else
    echo "❌ RuleSuggestionEngineTests: FAILED"
fi

echo ""
echo "🔍 Checking for specific error patterns..."
echo ""

echo "📝 Errors found in Critical tests:"
grep -i "error\|fail\|crash" test_output_critical.log || echo "No obvious errors found"

echo ""
echo "📝 Errors found in Forex tests:"
grep -i "error\|fail\|crash" test_output_forex.log || echo "No obvious errors found"

echo ""
echo "📝 Errors found in Rules tests:"
grep -i "error\|fail\|crash" test_output_rules.log || echo "No obvious errors found"

echo ""
echo "🎯 Check the .log files for detailed output"
echo "==========================================="
echo "- test_output_critical.log"
echo "- test_output_forex.log" 
echo "- test_output_rules.log"
echo "- test_output_all.log"
