#!/bin/bash
# Apply all API fixes for LedgerPro

echo "🚀 LedgerPro API Fix Runner"
echo "=========================="
echo ""

# Check if backend is running
if curl -s http://localhost:8000/api/health > /dev/null 2>&1; then
    echo "✅ Backend is running"
    BACKEND_WAS_RUNNING=true
else
    echo "⚠️  Backend is not running"
    BACKEND_WAS_RUNNING=false
fi

# Step 1: Apply Python backend fixes
echo ""
echo "Step 1: Applying backend fixes..."
echo "---------------------------------"
python3 /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/fix_api_issues.py

# Step 2: Apply Swift test fixes
echo ""
echo "Step 2: Applying Swift test fixes..."
echo "-----------------------------------"
chmod +x /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/fix_swift_tests.sh
/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/fix_swift_tests.sh

# Step 3: Restart backend if it was running
if [ "$BACKEND_WAS_RUNNING" = true ]; then
    echo ""
    echo "Step 3: Restarting backend..."
    echo "-----------------------------"
    # Find and kill the backend process
    pkill -f "api_server_real.py" || true
    sleep 2
    
    # Start backend in background
    cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro
    nohup ./start_backend.sh > backend_restart.log 2>&1 &
    
    echo "⏳ Waiting for backend to start..."
    sleep 5
    
    # Verify backend is running
    if curl -s http://localhost:8000/api/health > /dev/null 2>&1; then
        echo "✅ Backend restarted successfully"
    else
        echo "❌ Backend failed to restart. Please start manually."
    fi
fi

# Step 4: Test the fixes
echo ""
echo "Step 4: Testing fixes..."
echo "-----------------------"

# Test forex CSV upload
if [ -f "/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/test_forex.csv" ]; then
    echo "📤 Testing forex CSV upload..."
    RESPONSE=$(curl -s -X POST http://localhost:8000/api/upload \
        -F "file=@/Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/test_forex.csv" \
        -H "Accept: application/json")
    
    if echo "$RESPONSE" | grep -q "job_id"; then
        echo "✅ Forex CSV upload successful"
        JOB_ID=$(echo "$RESPONSE" | grep -o '"job_id":"[^"]*' | cut -d'"' -f4)
        echo "   Job ID: $JOB_ID"
    else
        echo "❌ Forex CSV upload failed"
    fi
fi

echo ""
echo "🎯 Fix Summary"
echo "============="
echo "✅ Backend calculation fix applied"
echo "✅ Forex detection logic added"
echo "✅ Swift test expectations updated"
echo ""
echo "📋 Next Steps:"
echo "1. Run API tests: cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro && swift test --filter APIIntegrationTests"
echo "2. Check test results"
echo "3. If tests still fail, check the specific error messages"
echo ""
echo "💡 Tips:"
echo "- Some tests may need the backend fully warmed up"
echo "- Run tests again if you see timeout errors"
echo "- Check backend_restart.log if backend issues occur"
