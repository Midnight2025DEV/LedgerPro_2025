#!/bin/bash
# LedgerPro Backend API Server Startup Script
# Note: This starts the FastAPI backend only. MCP servers are managed by the LedgerPro app itself.

echo "🚀 Starting LedgerPro Backend Server..."
echo "📝 Note: MCP servers will auto-start when you launch the LedgerPro app"
echo ""

# Navigate to backend directory
cd "$(dirname "$0")/backend"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source venv/bin/activate

# Install requirements
echo "📥 Installing Python dependencies..."
pip install -r requirements.txt

# Start the server
echo "🌟 Starting FastAPI server on http://127.0.0.1:8000"
python api_server_real.py

