#!/bin/bash
# Run only unit tests (excluding integration tests that need backend)

echo "🧪 Running Unit Tests (No Backend Required)..."
echo "============================================"

# Run Swift tests excluding integration tests
swift test \
    --filter "^(?!.*Integration).*Tests$" \
    --parallel

# Check test result
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ All unit tests passed!"
else
    echo ""
    echo "❌ Some unit tests failed!"
    exit 1
fi