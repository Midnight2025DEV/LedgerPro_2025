#!/bin/bash

echo "🧪 Running LedgerPro Test Suite"
echo "==============================="

# Clean build
echo "🧹 Cleaning build..."
cd LedgerPro
swift package clean

# Build
echo "🔨 Building..."
swift build

# Run tests with coverage
echo "🧪 Running tests..."
swift test --enable-code-coverage

# Generate coverage report
echo "📊 Generating coverage report..."
xcrun llvm-cov report \
  .build/debug/LedgerProPackageTests.xctest/Contents/MacOS/LedgerProPackageTests \
  -instr-profile .build/debug/codecov/default.profdata \
  -ignore-filename-regex="Tests|.build" \
  > coverage_report.txt

echo ""
echo "📊 Coverage Summary:"
tail -n 20 coverage_report.txt

# Check for force unwraps
echo ""
echo "🔍 Checking for force unwraps in Services..."
FORCE_UNWRAPS=$(find Sources/LedgerPro/Services -name "*.swift" -exec grep -c "!\[^=]" {} \; | awk '{sum += $1} END {print sum}')
echo "Force unwraps found: $FORCE_UNWRAPS"

if [ "$FORCE_UNWRAPS" -gt "0" ]; then
  echo "⚠️  Warning: Force unwraps detected in Services!"
  find Sources/LedgerPro/Services -name "*.swift" -exec grep -n "!" {} + | head -10
fi

# Check for unsafe string operations
echo ""
echo "🔍 Checking for unsafe string operations..."
UNSAFE_OPS=$(grep -r "\.prefix(\|\.suffix(\|dropFirst\|dropLast" Sources/LedgerPro/ --include="*.swift" | wc -l)
echo "Potentially unsafe string operations: $UNSAFE_OPS"

if [ "$UNSAFE_OPS" -gt "10" ]; then
  echo "⚠️  High number of potentially unsafe string operations detected!"
fi

# Performance test
echo ""
echo "🚀 Running performance tests..."
if swift test --filter "testLargeDatasetWorkflow" > perf.txt 2>&1; then
  if grep -E "[2-9][0-9]\.[0-9]+ seconds" perf.txt; then
    echo "⚠️  Performance regression detected!"
    grep -E "seconds\)" perf.txt
  else
    echo "✅ Performance tests passed"
  fi
else
  echo "⚠️  Performance tests failed"
fi

echo ""
echo "✅ Test run complete!"
echo ""
echo "📋 Summary:"
echo "- Coverage report: coverage_report.txt"
echo "- Performance results: perf.txt"
echo "- Force unwraps in Services: $FORCE_UNWRAPS"
echo "- Unsafe string operations: $UNSAFE_OPS"