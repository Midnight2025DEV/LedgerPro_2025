#!/bin/bash

# Test Report Generator for LedgerPro
# Saves test results in multiple formats

echo "🧪 Running LedgerPro Tests and Generating Report..."
echo "================================================"

# Create reports directory
REPORT_DIR="test_reports/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro

# Run tests and capture output
echo "Running tests..."
swift test 2>&1 | tee "$REPORT_DIR/full_output.txt"

# Extract summary information
echo "" > "$REPORT_DIR/summary.txt"
echo "Test Summary Report" >> "$REPORT_DIR/summary.txt"
echo "==================" >> "$REPORT_DIR/summary.txt"
echo "Date: $(date)" >> "$REPORT_DIR/summary.txt"
echo "" >> "$REPORT_DIR/summary.txt"

# Count results
TOTAL_TESTS=$(grep -c "Test Case" "$REPORT_DIR/full_output.txt")
PASSED=$(grep -c "passed" "$REPORT_DIR/full_output.txt")
FAILED=$(grep -c "failed" "$REPORT_DIR/full_output.txt")

echo "Total Tests: $TOTAL_TESTS" >> "$REPORT_DIR/summary.txt"
echo "Passed: $PASSED" >> "$REPORT_DIR/summary.txt"
echo "Failed: $FAILED" >> "$REPORT_DIR/summary.txt"
echo "" >> "$REPORT_DIR/summary.txt"

# List failed tests if any
if [ $FAILED -gt 0 ]; then
    echo "Failed Tests:" >> "$REPORT_DIR/summary.txt"
    grep "failed" "$REPORT_DIR/full_output.txt" | cut -d"'" -f2 >> "$REPORT_DIR/summary.txt"
fi

# Create JSON report
echo "{" > "$REPORT_DIR/report.json"
echo "  \"date\": \"$(date)\"," >> "$REPORT_DIR/report.json"
echo "  \"total_tests\": $TOTAL_TESTS," >> "$REPORT_DIR/report.json"
echo "  \"passed\": $PASSED," >> "$REPORT_DIR/report.json"
echo "  \"failed\": $FAILED," >> "$REPORT_DIR/report.json"
echo "  \"success_rate\": $(awk "BEGIN {printf \"%.2f\", $PASSED/$TOTAL_TESTS*100}")%" >> "$REPORT_DIR/report.json"
echo "}" >> "$REPORT_DIR/report.json"

# Display summary
echo ""
echo "📊 Test Results Summary:"
echo "======================="
cat "$REPORT_DIR/summary.txt"

echo ""
echo "📁 Full report saved to: $REPORT_DIR/"
echo "   - full_output.txt: Complete test output"
echo "   - summary.txt: Test summary"
echo "   - report.json: JSON format report"
