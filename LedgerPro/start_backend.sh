#!/bin/bash
# LedgerPro Backend Startup Script

echo "🚀 Starting LedgerPro Backend Server..."

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

