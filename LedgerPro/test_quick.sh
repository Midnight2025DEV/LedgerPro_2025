#!/bin/bash

# Simple test runner with file output and verification

# Create results directory
mkdir -p test_results

# Set filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="test_results/api_tests_$TIMESTAMP.txt"

# Run tests and save to file
echo "🧪 Running tests and saving to: $OUTPUT_FILE"
swift test --filter APIIntegrationTests 2>&1 | tee "$OUTPUT_FILE"

# Verify file was created and show location
echo ""
echo "✅ Test results saved!"
echo "📍 Location: $(pwd)/$OUTPUT_FILE"
echo "📏 Size: $(ls -lh "$OUTPUT_FILE" | awk '{print $5}')"
echo ""

# Quick summary
echo "📊 Quick Summary:"
echo "   Passed: $(grep -c "passed" "$OUTPUT_FILE")"
echo "   Failed: $(grep -c "failed" "$OUTPUT_FILE")"
