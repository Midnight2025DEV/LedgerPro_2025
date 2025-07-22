#!/bin/bash

# Test runner specifically for API Integration tests

echo "🚀 Running API Integration Tests..."
echo "===================================="

# First check if backend is running
echo "🔍 Checking backend health..."
if curl -s http://127.0.0.1:8000/api/health > /dev/null; then
    echo "✅ Backend is running"
else
    echo "❌ Backend is not running!"
    echo "Please start it with: cd backend && ./start_backend.sh"
    exit 1
fi

# Create test results directory
mkdir -p test_results

# Run only the API integration tests
echo ""
echo "🧪 Running APIIntegrationTests..."
echo ""

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="test_results/api_integration_tests_$TIMESTAMP.txt"

# Run the tests with color output
swift test --filter APIIntegrationTests 2>&1 | tee "$OUTPUT_FILE"

# Extract summary
echo ""
echo "📊 Test Summary:"
echo "==============="
grep -E "(passed|failed)" "$OUTPUT_FILE" | tail -5

# Show specific test results
echo ""
echo "🔍 Individual Test Results:"
echo "=========================="
grep -E "Test Case.*APIIntegrationTests" "$OUTPUT_FILE" | grep -E "(started|passed|failed)"

# Count results
PASSED=$(grep -c "passed" "$OUTPUT_FILE" || echo "0")
FAILED=$(grep -c "failed" "$OUTPUT_FILE" || echo "0")

echo ""
echo "📈 Final Score:"
echo "=============="
echo "✅ Passed: $PASSED"
echo "❌ Failed: $FAILED"

# Show file location
echo ""
echo "📁 Full results saved to: $(pwd)/$OUTPUT_FILE"
