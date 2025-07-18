#!/bin/bash

echo "🔍 LedgerPro Test Diagnostic Report"
echo "==================================="

echo -e "\n📁 Project Structure:"
echo "Package.swift exists: $([ -f Package.swift ] && echo "✅" || echo "❌")"
echo "Working directory: $(pwd)"

echo -e "\n🧪 Test Files Found:"
find Tests -name "*.swift" | head -20

echo -e "\n📊 Test Discovery Issue Analysis:"
echo "Swift test is finding 0 tests, which suggests test discovery is failing"

echo -e "\n🔍 Checking first few test files for structure issues..."
for testfile in $(find Tests -name "*.swift" | head -3); do
    echo -e "\n--- $testfile ---"
    echo "Has import XCTest: $(grep -c 'import XCTest' "$testfile")"
    echo "Has test functions: $(grep -c 'func test' "$testfile")"
    echo "Has XCTestCase: $(grep -c 'XCTestCase' "$testfile")"
done

echo -e "\n🔧 Attempting to run specific test file..."
echo "Testing CriticalWorkflowTests specifically:"
swift test --filter CriticalWorkflowTests

echo -e "\n📦 Package.swift Test Target Configuration:"
cat Package.swift | grep -A5 -B5 "testTarget"

echo -e "\n💡 Likely Issues:"
echo "1. Test discovery failing due to missing XCTest imports"
echo "2. Test functions not properly named (must start with 'test')"
echo "3. Test classes not inheriting from XCTestCase"
echo "4. Swift Package Manager test discovery issues"