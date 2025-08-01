#!/bin/bash

# Run Swift tests and capture full output
cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro

echo "🧪 Running Swift tests with full output..."
echo "=========================================="

# Run tests and save to file
swift test 2>&1 | tee test_output_full.txt

# Check the exit code
TEST_EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo "Exit code: $TEST_EXIT_CODE"

# Look for specific test failures
echo ""
echo "🔍 Checking for test failures..."
grep -A5 "error:" test_output_full.txt || echo "No error: patterns found"

echo ""
echo "🔍 Checking for failed tests..."
grep -i "failed" test_output_full.txt || echo "No failed patterns found"

echo ""
echo "📊 Test summary:"
tail -20 test_output_full.txt
