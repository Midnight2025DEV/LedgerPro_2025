#!/usr/bin/env python3
"""
CI-friendly version of the API server that runs without reload
"""
import os
import sys

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import the app from api_server_real
from api_server_real import app

if __name__ == "__main__":
    import uvicorn
    
    print("🚀 Starting API Server for CI...")
    print("📊 Backend: http://127.0.0.1:8000")
    print("🏥 Health Check: http://127.0.0.1:8000/api/health")
    
    # Run without reload for CI
    uvicorn.run(
        app,
        host="127.0.0.1",
        port=8000,
        log_level="info"
    )
