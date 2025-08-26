#!/bin/bash

echo "🔍 Investigating API Test Failures"
echo "=================================="

# First, let's check if there's a test configuration
echo "📁 Checking for test configuration files..."
find /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main -name "*test*config*" -o -name "*mock*" -o -name ".env.test" | head -10

echo ""
echo "🧪 Running a single API test with verbose output..."
echo "================================================="

# Run one API test to see detailed failure
swift test --filter "APIServiceTests.testHealthCheck_failure_updatesState" 2>&1 | tee single_test.txt

echo ""
echo "📋 Analyzing failure reason..."
echo "============================"

# Look for specific error patterns
if grep -q "backend not running" single_test.txt; then
    echo "❌ Backend not detected - tests are being skipped"
    echo "   Fix: Start backend with 'cd backend && ./start_backend.sh'"
elif grep -q "connection refused" single_test.txt; then
    echo "❌ Connection refused - backend not accessible"
    echo "   Fix: Check if backend is running on correct port"
elif grep -q "timeout" single_test.txt; then
    echo "❌ Request timeout - backend responding slowly"
    echo "   Fix: Increase timeout in test configuration"
elif grep -q "XCTSkip" single_test.txt; then
    echo "⚠️  Test was skipped - likely due to missing backend"
    echo "   This is expected behavior when backend isn't running"
else
    echo "🤔 Unknown failure - check output above for details"
fi

echo ""
echo "🔧 Checking API Service configuration..."
echo "======================================"

# Look for API configuration
grep -r "baseURL\|endpoint\|localhost" /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/Sources/LedgerPro/Services/APIService.swift 2>/dev/null | head -5

echo ""
echo "💡 Quick fixes to try:"
echo "===================="
echo "1. Start the backend: cd backend && ./start_backend.sh"
echo "2. Check backend is running: curl http://localhost:8000/health"
echo "3. Run API tests only: swift test --filter APIServiceTests"
echo "4. Check for test timeouts: grep -r 'timeout\|TimeInterval' Tests/"

# Clean up
rm -f single_test.txt
