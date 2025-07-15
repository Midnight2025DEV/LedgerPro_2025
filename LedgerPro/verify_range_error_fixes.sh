#!/bin/bash

echo "🔧 Range Error Fix Verification"
echo "=============================="
echo ""

cd "$(dirname "$0")"

# Verify we're in the right directory
if [ ! -f "Package.swift" ]; then
    echo "❌ Error: Not in LedgerPro directory"
    exit 1
fi

echo "📍 Directory: $(pwd)"
echo "🔨 Building project with range error fixes..."

# Clean build first
swift package clean

# Build the project
if swift build; then
    echo "✅ Build successful - range error fixes compiled correctly"
else
    echo "❌ Build failed - check compilation errors"
    exit 1
fi

echo ""
echo "🧪 Testing Range Error Fixes"
echo "============================="

# Test 1: Critical Workflow Tests (should now pass)
echo ""
echo "1️⃣ Testing CriticalWorkflowTests (previously failing due to range errors)"
echo "------------------------------------------------------------------------"

if swift test --filter CriticalWorkflowTests 2>&1 | tee test_critical_fixed.log; then
    echo "✅ CriticalWorkflowTests: PASSED"
    CRITICAL_RESULT="PASSED"
else
    echo "❌ CriticalWorkflowTests: Still failing"
    CRITICAL_RESULT="FAILED"
fi

# Test 2: Range Error Debug Tests (should definitely pass now)
echo ""
echo "2️⃣ Testing RangeErrorDebugTest (should pass with fixes)"
echo "------------------------------------------------------"

if swift test --filter RangeErrorDebugTest 2>&1 | tee test_range_debug.log; then
    echo "✅ RangeErrorDebugTest: PASSED"
    RANGE_DEBUG_RESULT="PASSED"
else
    echo "❌ RangeErrorDebugTest: Still failing"
    RANGE_DEBUG_RESULT="FAILED"
fi

# Test 3: Range Error Pinpoint Tests
echo ""
echo "3️⃣ Testing RangeErrorPinpointTest (should pass with fixes)"
echo "--------------------------------------------------------"

if swift test --filter RangeErrorPinpointTest 2>&1 | tee test_range_pinpoint.log; then
    echo "✅ RangeErrorPinpointTest: PASSED"
    RANGE_PINPOINT_RESULT="PASSED"
else
    echo "❌ RangeErrorPinpointTest: Still failing"
    RANGE_PINPOINT_RESULT="FAILED"
fi

# Test 4: Run the CI test filters that were failing
echo ""
echo "4️⃣ Testing CI Filters (ForexCalculationTests, RuleSuggestionEngineTests)"
echo "----------------------------------------------------------------------"

echo "🔍 ForexCalculationTests:"
if swift test --filter ForexCalculationTests 2>&1 | tee test_forex_fixed.log; then
    echo "✅ ForexCalculationTests: PASSED"
    FOREX_RESULT="PASSED"
else
    echo "❌ ForexCalculationTests: Still failing"
    FOREX_RESULT="FAILED"
fi

echo ""
echo "🔍 RuleSuggestionEngineTests:"
if swift test --filter RuleSuggestionEngineTests 2>&1 | tee test_rules_fixed.log; then
    echo "✅ RuleSuggestionEngineTests: PASSED"
    RULES_RESULT="PASSED"
else
    echo "❌ RuleSuggestionEngineTests: Still failing"
    RULES_RESULT="FAILED"
fi

# Summary
echo ""
echo "📊 Range Error Fix Results Summary"
echo "=================================="
echo "CriticalWorkflowTests:     $CRITICAL_RESULT"
echo "RangeErrorDebugTest:       $RANGE_DEBUG_RESULT"  
echo "RangeErrorPinpointTest:    $RANGE_PINPOINT_RESULT"
echo "ForexCalculationTests:     $FOREX_RESULT"
echo "RuleSuggestionEngineTests: $RULES_RESULT"

echo ""
echo "📋 Specific Fixes Applied:"
echo "========================="
echo "✅ Transaction.safeTruncateDescription() - prevents string range errors"
echo "✅ Transaction.safePrefix() - prevents array range errors"
echo "✅ Safe String.Index usage with limitedBy parameter"
echo "✅ Proper empty string handling in ID generation"
echo "✅ Safe component extraction in displayMerchantName"

# Check for remaining errors
echo ""
echo "🔍 Checking for Range Error Patterns in Logs"
echo "============================================="

for log in test_*_fixed.log test_range_*.log; do
    if [ -f "$log" ]; then
        echo ""
        echo "📝 Checking $log for range errors:"
        if grep -i "range.*out.*of.*bounds\|index.*out.*of.*range\|string.*index.*out.*of.*bounds" "$log"; then
            echo "⚠️  Range errors still found in $log"
        else
            echo "✅ No range errors found in $log"
        fi
    fi
done

echo ""
echo "💡 Next Steps"
echo "============"
if [ "$CRITICAL_RESULT" = "PASSED" ] && [ "$RANGE_DEBUG_RESULT" = "PASSED" ] && [ "$RANGE_PINPOINT_RESULT" = "PASSED" ]; then
    echo "🎉 SUCCESS: Range error fixes are working!"
    echo "✅ All range error tests are now passing"
    echo "✅ Can commit these changes and update CI"
    echo ""
    echo "🚀 Ready to push to fix GitHub Actions:"
    echo "   git add ."
    echo "   git commit -m 'fix: Resolve range errors in Transaction model'"
    echo "   git push"
else
    echo "⚠️  Some tests are still failing"
    echo "📋 Check the individual log files for details:"
    ls -la test_*_fixed.log test_range_*.log 2>/dev/null || echo "No log files generated"
    echo ""
    echo "🔍 Look for other potential range error sources in:"
    echo "   - String manipulation functions"
    echo "   - Array/Collection subscripting"
    echo "   - Prefix/suffix operations"
fi
