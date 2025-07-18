#!/bin/bash

# Local Test Debug Script for LedgerPro
# Run this script to debug failing tests locally

echo "🧪 LedgerPro Local Test Debug"
echo "============================="
echo ""

# Change to the correct directory
cd "$(dirname "$0")"

echo "📍 Current directory: $(pwd)"
echo "📋 Swift version: $(swift --version)"
echo ""

# Check if we're in the right place
if [ ! -f "Package.swift" ]; then
    echo "❌ Error: Package.swift not found"
    echo "Please run this script from the LedgerPro directory"
    exit 1
fi

echo "✅ Package.swift found"
echo ""

# Clean build first
echo "🧹 Cleaning build..."
swift package clean
echo ""

# Try building first
echo "🔨 Building project..."
if swift build; then
    echo "✅ Build successful"
else
    echo "❌ Build failed - check compilation errors above"
    exit 1
fi
echo ""

# Run tests individually to isolate failures
echo "🧪 Running individual test suites..."
echo "===================================="

echo ""
echo "1️⃣ Testing: BasicTests"
echo "----------------------"
swift test --filter BasicTests 2>&1 | tee test_basic.log
echo ""

echo "2️⃣ Testing: CategoryRuleTests"
echo "-----------------------------"
swift test --filter CategoryRuleTests 2>&1 | tee test_category_rule.log
echo ""

echo "3️⃣ Testing: CategoryServiceTests"
echo "--------------------------------"
swift test --filter CategoryServiceTests 2>&1 | tee test_category_service.log
echo ""

echo "4️⃣ Testing: ForexCalculationTests"
echo "---------------------------------"
swift test --filter ForexCalculationTests 2>&1 | tee test_forex.log
echo ""

echo "5️⃣ Testing: RuleSuggestionEngineTests"
echo "------------------------------------"
swift test --filter RuleSuggestionEngineTests 2>&1 | tee test_rules.log
echo ""

echo "6️⃣ Testing: CriticalWorkflowTests (This might fail)"
echo "--------------------------------------------------"
swift test --filter CriticalWorkflowTests 2>&1 | tee test_critical.log
echo ""

# Summary
echo "📊 Test Results Summary"
echo "======================="

check_test_result() {
    local log_file="$1"
    local test_name="$2"
    
    if [ -f "$log_file" ]; then
        if grep -q "PASS" "$log_file" || grep -q "✅" "$log_file"; then
            echo "✅ $test_name: PASSED"
        elif grep -q "FAIL" "$log_file" || grep -q "❌" "$log_file" || grep -q "error" "$log_file"; then
            echo "❌ $test_name: FAILED"
        else
            echo "⚠️  $test_name: UNKNOWN (check log)"
        fi
    else
        echo "❓ $test_name: NO LOG FILE"
    fi
}

check_test_result "test_basic.log" "BasicTests"
check_test_result "test_category_rule.log" "CategoryRuleTests" 
check_test_result "test_category_service.log" "CategoryServiceTests"
check_test_result "test_forex.log" "ForexCalculationTests"
check_test_result "test_rules.log" "RuleSuggestionEngineTests"
check_test_result "test_critical.log" "CriticalWorkflowTests"

echo ""
echo "🔍 Detailed Error Analysis"
echo "=========================="

for log in test_*.log; do
    if [ -f "$log" ]; then
        echo ""
        echo "📝 Errors in $log:"
        echo "-------------------"
        grep -i "error\|fail\|crash\|fatal\|abort\|range.*out.*bounds" "$log" | head -5 || echo "No obvious errors found"
    fi
done

echo ""
echo "💡 Debugging Tips"
echo "================="
echo "1. Check the individual .log files for detailed output"
echo "2. Look for 'range out of bounds' or similar errors"
echo "3. Focus on CriticalWorkflowTests if it's failing"
echo "4. Run 'swift test --filter <specific_test>' to debug individual tests"
echo ""
echo "📁 Generated log files:"
ls -la test_*.log 2>/dev/null || echo "No log files found"
