#!/bin/bash

# Run tests for LedgerPro
# This script runs all tests and provides a summary

echo "🧪 Running LedgerPro Tests..."
echo "================================"

# Create results directory
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR="test_results_$TIMESTAMP"
mkdir -p "LedgerPro/$RESULTS_DIR"

# Change to project directory
cd LedgerPro || exit 1

echo ""
echo "📁 Results will be saved to: $RESULTS_DIR"

# Function to count errors
count_errors() {
    local log_file=$1
    if [ -f "$log_file" ]; then
        grep -c "error:" "$log_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Test Python API components
echo ""
echo "🐍 Running Python API tests..."
PYTHON_ERRORS=0
if python3 tests/test_api.py > "$RESULTS_DIR/python_api_tests.log" 2>&1; then
    echo "✅ Python tests PASSED"
else
    echo "❌ Python tests FAILED"
    PYTHON_ERRORS=$(count_errors "$RESULTS_DIR/python_api_tests.log")
    echo "   Errors: $PYTHON_ERRORS"
fi

# Build and test Swift package
echo ""
echo "🦉 Building Swift package..."
BUILD_ERRORS=0
SWIFT_TEST_ERRORS=0
if swift build --configuration debug > "$RESULTS_DIR/swift_build.log" 2>&1; then
    echo "✅ Swift build PASSED"
    
    # Run Swift tests
    echo ""
    echo "🦉 Running Swift tests..."
    if swift test > "$RESULTS_DIR/swift_tests.log" 2>&1; then
        echo "✅ Swift tests PASSED"
    else
        echo "❌ Swift tests FAILED"
        SWIFT_TEST_ERRORS=$(count_errors "$RESULTS_DIR/swift_tests.log")
        echo "   Errors: $SWIFT_TEST_ERRORS"
    fi
else
    echo "❌ Swift build FAILED"
    BUILD_ERRORS=$(count_errors "$RESULTS_DIR/swift_build.log")
    echo "   Compilation errors: $BUILD_ERRORS"
    
    # Show first few errors
    echo ""
    echo "First few errors:"
    grep "error:" "$RESULTS_DIR/swift_build.log" | head -5
fi

# Summary
echo ""
echo "📊 Summary Report"
echo "================"

# Count total errors
TOTAL_ERRORS=0
TEST_ERRORS=0

if [ -f "$RESULTS_DIR/python_api_tests.log" ]; then
    # PYTHON_ERRORS already set above
    TOTAL_ERRORS=$((TOTAL_ERRORS + PYTHON_ERRORS))
    echo "Python API errors: $PYTHON_ERRORS"
fi

if [ -f "$RESULTS_DIR/swift_build.log" ]; then
    # BUILD_ERRORS already set above
    TOTAL_ERRORS=$((TOTAL_ERRORS + BUILD_ERRORS))
    echo "Swift build errors: $BUILD_ERRORS"
fi

if [ -f "$RESULTS_DIR/swift_tests.log" ]; then
    # Use SWIFT_TEST_ERRORS which was already set above
    TOTAL_ERRORS=$((TOTAL_ERRORS + SWIFT_TEST_ERRORS))
    echo "Swift test errors: $SWIFT_TEST_ERRORS"
fi

echo "Total errors: $TOTAL_ERRORS"

echo ""
echo "To view specific results:"
echo "  Python: cat LedgerPro/$RESULTS_DIR/python_api_tests.log"
echo "  Swift Build: cat LedgerPro/$RESULTS_DIR/swift_build.log"
echo "  Swift Tests: cat LedgerPro/$RESULTS_DIR/swift_tests.log"

# Return non-zero exit code if there were errors
exit $((TOTAL_ERRORS > 0 ? 1 : 0))
