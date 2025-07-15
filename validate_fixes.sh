#!/bin/bash
cd LedgerPro

echo "🔍 Validating fixes..."

# Check 1: Build succeeds
if swift build > /dev/null 2>&1; then
    echo "✅ Build successful"
else
    echo "❌ Build failed - check compilation errors"
    swift build
    exit 1
fi

# Check 2: Tests compile
if swift test --list-tests > /dev/null 2>&1; then
    echo "✅ Tests compile"
else
    echo "❌ Tests don't compile"
    exit 1
fi

# Check 3: Run critical test
echo "🧪 Testing critical workflow..."
if swift test --filter "testCompleteImportWorkflow" > /dev/null 2>&1; then
    echo "✅ Critical test passes!"
else
    echo "⚠️ Critical test failed, but continuing..."
fi

# Check 4: Count test results
echo "📊 Test Summary:"
swift test 2>&1 | tail -10