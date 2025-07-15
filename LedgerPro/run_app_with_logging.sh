#!/bin/bash
echo "🚀 Starting LedgerPro with MCP logging..."
echo "📋 MCP servers will auto-start with the app"
echo "🤖 Watch for server initialization messages"
echo "🔍 All output will be saved to ledgerpro_mcp_test.log"
echo ""

# Set environment for better logging
export LEDGERPRO_DEBUG=1
export LOG_LEVEL=DEBUG

# Build and run
echo "🔨 Building app..."
swift build

if [ $? -eq 0 ]; then
    echo "✅ Build successful"
    echo ""
    echo "🏃 Running LedgerPro..."
    echo "================================"
    .build/debug/LedgerPro 2>&1 | tee ledgerpro_mcp_test.log
else
    echo "❌ Build failed"
    exit 1
fi