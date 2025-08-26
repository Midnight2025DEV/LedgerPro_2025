#!/bin/bash
# Quick fix for APIServiceEnhancedTests.swift syntax error

echo "🔧 Fixing APIServiceEnhancedTests.swift syntax error..."

cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro

# The sed command that was run added a comment but didn't handle the line break properly
# Let's fix line 164 which has two statements on one line

# First, let's check if the file has the error
if grep -q "XCTAssertFalse(uploadResponse.jobId.isEmpty).*XCTAssertEqual" Tests/LedgerProTests/API/APIServiceEnhancedTests.swift 2>/dev/null; then
    echo "❌ Found syntax error - fixing..."
    # Fix by adding a newline between the two assertions
    sed -i '' 's/XCTAssertFalse(uploadResponse\.jobId\.isEmpty)[[:space:]]*XCTAssertEqual/XCTAssertFalse(result?.jobId.isEmpty ?? true)\
        XCTAssertEqual/g' Tests/LedgerProTests/API/APIServiceEnhancedTests.swift
    echo "✅ Fixed syntax error"
else
    echo "ℹ️  No syntax error found - file might already be fixed"
fi

echo ""
echo "Now you can run the tests:"
echo "cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro"
echo "swift test --filter APIIntegrationTests"
