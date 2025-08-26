#!/bin/bash

echo "🔍 Checking test status from correct directory..."
echo "================================================"

# Navigate to the package directory
cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro

echo "📁 Current directory: $(pwd)"
echo ""

echo "📊 Running swift test to get summary..."
echo "======================================"

# Run tests and capture just the summary
swift test 2>&1 | grep -E "(Test Suite.*executed|passed.*failed|All tests passed)" | tail -10

echo ""
echo "💡 To see full test output, run:"
echo "   cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro"
echo "   swift test"
