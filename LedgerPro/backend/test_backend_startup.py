#!/usr/bin/env python3
"""
Test script to verify backend can start in CI environment
"""
import os
import sys
import subprocess
import time

def test_backend_startup():
    """Test if the backend can start properly"""
    print("🧪 Testing backend startup...")
    
    # Change to backend directory
    backend_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(backend_dir)
    print(f"📁 Working directory: {os.getcwd()}")
    
    # Test imports
    print("\n📦 Testing imports...")
    try:
        from processors.python.camelot_processor import CamelotFinancialProcessor
        print("✅ CamelotFinancialProcessor imported")
    except ImportError as e:
        print(f"❌ Failed to import CamelotFinancialProcessor: {e}")
        return False
    
    try:
        from processors.python.csv_processor_enhanced import EnhancedCSVProcessor
        print("✅ EnhancedCSVProcessor imported")
    except ImportError as e:
        print(f"❌ Failed to import EnhancedCSVProcessor: {e}")
        return False
    
    try:
        import api_server_real
        print("✅ api_server_real imported")
    except ImportError as e:
        print(f"❌ Failed to import api_server_real: {e}")
        return False
    
    print("\n🚀 All imports successful!")
    
    # Try to start the server
    print("\n🔄 Starting server...")
    proc = subprocess.Popen(
        [sys.executable, "api_server_ci.py"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Wait a bit for server to start
    time.sleep(5)
    
    # Check if process is still running
    if proc.poll() is not None:
        stdout, stderr = proc.communicate()
        print("❌ Server exited early!")
        print(f"STDOUT:\n{stdout}")
        print(f"STDERR:\n{stderr}")
        return False
    
    # Try to hit the health endpoint
    import requests
    try:
        response = requests.get("http://127.0.0.1:8000/api/health", timeout=5)
        if response.status_code == 200:
            print("✅ Health check passed!")
            print(f"Response: {response.json()}")
            proc.terminate()
            return True
        else:
            print(f"❌ Health check failed with status: {response.status_code}")
    except Exception as e:
        print(f"❌ Failed to connect to server: {e}")
    
    # Clean up
    proc.terminate()
    return False

if __name__ == "__main__":
    success = test_backend_startup()
    sys.exit(0 if success else 1)
