#!/bin/bash

# Test MCP servers after CSV processor fix

echo "🔍 Testing MCP Servers Integration"
echo "=================================="
echo ""

# Navigate to MCP servers directory
cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro/mcp-servers

# Check if virtual environments exist
echo "📦 Checking virtual environments..."
for server in openai-service pdf-processor financial-analyzer; do
    if [ -d "$server/venv" ]; then
        echo "   ✅ $server/venv exists"
    else
        echo "   ❌ $server/venv missing - needs setup"
    fi
done

echo ""
echo "🧪 Running MCP server tests..."
echo ""

# Run the test script
python test_mcp_servers.py

echo ""
echo "💡 Notes:"
echo "   - The PDF processor uses the backend's csv_processor_enhanced.py"
echo "   - Our forex fixes are automatically included"
echo "   - If servers fail to start, check virtual environments"
