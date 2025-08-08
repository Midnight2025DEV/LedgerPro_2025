#!/bin/bash
# Run integration tests (requires backend to be running)

echo "🔗 Running Integration Tests (Backend Required)..."
echo "================================================"

# Check if backend is running
curl -s http://127.0.0.1:8000/api/health > /dev/null
if [ $? -ne 0 ]; then
    echo "❌ Backend server is not running!"
    echo "Please start the backend with: ./start_backend.sh"
    exit 1
fi

echo "✅ Backend is running"
echo ""

# Run only integration tests
swift test \
    --filter "Integration" \
    --parallel

# Check test result
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ All integration tests passed!"
else
    echo ""
    echo "❌ Some integration tests failed!"
    exit 1
fi